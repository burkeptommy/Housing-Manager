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
import pdf from 'pdf-parse';

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
        if (base !== exact) {
            return `site:manualslib.com "${exact}" | "${base}" manual`;
        }
        return `site:manualslib.com "${exact}" manual`;
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

// ── Step 3: Two-Step Modal Download with Popup Handler ──────────────────────

const results = [];
const crawlRequests = [];

for (const [catalogId, info] of modelToManualsLibUrl) {
    crawlRequests.push({
        url: info.url,
        userData: {
            supabaseId: catalogId,
            modelNumber: info.model.model_number,
            brand: info.model.equipment_manufacturers.name,
            brandSlug: info.model.equipment_manufacturers.slug,
            originalModel: info.model.model_number,
        },
        label: 'MANUALSLIB',
    });
}

// Track not-found models
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
    const { supabaseId, modelNumber, brand, brandSlug, originalModel } = request.userData;
    const manualsLibUrl = request.url;

    log.info(`[${brand} ${modelNumber}] Visiting ManualsLib page...`);
    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});

    try {
        // Step 3a: Find and click the initial Download button
        const downloadBtn = await page.$(
            'a.btn-download, a[href*="/download/"], a:has-text("Download Manual"), a:has-text("Download PDF"), .download-manual'
        );

        if (!downloadBtn) {
            log.info(`[${modelNumber}] No download button — saving ManualsLib link`);
            await saveSource(supabaseId, manualsLibUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualsLibUrl, verification_status: 'LINK_ONLY' });
            return;
        }

        log.info(`[${modelNumber}] Clicking download button...`);
        await downloadBtn.click();

        // Step 3b: Wait for modal
        await page.waitForTimeout(3000);
        await page.waitForSelector('.modal, .popup, [role="dialog"], [class*="modal"]', { timeout: 5000 }).catch(() => {});

        // Step 3c: Find the secondary button inside the modal
        const modalBtn = await page.$(
            '.modal a:has-text("Download"), [role="dialog"] a:has-text("Download"), ' +
            '.modal button:has-text("Download"), a:has-text("Get Manual"), ' +
            'a:has-text("Download PDF"), a.download-link, #download-pdf, ' +
            '.popup a:has-text("Download"), .popup button:has-text("Download")'
        );

        if (!modalBtn) {
            log.info(`[${modelNumber}] No modal button found — saving link`);
            await saveSource(supabaseId, manualsLibUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualsLibUrl, verification_status: 'LINK_ONLY' });
            return;
        }

        // Step 3d: Race for download OR popup (new tab)
        log.info(`[${modelNumber}] Clicking modal button — racing download vs popup...`);

        const [raceResult] = await Promise.all([
            Promise.race([
                page.waitForEvent('download', { timeout: 20000 }).catch(() => null),
                page.waitForEvent('popup', { timeout: 20000 }).catch(() => null),
            ]),
            modalBtn.click({ timeout: 10000 }).catch(() => null),
        ]);

        let pdfBuffer = null;
        let pdfUrl = null;

        if (raceResult && typeof raceResult.url === 'function') {
            // It opened a new tab (popup) — the URL is the direct PDF link
            pdfUrl = raceResult.url();
            log.info(`[${modelNumber}] Popup detected — PDF URL: ${pdfUrl.substring(0, 80)}...`);

            try {
                // Close the popup tab to free resources
                await raceResult.close().catch(() => {});
            } catch { /* */ }

            // Fetch the PDF directly
            const cookies = await page.context().cookies();
            const cookieStr = cookies.map(c => `${c.name}=${c.value}`).join('; ');

            const pdfResp = await fetch(pdfUrl, {
                headers: {
                    'User-Agent': await page.evaluate(() => navigator.userAgent),
                    'Referer': manualsLibUrl,
                    'Cookie': cookieStr,
                },
                redirect: 'follow',
                signal: AbortSignal.timeout(30000),
            });

            if (pdfResp.ok) {
                pdfBuffer = Buffer.from(await pdfResp.arrayBuffer());
            }
        } else if (raceResult && typeof raceResult.path === 'function') {
            // Standard Playwright download
            log.info(`[${modelNumber}] Download event intercepted`);
            const filePath = await raceResult.path();
            if (filePath) {
                const { readFileSync } = await import('fs');
                pdfBuffer = readFileSync(filePath);
            }
        } else {
            log.info(`[${modelNumber}] Neither download nor popup fired`);

            // Last resort: check if modalBtn has an href we can fetch
            const href = await modalBtn.getAttribute('href').catch(() => null);
            if (href && (href.includes('.pdf') || href.includes('/download/'))) {
                const fullUrl = href.startsWith('http') ? href : `https://www.manualslib.com${href}`;
                log.info(`[${modelNumber}] Trying direct href: ${fullUrl.substring(0, 60)}`);
                const cookies = await page.context().cookies();
                const cookieStr = cookies.map(c => `${c.name}=${c.value}`).join('; ');
                const resp = await fetch(fullUrl, {
                    headers: { 'User-Agent': await page.evaluate(() => navigator.userAgent), 'Referer': manualsLibUrl, 'Cookie': cookieStr },
                    redirect: 'follow', signal: AbortSignal.timeout(30000),
                }).catch(() => null);
                if (resp?.ok) pdfBuffer = Buffer.from(await resp.arrayBuffer());
            }
        }

        // ── Step 4: PDF Verification ────────────────────────────────────
        if (pdfBuffer && pdfBuffer.length > 1000) {
            // Check magic bytes
            if (pdfBuffer[0] !== 0x25 || pdfBuffer[1] !== 0x50 || pdfBuffer[2] !== 0x44 || pdfBuffer[3] !== 0x46) {
                log.info(`[${modelNumber}] Downloaded file is not a PDF`);
                await saveSource(supabaseId, manualsLibUrl);
                results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualsLibUrl, verification_status: 'LINK_ONLY' });
                return;
            }

            // Parse PDF text (first 15 pages) and verify model number
            let verificationStatus = 'NEEDS_REVIEW';
            try {
                const parsed = await pdf(pdfBuffer, { max: 15 });
                const text = parsed.text.toUpperCase();
                const exactUpper = originalModel.toUpperCase().replace(/[^A-Z0-9]/g, '');
                const baseUpper = stripColorCode(originalModel).toUpperCase().replace(/[^A-Z0-9]/g, '');

                // Check for exact model, base model, or wildcard variants
                const exactFound = text.replace(/[^A-Z0-9]/g, '').includes(exactUpper);
                const baseFound = text.replace(/[^A-Z0-9]/g, '').includes(baseUpper);
                const wildcardRegex = new RegExp(baseUpper + '(\\*\\*|XX|SERIES|[A-Z]{0,3})', 'i');
                const wildcardFound = wildcardRegex.test(text.replace(/[^A-Z0-9*]/g, ''));

                if (exactFound) {
                    verificationStatus = 'VERIFIED';
                    log.info(`[${modelNumber}] ✓ VERIFIED — exact model found in PDF`);
                } else if (baseFound || wildcardFound) {
                    verificationStatus = 'VERIFIED';
                    log.info(`[${modelNumber}] ✓ VERIFIED — base/wildcard model found in PDF`);
                } else {
                    log.info(`[${modelNumber}] ? NEEDS_REVIEW — model not found in first 15 pages`);
                }
            } catch (parseErr) {
                log.warning(`[${modelNumber}] PDF parse error: ${parseErr.message}`);
            }

            // Upload to Supabase storage
            const storagePath = `${brandSlug}/${modelNumber}/owners_manual.pdf`;
            const uploadResp = await fetch(`${supabaseUrl}/storage/v1/object/equipment-manuals/${storagePath}`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/pdf', 'x-upsert': 'true' },
                body: pdfBuffer,
            });

            if (uploadResp.ok) {
                await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
                    method: 'PATCH',
                    headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
                    body: JSON.stringify({ source_url: manualsLibUrl, file_path: storagePath, file_size_bytes: pdfBuffer.length, last_verified_at: new Date().toISOString() }),
                });

                log.info(`✓ ${brand} ${modelNumber} — ${verificationStatus} (${Math.round(pdfBuffer.length / 1024)} KB)`);
                results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl || manualsLibUrl, verification_status: verificationStatus });
                return;
            }
        }

        // Fallback
        await saveSource(supabaseId, manualsLibUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualsLibUrl, verification_status: 'LINK_ONLY' });

    } catch (err) {
        log.warning(`[${modelNumber}] Error: ${err.message}`);
        await saveSource(supabaseId, manualsLibUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualsLibUrl, verification_status: 'ERROR' });
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
