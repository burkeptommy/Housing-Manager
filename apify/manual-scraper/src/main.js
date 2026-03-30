/**
 * Haven Equipment Manual Scraper v3
 *
 * Uses Google Search to find direct PDF URLs for equipment manuals,
 * then downloads and uploads them to Supabase storage.
 *
 * This approach works for ALL brands including JS-heavy sites like
 * Samsung, GE, and Carrier because Google already indexes their PDFs.
 */

import { Actor, log } from 'apify';

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
    log.error('Missing supabaseUrl or supabaseServiceKey in input');
    await Actor.exit({ exitCode: 1 });
}

// ── Fetch models from Supabase ──────────────────────────────────────────────

log.info('Fetching models from Supabase...');

// First, get IDs of models that already have cached PDFs
let cachedIds = new Set();
if (onlyMissing) {
    const manualsUrl = `${supabaseUrl}/rest/v1/equipment_manuals?select=catalog_entry_id&file_size_bytes=gt.0&limit=10000`;
    const manualsResponse = await fetch(manualsUrl, {
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}` },
    });
    cachedIds = new Set((await manualsResponse.json()).map(m => m.catalog_entry_id));
    log.info(`Found ${cachedIds.size} models with cached PDFs`);
}

// Fetch ALL catalog entries (paginated) then filter
let allModels = [];
let offset = 0;
const PAGE_SIZE = 1000;

while (true) {
    let url = `${supabaseUrl}/rest/v1/equipment_catalog?select=id,model_number,model_name,equipment_manufacturers!inner(name,slug,support_url),equipment_categories!inner(name,slug)&limit=${PAGE_SIZE}&offset=${offset}&order=id`;
    if (manufacturerSlug) {
        url += `&equipment_manufacturers.slug=eq.${manufacturerSlug}`;
    }

    const modelsResponse = await fetch(url, {
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}` },
    });
    const page = await modelsResponse.json();
    if (!page || page.length === 0) break;

    allModels.push(...page);
    offset += PAGE_SIZE;
    if (page.length < PAGE_SIZE) break;
}

log.info(`Fetched ${allModels.length} total models from catalog`);

// Filter to only uncovered models
let models;
if (onlyMissing) {
    models = allModels.filter(m => !cachedIds.has(m.id));
    log.info(`${models.length} models need manuals (${cachedIds.size} already cached)`);
} else {
    models = allModels;
}

// Limit to batchSize
if (models.length > batchSize) {
    models = models.slice(0, batchSize);
    log.info(`Processing first ${batchSize} of ${models.length} uncovered models`);
}

if (models.length === 0) {
    log.info('No models need manuals. Exiting.');
    await Actor.pushData({ totalProcessed: 0, pdfsDownloaded: 0, notFound: 0, timestamp: new Date().toISOString(), results: [] });
    await Actor.exit();
}

// ── Build Google Search queries ─────────────────────────────────────────────

// Batch models into groups of 5 queries per Google Search run
// (to stay within rate limits and costs)
const queries = models.map(model => {
    const mfg = model.equipment_manufacturers;
    return {
        query: `${mfg.name} ${model.model_number} owner manual PDF filetype:pdf`,
        model,
    };
});

log.info(`Built ${queries.length} Google Search queries`);

// ── Run Google Search Scraper ───────────────────────────────────────────────

const GOOGLE_SCRAPER_ID = 'apify/google-search-scraper';

// Process in batches of 20 queries to manage costs
const BATCH_SIZE = 20;
const allResults = [];

for (let i = 0; i < queries.length; i += BATCH_SIZE) {
    const batch = queries.slice(i, i + BATCH_SIZE);
    const queryString = batch.map(q => q.query).join('\n');

    log.info(`Running Google Search batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(queries.length / BATCH_SIZE)} (${batch.length} queries)...`);

    // Call Google Search Scraper via Apify API
    const searchRun = await Actor.call(GOOGLE_SCRAPER_ID, {
        queries: queryString,
        maxPagesPerQuery: 1,
        resultsPerPage: 5,
        countryCode: 'us',
        languageCode: 'en',
    });

    // Get the results
    const searchDataset = await Actor.apifyClient.dataset(searchRun.defaultDatasetId);
    const { items: searchResults } = await searchDataset.listItems();

    // Match search results back to models
    for (let j = 0; j < batch.length && j < searchResults.length; j++) {
        const model = batch[j].model;
        const searchResult = searchResults[j];
        const organicResults = searchResult?.organicResults || [];

        // Find PDF URLs in the results
        const pdfUrls = [];
        for (const result of organicResults) {
            const resultUrl = result.url || '';
            if (resultUrl.toLowerCase().includes('.pdf')) {
                pdfUrls.push({
                    url: resultUrl,
                    title: (result.title || '').toLowerCase(),
                    description: (result.description || '').toLowerCase(),
                });
            }
        }

        allResults.push({
            model,
            pdfUrls,
        });
    }

    // Small delay between batches
    if (i + BATCH_SIZE < queries.length) {
        await new Promise(r => setTimeout(r, 2000));
    }
}

log.info(`Google Search complete. Found PDF URLs for ${allResults.filter(r => r.pdfUrls.length > 0).length}/${allResults.length} models`);

// ── Download PDFs and upload to Supabase ────────────────────────────────────

const results = [];

for (const { model, pdfUrls } of allResults) {
    const mfg = model.equipment_manufacturers;
    const modelNumber = model.model_number;

    if (pdfUrls.length === 0) {
        results.push({
            catalogEntryId: model.id,
            modelNumber,
            manufacturer: mfg.name,
            status: 'no_pdfs_found',
        });
        continue;
    }

    // Classify the PDFs
    const classified = { owners_manual: null, installation_guide: null, spec_sheet: null };

    for (const pdf of pdfUrls) {
        const text = pdf.title + ' ' + pdf.description;
        const urlLower = pdf.url.toLowerCase();

        if (!classified.owners_manual && (
            text.includes('owner') || text.includes('manual') || text.includes('use') ||
            text.includes('care') || text.includes('user guide') ||
            urlLower.includes('owner') || urlLower.includes('manual') ||
            urlLower.includes('useandcare') || urlLower.includes('user')
        )) {
            classified.owners_manual = pdf.url;
        } else if (!classified.installation_guide && (
            text.includes('install') || text.includes('setup') || text.includes('quick') ||
            urlLower.includes('install') || urlLower.includes('setup')
        )) {
            classified.installation_guide = pdf.url;
        } else if (!classified.spec_sheet && (
            text.includes('spec') || text.includes('dimension') || text.includes('data sheet') ||
            urlLower.includes('spec') || urlLower.includes('dimension')
        )) {
            classified.spec_sheet = pdf.url;
        }
    }

    // Fallback: first PDF is owners_manual
    if (!classified.owners_manual && pdfUrls.length > 0) {
        classified.owners_manual = pdfUrls[0].url;
    }

    // Download and upload each PDF
    for (const [manualType, pdfUrl] of Object.entries(classified)) {
        if (!pdfUrl) continue;

        try {
            log.info(`Downloading ${mfg.name} ${modelNumber} ${manualType}...`);

            const pdfResponse = await fetch(pdfUrl, {
                headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' },
                redirect: 'follow',
                signal: AbortSignal.timeout(30000),
            });

            if (!pdfResponse.ok) {
                log.warning(`HTTP ${pdfResponse.status} for ${modelNumber} from ${new URL(pdfUrl).hostname}`);
                continue;
            }

            const pdfBuffer = await pdfResponse.arrayBuffer();
            const pdfBytes = new Uint8Array(pdfBuffer);

            // Verify PDF magic bytes
            if (pdfBytes.length < 5 || pdfBytes[0] !== 0x25 || pdfBytes[1] !== 0x50 ||
                pdfBytes[2] !== 0x44 || pdfBytes[3] !== 0x46) {
                log.warning(`Not a PDF for ${modelNumber} ${manualType}`);
                continue;
            }

            if (pdfBuffer.byteLength < 1000) continue;

            // Upload to Supabase storage
            const storagePath = `${mfg.slug}/${modelNumber}/${manualType}.pdf`;
            const uploadResponse = await fetch(
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

            if (!uploadResponse.ok) {
                log.warning(`Upload failed for ${storagePath}: ${await uploadResponse.text()}`);
                continue;
            }

            // Update equipment_manuals record
            await fetch(
                `${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${model.id}&manual_type=eq.${manualType}`,
                {
                    method: 'PATCH',
                    headers: {
                        'apikey': supabaseServiceKey,
                        'Authorization': `Bearer ${supabaseServiceKey}`,
                        'Content-Type': 'application/json',
                        'Prefer': 'return=minimal',
                    },
                    body: JSON.stringify({
                        source_url: pdfUrl,
                        file_path: storagePath,
                        file_size_bytes: pdfBuffer.byteLength,
                        last_verified_at: new Date().toISOString(),
                    }),
                }
            );

            const sizeKB = Math.round(pdfBuffer.byteLength / 1024);
            log.info(`✓ ${mfg.name} ${modelNumber} ${manualType} (${sizeKB} KB)`);

            results.push({
                catalogEntryId: model.id,
                modelNumber,
                manufacturer: mfg.name,
                manualType,
                status: 'downloaded',
                pdfUrl,
                fileSize: pdfBuffer.byteLength,
                storagePath,
            });
        } catch (err) {
            log.warning(`Error: ${modelNumber} ${manualType}: ${err.message}`);
        }
    }

    // If nothing downloaded for this model
    const downloadedForModel = results.filter(r => r.modelNumber === modelNumber && r.status === 'downloaded');
    if (downloadedForModel.length === 0 && !results.find(r => r.modelNumber === modelNumber)) {
        results.push({
            catalogEntryId: model.id,
            modelNumber,
            manufacturer: mfg.name,
            status: 'pdf_found_but_download_failed',
            pdfUrl: classified.owners_manual,
        });
    }
}

// ── Summary ─────────────────────────────────────────────────────────────────

const downloaded = results.filter(r => r.status === 'downloaded');
const notFound = results.filter(r => r.status === 'no_pdfs_found');
const failedDownload = results.filter(r => r.status === 'pdf_found_but_download_failed');

await Actor.pushData({
    totalProcessed: models.length,
    pdfsDownloaded: downloaded.length,
    notFound: notFound.length,
    downloadFailed: failedDownload.length,
    timestamp: new Date().toISOString(),
    results,
});

log.info(`Done! ${downloaded.length} PDFs downloaded, ${notFound.length} not found, ${failedDownload.length} download failed out of ${models.length} models`);

await Actor.exit();
