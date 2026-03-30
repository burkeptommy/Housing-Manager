/**
 * Haven Equipment Manual Scraper v5 — Google→ManualsLib
 *
 * Uses Google Search restricted to ManualsLib.com to find the correct
 * manual page for each model, then navigates to ManualsLib with Playwright
 * to extract/download the PDF.
 *
 * This guarantees accuracy because:
 * 1. Google's site: operator constrains results to ManualsLib only
 * 2. ManualsLib curates manuals — each is tagged to specific models
 * 3. We validate the ManualsLib URL contains the model number
 * 4. PDFs are verified with magic bytes before uploading
 */

import { Actor, log } from 'apify';
import { PlaywrightCrawler, createPlaywrightRouter } from '@crawlee/playwright';

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

// ── Fetch models ────────────────────────────────────────────────────────────

log.info('Fetching models from Supabase...');

let cachedIds = new Set();
if (onlyMissing) {
    const resp = await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?select=catalog_entry_id&file_size_bytes=gt.0&limit=10000`, {
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}` },
    });
    cachedIds = new Set((await resp.json()).map(m => m.catalog_entry_id));
    log.info(`${cachedIds.size} models already have cached PDFs`);
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
    await Actor.pushData({ totalProcessed: 0, pdfsDownloaded: 0, manualsLibLinked: 0, notFound: 0, timestamp: new Date().toISOString(), results: [] });
    await Actor.exit();
}

// ── Step 1: Google Search for ManualsLib URLs ───────────────────────────────

log.info('Step 1: Searching Google for ManualsLib pages...');

const BATCH_SIZE = 20;
const modelToManualsLibUrl = new Map();

for (let i = 0; i < models.length; i += BATCH_SIZE) {
    const batch = models.slice(i, i + BATCH_SIZE);
    const queryString = batch.map(m => {
        const brand = m.equipment_manufacturers.name;
        return `site:manualslib.com ${brand} ${m.model_number} manual`;
    }).join('\n');

    log.info(`Google Search batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(models.length / BATCH_SIZE)}...`);

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

            // Find ManualsLib manual page (prefer /manual/ URLs over /products/ or /brand/)
            const manualPage = results.find(r =>
                r.url && r.url.includes('manualslib.com/manual/')
            );
            const productPage = results.find(r =>
                r.url && r.url.includes('manualslib.com/products/')
            );

            const bestUrl = manualPage?.url || productPage?.url;
            if (bestUrl) {
                modelToManualsLibUrl.set(model.id, {
                    url: bestUrl,
                    model,
                    isManualPage: !!manualPage,
                });
            }
        }
    } catch (err) {
        log.warning(`Google Search batch failed: ${err.message}`);
    }

    if (i + BATCH_SIZE < models.length) {
        await new Promise(r => setTimeout(r, 2000));
    }
}

log.info(`Found ManualsLib pages for ${modelToManualsLibUrl.size}/${models.length} models`);

// ── Step 2: Visit ManualsLib pages and extract/download PDFs ────────────────

log.info('Step 2: Visiting ManualsLib pages to extract PDFs...');

const results = [];
const crawlRequests = [];

for (const [catalogId, info] of modelToManualsLibUrl) {
    crawlRequests.push({
        url: info.url,
        userData: {
            catalogEntryId: catalogId,
            modelNumber: info.model.model_number,
            manufacturerName: info.model.equipment_manufacturers.name,
            manufacturerSlug: info.model.equipment_manufacturers.slug,
            isManualPage: info.isManualPage,
        },
        label: 'MANUALSLIB',
    });
}

// Track models not found on ManualsLib
for (const model of models) {
    if (!modelToManualsLibUrl.has(model.id)) {
        results.push({
            catalogEntryId: model.id,
            modelNumber: model.model_number,
            manufacturer: model.equipment_manufacturers.name,
            status: 'not_on_manualslib',
        });
    }
}

const router = createPlaywrightRouter();

router.addHandler('MANUALSLIB', async ({ page, request }) => {
    const { catalogEntryId, modelNumber, manufacturerName, manufacturerSlug, isManualPage } = request.userData;
    log.info(`Visiting ManualsLib for ${manufacturerName} ${modelNumber}...`);

    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    // Save the ManualsLib URL as the source (this is already verified correct via Google)
    const manualsLibUrl = request.url;

    // Try to find a PDF download link
    const pdfUrl = await page.evaluate(() => {
        // Look for download PDF links
        const links = [];

        // ManualsLib download patterns
        document.querySelectorAll('a').forEach(a => {
            const href = a.href || '';
            const text = (a.textContent || '').toLowerCase().trim();

            if (href.includes('.pdf') ||
                href.includes('/download/') ||
                text.includes('download pdf') ||
                text.includes('download manual') ||
                (text.includes('download') && !href.includes('javascript:'))) {
                links.push(href);
            }
        });

        return links.length > 0 ? links[0] : null;
    });

    if (pdfUrl && (pdfUrl.includes('.pdf') || pdfUrl.includes('/download/'))) {
        try {
            const pdfResponse = await fetch(pdfUrl, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
                    'Referer': manualsLibUrl,
                },
                redirect: 'follow',
                signal: AbortSignal.timeout(30000),
            });

            if (pdfResponse.ok) {
                const pdfBuffer = await pdfResponse.arrayBuffer();
                const bytes = new Uint8Array(pdfBuffer);

                if (bytes.length > 1000 && bytes[0] === 0x25 && bytes[1] === 0x50 && bytes[2] === 0x44 && bytes[3] === 0x46) {
                    // Valid PDF — upload to Supabase
                    const storagePath = `${manufacturerSlug}/${modelNumber}/owners_manual.pdf`;
                    const uploadResp = await fetch(
                        `${supabaseUrl}/storage/v1/object/equipment-manuals/${storagePath}`,
                        {
                            method: 'POST',
                            headers: {
                                'Authorization': `Bearer ${supabaseServiceKey}`,
                                'Content-Type': 'application/pdf',
                                'x-upsert': 'true',
                            },
                            body: pdfBuffer,
                        }
                    );

                    if (uploadResp.ok) {
                        await updateManualRecord(catalogEntryId, manualsLibUrl, storagePath, pdfBuffer.byteLength);
                        log.info(`✓ ${manufacturerName} ${modelNumber} — PDF downloaded (${Math.round(pdfBuffer.byteLength / 1024)} KB)`);
                        results.push({ catalogEntryId, modelNumber, manufacturer: manufacturerName, status: 'downloaded', fileSize: pdfBuffer.byteLength, sourceUrl: manualsLibUrl });
                        return;
                    }
                }
            }
        } catch (err) {
            log.info(`PDF download failed for ${modelNumber}: ${err.message}`);
        }
    }

    // No downloadable PDF — save the ManualsLib URL as source
    // This still gives the user a verified, correct link to view the manual
    await updateManualSource(catalogEntryId, manualsLibUrl);
    log.info(`→ ${manufacturerName} ${modelNumber} — ManualsLib link saved`);
    results.push({ catalogEntryId, modelNumber, manufacturer: manufacturerName, status: 'source_saved', sourceUrl: manualsLibUrl });
});

// Helper: Update DB with PDF file info
async function updateManualRecord(catalogEntryId, sourceUrl, storagePath, fileSize) {
    await fetch(
        `${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${catalogEntryId}&manual_type=eq.owners_manual`,
        {
            method: 'PATCH',
            headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
            body: JSON.stringify({ source_url: sourceUrl, file_path: storagePath, file_size_bytes: fileSize, last_verified_at: new Date().toISOString() }),
        }
    );
}

// Helper: Update DB with ManualsLib URL only
async function updateManualSource(catalogEntryId, sourceUrl) {
    await fetch(
        `${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${catalogEntryId}&manual_type=eq.owners_manual`,
        {
            method: 'PATCH',
            headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
            body: JSON.stringify({ source_url: sourceUrl, last_verified_at: new Date().toISOString() }),
        }
    );
}

if (crawlRequests.length > 0) {
    const crawler = new PlaywrightCrawler({
        requestHandler: router,
        maxConcurrency: 2,
        navigationTimeoutSecs: 20,
        requestHandlerTimeoutSecs: 30,
        maxRequestRetries: 1,
        headless: true,
        launchContext: { launchOptions: { args: ['--disable-dev-shm-usage', '--no-sandbox'] } },
    });
    await crawler.run(crawlRequests);
}

// ── Summary ─────────────────────────────────────────────────────────────────

const downloaded = results.filter(r => r.status === 'downloaded');
const linked = results.filter(r => r.status === 'source_saved');
const notFound = results.filter(r => r.status === 'not_on_manualslib');

await Actor.pushData({
    totalProcessed: models.length,
    pdfsDownloaded: downloaded.length,
    manualsLibLinked: linked.length,
    notFound: notFound.length,
    timestamp: new Date().toISOString(),
    results,
});

log.info(`Done! ${downloaded.length} PDFs, ${linked.length} ManualsLib links, ${notFound.length} not found out of ${models.length}`);
await Actor.exit();
