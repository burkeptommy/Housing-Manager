/**
 * Haven Equipment Manual Scraper
 *
 * Crawls manufacturer support portals to find and download equipment manual PDFs.
 * Uses PlaywrightCrawler for JS-heavy sites (Samsung, GE, Carrier, etc.).
 *
 * Input: List of models to find manuals for (fetched from Supabase).
 * Output: Dataset of found PDF URLs + downloaded PDFs to key-value store.
 *
 * Designed to run on a weekly/monthly schedule via Apify Scheduler.
 */

import { Actor, log } from 'apify';
import { PlaywrightCrawler, createPlaywrightRouter } from '@crawlee/playwright';

await Actor.init();

// Get input
const input = await Actor.getInput() ?? {};
const {
    supabaseUrl = '',
    supabaseServiceKey = '',
    batchSize = 50,
    manufacturerSlug = null, // null = all brands, or specific slug like 'samsung'
    onlyMissing = true, // Only process models without cached PDFs
} = input;

if (!supabaseUrl || !supabaseServiceKey) {
    log.error('Missing supabaseUrl or supabaseServiceKey in input');
    await Actor.exit({ exitCode: 1 });
}

// Fetch models that need manuals from Supabase
log.info('Fetching models from Supabase...');

let url = `${supabaseUrl}/rest/v1/equipment_catalog?select=id,model_number,model_name,equipment_manufacturers!inner(name,slug,support_url,website_url),equipment_categories!inner(name,slug)&limit=${batchSize}`;

if (manufacturerSlug) {
    url += `&equipment_manufacturers.slug=eq.${manufacturerSlug}`;
}

const modelsResponse = await fetch(url, {
    headers: {
        'apikey': supabaseServiceKey,
        'Authorization': `Bearer ${supabaseServiceKey}`,
    },
});

const models = await modelsResponse.json();
log.info(`Fetched ${models.length} models to process`);

if (onlyMissing) {
    // Filter to only models without cached PDFs
    const manualsUrl = `${supabaseUrl}/rest/v1/equipment_manuals?select=catalog_entry_id&file_size_bytes=gt.0`;
    const manualsResponse = await fetch(manualsUrl, {
        headers: {
            'apikey': supabaseServiceKey,
            'Authorization': `Bearer ${supabaseServiceKey}`,
        },
    });
    const cachedManuals = await manualsResponse.json();
    const cachedIds = new Set(cachedManuals.map(m => m.catalog_entry_id));

    const filteredModels = models.filter(m => !cachedIds.has(m.id));
    log.info(`After filtering: ${filteredModels.length} models need manuals (${models.length - filteredModels.length} already cached)`);
    models.length = 0;
    models.push(...filteredModels);
}

// Build search URLs for each model based on manufacturer
const searchRequests = [];

for (const model of models) {
    const mfg = model.equipment_manufacturers;
    const slug = mfg.slug;
    const modelNumber = model.model_number;
    const supportUrl = mfg.support_url || mfg.website_url;

    // Build the search URL based on manufacturer
    let searchUrl;
    switch (slug) {
        // Samsung
        case 'samsung':
            searchUrl = `https://www.samsung.com/us/support/model/${modelNumber}/`;
            break;
        // GE family
        case 'ge-appliances':
        case 'ge-profile':
        case 'monogram':
        case 'cafe':
        case 'hotpoint':
            searchUrl = `https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber=${modelNumber}`;
            break;
        // Whirlpool family
        case 'whirlpool':
        case 'maytag':
        case 'kitchenaid':
        case 'amana':
        case 'jennair':
            searchUrl = `https://www.${slug === 'jennair' ? 'jennair' : slug}.com/owners-center-pdp.${modelNumber}.html`;
            break;
        // Carrier family
        case 'carrier':
        case 'bryant':
        case 'payne':
            searchUrl = `https://www.${slug}.com/en/us/support/product-literature/`;
            break;
        // Frigidaire / Electrolux
        case 'frigidaire':
            searchUrl = `https://support.frigidaire.com/Owner-Center/Product-Support/${modelNumber}`;
            break;
        case 'electrolux':
            searchUrl = `https://www.electrolux.com/us/support/product-support/${modelNumber}`;
            break;
        // BSH family
        case 'bosch':
        case 'thermador':
        case 'gaggenau':
            searchUrl = `https://www.${slug === 'bosch' ? 'bosch-home.com/us' : slug + '.com/us'}/support/${modelNumber}`;
            break;
        // Bathroom
        case 'kohler':
            searchUrl = `https://www.us.kohler.com/us/search?q=${modelNumber}&type=documents`;
            break;
        case 'delta-faucet':
            searchUrl = `https://www.deltafaucet.com/own/${modelNumber}`;
            break;
        case 'moen':
            searchUrl = `https://www.moen.com/support/product-support?modelNumber=${modelNumber}`;
            break;
        // Default: use support URL with model as query
        default:
            searchUrl = `${supportUrl}?q=${modelNumber}`;
            break;
    }

    searchRequests.push({
        url: searchUrl,
        userData: {
            catalogEntryId: model.id,
            modelNumber,
            manufacturerName: mfg.name,
            manufacturerSlug: slug,
        },
        label: 'SEARCH',
    });
}

log.info(`Built ${searchRequests.length} search requests`);

// Results collection
const results = [];

// Create router
const router = createPlaywrightRouter();

router.addHandler('SEARCH', async ({ page, request, log: reqLog }) => {
    const { catalogEntryId, modelNumber, manufacturerName, manufacturerSlug } = request.userData;

    reqLog.info(`Searching for ${manufacturerName} ${modelNumber}...`);

    // Wait for page to fully load (JS rendering)
    await page.waitForLoadState('networkidle', { timeout: 15000 }).catch(() => {});

    // Find all PDF links on the page
    const pdfLinks = await page.evaluate(() => {
        const links = [];

        // Strategy 1: Find <a> tags with .pdf hrefs
        document.querySelectorAll('a[href*=".pdf"]').forEach(a => {
            links.push({
                url: a.href,
                text: (a.textContent || '').trim().toLowerCase(),
            });
        });

        // Strategy 2: Find download buttons/links that might have data attributes
        document.querySelectorAll('[data-url*=".pdf"], [data-href*=".pdf"]').forEach(el => {
            const url = el.getAttribute('data-url') || el.getAttribute('data-href');
            if (url) links.push({ url, text: (el.textContent || '').trim().toLowerCase() });
        });

        // Strategy 3: Check for iframe or embed src with .pdf
        document.querySelectorAll('iframe[src*=".pdf"], embed[src*=".pdf"]').forEach(el => {
            links.push({ url: el.src, text: 'embedded pdf' });
        });

        // Strategy 4: Check onclick handlers that reference PDFs
        document.querySelectorAll('[onclick*=".pdf"]').forEach(el => {
            const match = el.getAttribute('onclick').match(/https?:\/\/[^\s'"]+\.pdf/i);
            if (match) links.push({ url: match[0], text: (el.textContent || '').trim().toLowerCase() });
        });

        return links;
    });

    if (pdfLinks.length === 0) {
        reqLog.warning(`No PDF links found for ${manufacturerName} ${modelNumber}`);
        results.push({
            catalogEntryId,
            modelNumber,
            manufacturer: manufacturerName,
            status: 'no_pdfs_found',
            pageUrl: request.url,
        });
        return;
    }

    reqLog.info(`Found ${pdfLinks.length} PDF links for ${modelNumber}`);

    // Classify PDFs by type
    const classified = { owners_manual: null, installation_guide: null, spec_sheet: null };

    for (const link of pdfLinks) {
        const text = link.text;
        const urlLower = link.url.toLowerCase();

        if (!classified.owners_manual && (
            text.includes('owner') || text.includes('manual') || text.includes('use') ||
            text.includes('care') || text.includes('guide') ||
            urlLower.includes('owner') || urlLower.includes('manual') ||
            urlLower.includes('useandcare') || urlLower.includes('use-and-care')
        )) {
            classified.owners_manual = link.url;
        } else if (!classified.installation_guide && (
            text.includes('install') || text.includes('setup') ||
            urlLower.includes('install') || urlLower.includes('setup')
        )) {
            classified.installation_guide = link.url;
        } else if (!classified.spec_sheet && (
            text.includes('spec') || text.includes('dimension') || text.includes('data sheet') ||
            urlLower.includes('spec') || urlLower.includes('dimension')
        )) {
            classified.spec_sheet = link.url;
        }
    }

    // If nothing classified, use first PDF as owners_manual
    if (!classified.owners_manual && pdfLinks.length > 0) {
        classified.owners_manual = pdfLinks[0].url;
    }

    // Download PDFs and upload to Supabase storage
    for (const [manualType, pdfUrl] of Object.entries(classified)) {
        if (!pdfUrl) continue;

        try {
            reqLog.info(`Downloading ${manualType} for ${modelNumber}: ${pdfUrl}`);

            const pdfResponse = await fetch(pdfUrl, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                },
            });

            if (!pdfResponse.ok) {
                reqLog.warning(`Failed to download ${pdfUrl}: HTTP ${pdfResponse.status}`);
                continue;
            }

            const pdfBuffer = await pdfResponse.arrayBuffer();
            const pdfBytes = new Uint8Array(pdfBuffer);

            // Verify PDF magic bytes
            if (pdfBytes[0] !== 0x25 || pdfBytes[1] !== 0x50 || pdfBytes[2] !== 0x44 || pdfBytes[3] !== 0x46) {
                reqLog.warning(`Response is not a PDF for ${modelNumber} ${manualType}`);
                continue;
            }

            const fileSize = pdfBuffer.byteLength;
            if (fileSize < 1000) {
                reqLog.warning(`PDF too small (${fileSize} bytes) for ${modelNumber}`);
                continue;
            }

            // Upload to Supabase storage
            const storagePath = `${manufacturerSlug}/${modelNumber}/${manualType}.pdf`;

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
                const err = await uploadResponse.text();
                reqLog.warning(`Upload failed for ${storagePath}: ${err}`);
                continue;
            }

            // Update equipment_manuals record
            const updateResponse = await fetch(
                `${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${catalogEntryId}&manual_type=eq.${manualType}`,
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
                        file_size_bytes: fileSize,
                        last_verified_at: new Date().toISOString(),
                    }),
                }
            );

            reqLog.info(`✓ ${manufacturerName} ${modelNumber} ${manualType} (${Math.round(fileSize / 1024)} KB)`);

            results.push({
                catalogEntryId,
                modelNumber,
                manufacturer: manufacturerName,
                manualType,
                status: 'downloaded',
                pdfUrl,
                fileSize,
                storagePath,
            });
        } catch (err) {
            reqLog.warning(`Error processing ${modelNumber} ${manualType}: ${err.message}`);
        }
    }
});

// Create and run the crawler
const crawler = new PlaywrightCrawler({
    requestHandler: router,
    maxConcurrency: 3, // Be respectful to manufacturer sites
    navigationTimeoutSecs: 30,
    requestHandlerTimeoutSecs: 60,
    maxRequestRetries: 1,
    headless: true,
    launchContext: {
        launchOptions: {
            args: ['--disable-dev-shm-usage'],
        },
    },
});

if (searchRequests.length > 0) {
    await crawler.run(searchRequests);
}

// Push summary to dataset
const downloaded = results.filter(r => r.status === 'downloaded');
const notFound = results.filter(r => r.status === 'no_pdfs_found');

const summary = {
    totalProcessed: searchRequests.length,
    pdfsDownloaded: downloaded.length,
    notFound: notFound.length,
    timestamp: new Date().toISOString(),
    results,
};

await Actor.pushData(summary);

log.info(`Done! ${downloaded.length} PDFs downloaded, ${notFound.length} not found out of ${searchRequests.length} models`);

await Actor.exit();
