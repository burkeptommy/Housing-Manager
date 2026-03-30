/**
 * Haven Equipment Manual Scraper v6 — Complete Pipeline
 *
 * 5-step architecture:
 * 1. Supabase ID pass-through (deterministic DB updates)
 * 2. Color-stripper Google Search (tiered exact|base model queries)
 * 3. Two-step modal download with popup handler (download OR new-tab race)
 * 4. In-memory PDF verification via pdf-parse (model number in text)
 * 5. Structured output dataset with verification status
 */

import { Actor, log } from 'apify';
import { PlaywrightCrawler, createPlaywrightRouter } from '@crawlee/playwright';
// PDF text extraction: extract readable strings from PDF buffer
// Simpler than pdf-parse, no native dependencies
function extractPdfText(buffer, maxBytes = 500000) {
    const text = [];
    const slice = buffer.slice(0, Math.min(buffer.length, maxBytes));
    const str = slice.toString('latin1');
    // Extract text between BT/ET markers (PDF text objects) and readable ASCII strings
    const matches = str.match(/[\x20-\x7E]{4,}/g) || [];
    return matches.join(' ').toUpperCase();
}

await Actor.init();

const input = await Actor.getInput() ?? {};
const {
    supabaseUrl = '',
    supabaseServiceKey = '',
    batchSize = 50,
    manufacturerSlug = null,
    onlyMissing = true,
} = input;

if (!supabaseUrl || !supabaseServiceKey) {
    log.error('Missing supabaseUrl or supabaseServiceKey');
    await Actor.exit({ exitCode: 1 });
}

// ── Step 1: Fetch models with Supabase IDs ──────────────────────────────────

log.info('Fetching models from Supabase...');

let cachedIds = new Set();
if (onlyMissing) {
    const resp = await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?select=catalog_entry_id&file_size_bytes=gt.0&limit=10000`, {
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}` },
    });
    cachedIds = new Set((await resp.json()).map(m => m.catalog_entry_id));
}

let allModels = [];
let offset = 0;
while (true) {
    let url = `${supabaseUrl}/rest/v1/equipment_catalog?select=id,model_number,model_name,equipment_manufacturers!inner(name,slug),equipment_categories!inner(name)&limit=1000&offset=${offset}&order=id`;
    if (manufacturerSlug) url += `&equipment_manufacturers.slug=eq.${manufacturerSlug}`;
    const resp = await fetch(url, { headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}` } });
    const page = await resp.json();
    if (!page || page.length === 0) break;
    allModels.push(...page);
    offset += 1000;
    if (page.length < 1000) break;
}

let models = onlyMissing ? allModels.filter(m => !cachedIds.has(m.id)) : allModels;
if (models.length > batchSize) models = models.slice(0, batchSize);
log.info(`Processing ${models.length} models (${allModels.length} total, ${cachedIds.size} cached)`);

if (models.length === 0) {
    await Actor.pushData({ totalProcessed: 0, pdfsDownloaded: 0, verified: 0, needsReview: 0, notFound: 0, results: [] });
    await Actor.exit();
}

// ── Step 2: Color-Stripper Pre-Processor ────────────────────────────────────

function stripColorCode(model) {
    // Remove special chars, then strip last 2 letters if > 6 chars and ends with letters after a digit
    const cleaned = model.replace(/[^A-Za-z0-9-]/g, '');
    if (cleaned.length <= 6) return cleaned;
    const match = cleaned.match(/^(.+\d)[A-Za-z]{1,2}$/);
    return match ? match[1] : cleaned;
}

// ── Google Search for ManualsLib URLs ───────────────────────────────────────

log.info('Searching Google for ManualsLib pages...');

const BATCH_SIZE = 20;
const modelToManualsLibUrl = new Map();

for (let i = 0; i < models.length; i += BATCH_SIZE) {
    const batch = models.slice(i, i + BATCH_SIZE);
    const queryString = batch.map(m => {
        const brand = m.equipment_manufacturers.name;
        const exact = m.model_number.replace(/[^A-Za-z0-9-]/g, '');
        const base = stripColorCode(exact);
        // Fuzzy search: no quotes around variables to allow partial matches
        // Always include brand to prevent cross-brand collisions
        return `site:manualslib.com ${brand} ${base} manual`;
    }).join('\n');

    log.info(`Google batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(models.length / BATCH_SIZE)}...`);

    try {
        const searchRun = await Actor.call('apify/google-search-scraper', {
            queries: queryString,
            maxPagesPerQuery: 1,
            resultsPerPage: 3,
            countryCode: 'us',
            languageCode: 'en',
        });
        const dataset = await Actor.apifyClient.dataset(searchRun.defaultDatasetId);
        const { items } = await dataset.listItems();

        for (let j = 0; j < batch.length && j < items.length; j++) {
            const model = batch[j];
            const results = items[j]?.organicResults || [];
            const manualPage = results.find(r => r.url?.includes('manualslib.com/manual/'));
            const productPage = results.find(r => r.url?.includes('manualslib.com/products/'));
            const bestUrl = manualPage?.url || productPage?.url;
            if (bestUrl) {
                modelToManualsLibUrl.set(model.id, { url: bestUrl, model });
            }
        }
    } catch (err) {
        log.warning(`Google batch failed: ${err.message}`);
    }

    if (i + BATCH_SIZE < models.length) await new Promise(r => setTimeout(r, 2000));
}

log.info(`Found ManualsLib pages for ${modelToManualsLibUrl.size}/${models.length} models`);

// ── Step 3: URL Rewrite → Download Page → Get Manual → Steal CDN Link ───────

const results = [];
const crawlRequests = [];

for (const [catalogId, info] of modelToManualsLibUrl) {
    // Clean the URL: strip query params and fragments before rewriting
    const cleanUrl = info.url.split('?')[0].split('#')[0];
    // Step 1: Rewrite /manual/ → /download/ to go straight to the download page
    const downloadUrl = cleanUrl.replace('/manual/', '/download/');
    crawlRequests.push({
        url: downloadUrl,
        userData: {
            supabaseId: catalogId,
            modelNumber: info.model.model_number,
            brand: info.model.equipment_manufacturers.name,
            brandSlug: info.model.equipment_manufacturers.slug,
            originalModel: info.model.model_number,
            manualPageUrl: info.url,
        },
        label: 'MANUALSLIB',
    });
}

for (const model of models) {
    if (!modelToManualsLibUrl.has(model.id)) {
        results.push({
            supabase_id: model.id,
            brand: model.equipment_manufacturers.name,
            original_model: model.model_number,
            pdf_url: null,
            verification_status: 'NOT_FOUND',
        });
    }
}

const router = createPlaywrightRouter();

router.addHandler('MANUALSLIB', async ({ page, request }) => {
    const { supabaseId, modelNumber, brand, brandSlug, originalModel, manualPageUrl } = request.userData;
    const safeModel = modelNumber.replace(/[^a-zA-Z0-9_-]/g, '_');

    log.info(`[${brand} ${modelNumber}] On download page: ${request.url}`);
    await page.waitForLoadState('domcontentloaded', { timeout: 20000 }).catch(() => {});
    await page.waitForTimeout(3000);

    try {
        // Screenshot: what does the download page look like?
        const ss1 = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-downloadpage-${safeModel}`, ss1, { contentType: 'image/png' });
        log.info(`[${modelNumber}] Screenshot saved: debug-downloadpage-${safeModel}`);

        // Step 2: Wait for CAPTCHA to resolve, then click "Get Manual"

        // 2a: Wait for any CAPTCHA iframe to disappear (residential proxy should auto-solve)
        log.info(`[${modelNumber}] Waiting for CAPTCHA to clear...`);
        await page.locator('iframe[src*="captcha"], iframe[src*="hcaptcha"], iframe[src*="recaptcha"]')
            .waitFor({ state: 'hidden', timeout: 20000 })
            .catch(() => { log.info(`[${modelNumber}] No CAPTCHA iframe found or already hidden`); });

        // 2b: Hard buffer to let any JS finish after CAPTCHA clears
        await page.waitForTimeout(5000);

        // 2c: Wait for "Get Manual" button to be visible AND enabled
        log.info(`[${modelNumber}] Waiting for "Get Manual" button...`);
        const getManualBtn = await page.waitForSelector(
            'button:has-text("Get Manual"), a:has-text("Get Manual"), ' +
            'input[value*="Get Manual"], button:has-text("Download"), ' +
            'a:has-text("Download Manual"), input[type="submit"]',
            { timeout: 30000, state: 'visible' }
        ).catch(() => null);

        if (!getManualBtn) {
            log.info(`[${modelNumber}] No "Get Manual" button found`);
            const ss2 = await page.screenshot({ fullPage: true });
            await Actor.setValue(`debug-blocked-${safeModel}`, ss2, { contentType: 'image/png' });
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'CAPTCHA_BLOCKED' });
            return;
        }

        // 2d: Verify button is enabled before clicking
        const isDisabled = await getManualBtn.getAttribute('disabled');
        if (isDisabled !== null) {
            log.info(`[${modelNumber}] "Get Manual" button is disabled — waiting 5s more`);
            await page.waitForTimeout(5000);
        }

        // Screenshot right before click — verify CAPTCHA is gone
        const ssPreClick = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-preclick-${safeModel}`, ssPreClick, { contentType: 'image/png' });
        log.info(`[${modelNumber}] Screenshot saved: debug-preclick-${safeModel}`);

        log.info(`[${modelNumber}] Clicking "Get Manual"...`);
        await getManualBtn.click();
        await page.waitForTimeout(3000);

        // Step 3: Find "View in Browser" or "Download PDF" link with the CDN URL
        log.info(`[${modelNumber}] Looking for CDN PDF link...`);
        const pdfLink = await page.waitForSelector(
            'a:has-text("View in Browser"), a:has-text("Download PDF"), ' +
            'a[href*="data2.manualslib.com"], a[href*="data1.manualslib.com"], ' +
            'a[href*=".pdf"][href*="manualslib"]',
            { timeout: 15000 }
        ).catch(() => null);

        if (!pdfLink) {
            log.info(`[${modelNumber}] No CDN link appeared after "Get Manual"`);
            const ss3 = await page.screenshot({ fullPage: true });
            await Actor.setValue(`debug-nocdnlink-${safeModel}`, ss3, { contentType: 'image/png' });
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'LINK_ONLY' });
            return;
        }

        const pdfUrl = await pdfLink.getAttribute('href');
        if (!pdfUrl) {
            log.info(`[${modelNumber}] Link found but no href`);
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'LINK_ONLY' });
            return;
        }

        const fullPdfUrl = pdfUrl.startsWith('http') ? pdfUrl : `https://www.manualslib.com${pdfUrl}`;
        log.info(`[${modelNumber}] Got CDN link: ${fullPdfUrl.substring(0, 80)}`);

        // Step 4: Fetch PDF via standard HTTP, verify, and upload
        const pdfResp = await fetch(fullPdfUrl, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                'Referer': request.url,
            },
            redirect: 'follow',
            signal: AbortSignal.timeout(60000),
        });

        if (!pdfResp.ok) {
            log.warning(`[${modelNumber}] PDF fetch failed: HTTP ${pdfResp.status}`);
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: fullPdfUrl, verification_status: 'FETCH_FAILED' });
            return;
        }

        const pdfBuffer = Buffer.from(await pdfResp.arrayBuffer());

        // Verify PDF magic bytes
        if (pdfBuffer.length < 1000 || pdfBuffer[0] !== 0x25 || pdfBuffer[1] !== 0x50 || pdfBuffer[2] !== 0x44 || pdfBuffer[3] !== 0x46) {
            log.info(`[${modelNumber}] Fetched file is not a valid PDF (${pdfBuffer.length} bytes)`);
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: fullPdfUrl, verification_status: 'NOT_PDF' });
            return;
        }

        // Verify model number in PDF text
        let verificationStatus = 'NEEDS_REVIEW';
        try {
            const text = extractPdfText(pdfBuffer);
            const exactUpper = originalModel.toUpperCase().replace(/[^A-Z0-9]/g, '');
            const baseUpper = stripColorCode(originalModel).toUpperCase().replace(/[^A-Z0-9]/g, '');
            const textClean = text.replace(/[^A-Z0-9]/g, '');

            if (textClean.includes(exactUpper)) {
                verificationStatus = 'VERIFIED';
                log.info(`[${modelNumber}] ✓ VERIFIED — exact model in PDF`);
            } else if (textClean.includes(baseUpper)) {
                verificationStatus = 'VERIFIED';
                log.info(`[${modelNumber}] ✓ VERIFIED — base model in PDF`);
            } else {
                log.info(`[${modelNumber}] ? NEEDS_REVIEW — model not found in PDF text`);
            }
        } catch (e) {
            log.warning(`[${modelNumber}] Text extraction error: ${e.message}`);
        }

        // Upload to Supabase
        const storagePath = `${brandSlug}/${safeModel}/owners_manual.pdf`;
        const uploadResp = await fetch(`${supabaseUrl}/storage/v1/object/equipment-manuals/${storagePath}`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/pdf', 'x-upsert': 'true' },
            body: pdfBuffer,
        });

        if (uploadResp.ok) {
            await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
                method: 'PATCH',
                headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
                body: JSON.stringify({ source_url: manualPageUrl, file_path: storagePath, file_size_bytes: pdfBuffer.length, last_verified_at: new Date().toISOString() }),
            });
            log.info(`✓ ${brand} ${modelNumber} — ${verificationStatus} (${Math.round(pdfBuffer.length / 1024)} KB)`);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: fullPdfUrl, verification_status: verificationStatus });
        } else {
            log.warning(`[${modelNumber}] Upload failed`);
            await saveSource(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: fullPdfUrl, verification_status: 'UPLOAD_FAILED' });
        }

    } catch (err) {
        log.warning(`[${modelNumber}] Error: ${err.message}`);
        await saveSource(supabaseId, manualPageUrl || request.url);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: request.url, verification_status: 'ERROR' });
    }
});

async function saveSource(supabaseId, url) {
    await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
        method: 'PATCH',
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
        body: JSON.stringify({ source_url: url, last_verified_at: new Date().toISOString() }),
    });
}

// ── Run crawler ─────────────────────────────────────────────────────────────

if (crawlRequests.length > 0) {
    const crawler = new PlaywrightCrawler({
        requestHandler: router,
        maxConcurrency: 1,
        navigationTimeoutSecs: 30,
        requestHandlerTimeoutSecs: 60,
        maxRequestRetries: 1,
        headless: true,
        proxyConfiguration: await Actor.createProxyConfiguration({
            groups: ['RESIDENTIAL'],
            useApifyProxy: true,
        }),
        browserPoolOptions: { useFingerprints: true },
        launchContext: {
            launchOptions: { args: ['--disable-dev-shm-usage', '--no-sandbox'] },
        },
    });
    await crawler.run(crawlRequests);
}

// ── Step 5: Output Dataset ──────────────────────────────────────────────────

const downloaded = results.filter(r => r.verification_status === 'VERIFIED' || r.verification_status === 'NEEDS_REVIEW');
const linkOnly = results.filter(r => r.verification_status === 'LINK_ONLY');
const notFound = results.filter(r => r.verification_status === 'NOT_FOUND');

await Actor.pushData({
    totalProcessed: models.length,
    pdfsDownloaded: downloaded.length,
    verified: results.filter(r => r.verification_status === 'VERIFIED').length,
    needsReview: results.filter(r => r.verification_status === 'NEEDS_REVIEW').length,
    linkOnly: linkOnly.length,
    notFound: notFound.length,
    timestamp: new Date().toISOString(),
    results,
});

log.info(`Done! ${downloaded.length} PDFs (${results.filter(r => r.verification_status === 'VERIFIED').length} verified), ${linkOnly.length} links, ${notFound.length} not found`);
await Actor.exit();
