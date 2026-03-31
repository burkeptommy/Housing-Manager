/**
 * Haven Equipment Manual Scraper v8 — Active Emulation
 *
 * Pipeline:
 * 1. Supabase fetch + color-code stripping
 * 2. Google Search (site:manualslib.com, US region, fuzzy brand+model)
 * 3. URL rewrite /manual/ → /download/
 * 4. 2Captcha solve with fast polling
 * 5. Network interception + double-tap injection + immediate click
 * 6. "Something went wrong" retry with cookie clear + fresh proxy
 * 7. CDN link extraction → PDF fetch → verification → upload
 */

import { Actor, log } from 'apify';
import { PlaywrightCrawler, createPlaywrightRouter } from '@crawlee/playwright';
import { Solver } from '2captcha-ts';

const TWOCAPTCHA_KEY = '91a11773cf07e2e561c0fd5e3980f258';
const solver = new Solver(TWOCAPTCHA_KEY);

function extractPdfText(buffer, maxBytes = 500000) {
    const slice = buffer.slice(0, Math.min(buffer.length, maxBytes));
    const str = slice.toString('latin1');
    const matches = str.match(/[\x20-\x7E]{4,}/g) || [];
    return matches.join(' ').toUpperCase();
}

function stripColorCode(model) {
    const cleaned = model.replace(/[^A-Za-z0-9-]/g, '');
    if (cleaned.length <= 6) return cleaned;
    const match = cleaned.match(/^(.+\d)[A-Za-z]{1,2}$/);
    return match ? match[1] : cleaned;
}

await Actor.init();

const input = await Actor.getInput() ?? {};
const { supabaseUrl = '', supabaseServiceKey = '', batchSize = 50, manufacturerSlug = null, onlyMissing = true } = input;

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

// ── Google Search ───────────────────────────────────────────────────────────

log.info('Searching Google for ManualsLib pages...');

const SEARCH_BATCH = 20;
const modelToUrl = new Map();

for (let i = 0; i < models.length; i += SEARCH_BATCH) {
    const batch = models.slice(i, i + SEARCH_BATCH);
    const queryString = batch.map(m => {
        const brand = m.equipment_manufacturers.name;
        const base = stripColorCode(m.model_number.replace(/[^A-Za-z0-9-]/g, ''));
        return `site:manualslib.com ${brand} ${base} manual`;
    }).join('\n');

    log.info(`Google batch ${Math.floor(i / SEARCH_BATCH) + 1}/${Math.ceil(models.length / SEARCH_BATCH)}...`);

    try {
        const searchRun = await Actor.call('apify/google-search-scraper', {
            queries: queryString, maxPagesPerQuery: 1, resultsPerPage: 3,
            countryCode: 'us', languageCode: 'en',
        });
        const dataset = await Actor.apifyClient.dataset(searchRun.defaultDatasetId);
        const { items } = await dataset.listItems();

        for (let j = 0; j < batch.length && j < items.length; j++) {
            const results = items[j]?.organicResults || [];
            const manualPage = results.find(r => r.url?.includes('manualslib.com/manual/'));
            const productPage = results.find(r => r.url?.includes('manualslib.com/products/'));
            if (manualPage?.url || productPage?.url) {
                modelToUrl.set(batch[j].id, { url: (manualPage?.url || productPage?.url), model: batch[j] });
            }
        }
    } catch (err) {
        log.warning(`Google batch failed: ${err.message}`);
    }

    if (i + SEARCH_BATCH < models.length) await new Promise(r => setTimeout(r, 2000));
}

log.info(`Found ManualsLib pages for ${modelToUrl.size}/${models.length} models`);

// ── Build crawl requests ────────────────────────────────────────────────────

const HARDCODED_TEST = true; // REMOVE AFTER TESTING

const results = [];
const crawlRequests = [];

if (HARDCODED_TEST) {
    const testUrl = 'https://www.manualslib.com/manual/797523/Lincat-Eco8.html';
    const downloadUrl = testUrl.split('?')[0].split('#')[0].replace('/manual/', '/download/');
    log.info(`HARDCODED TEST: ${downloadUrl}`);
    crawlRequests.push({
        url: downloadUrl,
        userData: { supabaseId: 'test', modelNumber: 'Eco8', brand: 'Lincat', brandSlug: 'lincat', originalModel: 'Eco8', manualPageUrl: testUrl },
        label: 'MANUALSLIB',
    });
} else {
    for (const [catalogId, info] of modelToUrl) {
        const cleanUrl = info.url.split('?')[0].split('#')[0];
        const downloadUrl = cleanUrl.replace('/manual/', '/download/');
        crawlRequests.push({
            url: downloadUrl,
            userData: { supabaseId: catalogId, modelNumber: info.model.model_number, brand: info.model.equipment_manufacturers.name, brandSlug: info.model.equipment_manufacturers.slug, originalModel: info.model.model_number, manualPageUrl: info.url },
            label: 'MANUALSLIB',
        });
    }
    for (const model of models) {
        if (!modelToUrl.has(model.id)) {
            results.push({ supabase_id: model.id, brand: model.equipment_manufacturers.name, original_model: model.model_number, pdf_url: null, verification_status: 'NOT_FOUND' });
        }
    }
}

// ── Router ──────────────────────────────────────────────────────────────────

const router = createPlaywrightRouter();

router.addHandler('MANUALSLIB', async ({ page, request, session }) => {
    const { supabaseId, modelNumber, brand, brandSlug, originalModel, manualPageUrl } = request.userData;
    const safeModel = modelNumber.replace(/[^a-zA-Z0-9_-]/g, '_');
    const retryCount = request.retryCount || 0;

    log.info(`[${brand} ${modelNumber}] Attempt ${retryCount + 1} — download page: ${request.url}`);

    await page.waitForLoadState('domcontentloaded', { timeout: 20000 }).catch(() => {});
    await page.waitForTimeout(2000);

    // Step 1: Start network interception BEFORE any CAPTCHA interaction
    const interceptedPosts = [];
    page.on('request', req => {
        if (req.method() === 'POST' && req.url().includes('manualslib.com')) {
            log.info(`[API_WATCH] POST ${req.url()} | Payload: ${(req.postData() || '').substring(0, 200)}`);
            interceptedPosts.push({ url: req.url(), data: req.postData() });
        }
    });

    // Watch for ALL responses from manualslib.com — especially the /download POST response
    const interceptedResponses = [];
    let downloadPostResponse = null;
    page.on('response', async (res) => {
        const ct = res.headers()['content-type'] || '';
        const url = res.url();

        if (ct.includes('application/pdf') || url.includes('.pdf') || url.includes('cpdf')) {
            log.info(`[API_WATCH] PDF Response: ${url}`);
            interceptedResponses.push(url);
        }

        // Capture the /download POST response — this contains the CDN URL
        if (url.includes('manualslib.com/download') && res.request().method() === 'POST') {
            try {
                const body = await res.text();
                log.info(`[API_WATCH] Download POST response (${res.status()}): ${body.substring(0, 500)}`);
                downloadPostResponse = body;
            } catch(e) {
                log.info(`[API_WATCH] Could not read download response: ${e.message}`);
            }
        }
    });

    try {
        // Screenshot: download page
        const ss1 = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-downloadpage-${safeModel}-${retryCount}`, ss1, { contentType: 'image/png' });

        // Step 2: Check for "Something went wrong" from a previous attempt
        const errorText = await page.textContent('body');
        if (errorText?.includes('Something went wrong')) {
            log.warning(`[${modelNumber}] "Something went wrong" detected — clearing cookies and retrying`);
            if (session) session.retire();
            throw new Error('Something went wrong detected. Retrying with fresh session.');
        }

        // Step 3: Find reCAPTCHA and solve via 2Captcha
        const captchaIframe = await page.$('iframe[src*="recaptcha/api2/anchor"]');
        if (captchaIframe) {
            const iframeSrc = await captchaIframe.getAttribute('src');
            const sitekeyMatch = iframeSrc?.match(/k=([^&]+)/);
            const sitekey = sitekeyMatch?.[1];

            if (sitekey) {
                log.info(`[${modelNumber}] Sending to 2Captcha (sitekey: ${sitekey.substring(0, 12)}...)...`);

                // Fast polling — check every 5 seconds instead of default 10
                const solution = await solver.recaptcha({
                    pageurl: request.url,
                    googlekey: sitekey,
                    pollingInterval: 5000,
                });

                log.info(`[${modelNumber}] ✓ 2Captcha solved! Token: ${solution.data.substring(0, 30)}...`);

                // Step 4: Double-tap injection — set textarea + call ALL known callbacks + click immediately
                const injectionResult = await page.evaluate((token) => {
                    const info = [];

                    // Inject into ALL reCAPTCHA textareas
                    document.querySelectorAll('textarea[name="g-recaptcha-response"], #g-recaptcha-response').forEach(el => {
                        el.style.display = 'block';
                        el.value = token;
                        info.push('textarea_set');
                    });

                    // Call recaptchaCallback
                    if (typeof window.recaptchaCallback === 'function') {
                        try { window.recaptchaCallback(token); info.push('recaptchaCallback_OK'); } catch(e) { info.push('recaptchaCallback_ERR:' + e.message); }
                    }

                    // Call onSubmit
                    if (typeof window.onSubmit === 'function') {
                        try { window.onSubmit(token); info.push('onSubmit_OK'); } catch(e) { info.push('onSubmit_ERR'); }
                    }

                    // Try grecaptcha.execute if v3
                    try {
                        if (typeof grecaptcha !== 'undefined' && grecaptcha.execute) {
                            info.push('grecaptcha_exists');
                        }
                    } catch(e) {}

                    return info;
                }, solution.data);

                log.info(`[${modelNumber}] Injection: ${injectionResult.join(', ')}`);

                // Step 5: Set textarea + force-click "Get Manual" (bypass any overlay)
                log.info(`[${modelNumber}] Injecting token into textarea...`);

                await page.evaluate((token) => {
                    document.querySelectorAll('textarea[name="g-recaptcha-response"]').forEach(el => {
                        el.value = token;
                    });
                }, solution.data);

                // Call recaptchaCallback via evaluate — this triggers an AJAX POST
                // The callback may cause a navigation — we need to prevent that
                log.info(`[${modelNumber}] Calling recaptchaCallback...`);

                // Set up a MutationObserver to watch for href changes on .download-url and .view-url
                const hrefPromise = page.evaluate(() => {
                    return new Promise((resolve) => {
                        const targets = document.querySelectorAll('.download-url, .view-url');
                        if (!targets.length) { resolve(null); return; }

                        const observer = new MutationObserver((mutations) => {
                            for (const m of mutations) {
                                if (m.type === 'attributes' && m.attributeName === 'href') {
                                    const href = m.target.getAttribute('href');
                                    if (href && href.length > 10) {
                                        observer.disconnect();
                                        resolve(href);
                                        return;
                                    }
                                }
                            }
                        });

                        targets.forEach(t => observer.observe(t, { attributes: true, attributeFilter: ['href'] }));

                        // Timeout after 20s
                        setTimeout(() => { observer.disconnect(); resolve(null); }, 20000);
                    });
                });

                // Inject token into grecaptcha internals AND textarea, then call callback
                log.info(`[${modelNumber}] Injecting token into grecaptcha + calling callback...`);
                await page.evaluate((token) => {
                    // Set textarea
                    document.querySelectorAll('textarea[name="g-recaptcha-response"]').forEach(el => {
                        el.value = token;
                    });

                    // Try to set grecaptcha's internal response
                    try {
                        if (typeof grecaptcha !== 'undefined') {
                            // Override getResponse to return our token
                            const origGetResponse = grecaptcha.getResponse;
                            grecaptcha.getResponse = () => token;
                        }
                    } catch(e) {}

                    // Make the POST ourselves via XMLHttpRequest (synchronous with the callback)
                    const xhr = new XMLHttpRequest();
                    xhr.open('POST', window.location.href, true);
                    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === 4 && xhr.status === 200) {
                            try {
                                const resp = JSON.parse(xhr.responseText);
                                if (resp.error === '') {
                                    // Success! Now call the callback which should populate the hrefs
                                    if (typeof window.recaptchaCallback === 'function') {
                                        window.recaptchaCallback(token);
                                    }
                                }
                            } catch(e) {
                                // Response might be HTML — try callback anyway
                                if (typeof window.recaptchaCallback === 'function') {
                                    window.recaptchaCallback(token);
                                }
                            }
                        }
                    };
                    xhr.send('captcha=' + encodeURIComponent(token));
                }, solution.data);

                // Wait for the observer to catch the href
                const capturedHref = await hrefPromise;

                if (capturedHref) {
                    const fullUrl = capturedHref.startsWith('http') ? capturedHref : `https://www.manualslib.com${capturedHref}`;
                    log.info(`[${modelNumber}] ✓✓✓ MutationObserver captured CDN URL: ${fullUrl.substring(0, 80)}`);
                    await fetchAndUploadPdf(fullUrl, request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
                    return;
                }

                log.info(`[${modelNumber}] MutationObserver timed out — no href change detected`);
                await page.waitForTimeout(2000);

                const ssPost = await page.screenshot({ fullPage: true });
                await Actor.setValue(`debug-postcallback-${safeModel}`, ssPost, { contentType: 'image/png' });

                const postResult = { body: null };

                log.info(`[${modelNumber}] Direct POST result: status=${postResult.status}, bodyLength=${(postResult.body || '').length}`);

                // Search the full HTML response for any PDF or CDN links
                if (postResult.body) {
                    const body = postResult.body;

                    // Look for CDN URLs
                    const cdnMatch = body.match(/https?:\/\/data[12]\.manualslib\.com[^\s"'<>]+/i);
                    const cpdfMatch = body.match(/https?:\/\/[^\s"'<>]*cpdf[^\s"'<>]+\.pdf/i);
                    const anyPdfHref = body.match(/href="([^"]*\.pdf[^"]*)"/i);
                    const downloadLink = body.match(/href="(\/download\/[^"]+)"/ig);

                    log.info(`[${modelNumber}] POST body scan — cdn:${!!cdnMatch} cpdf:${!!cpdfMatch} pdfHref:${!!anyPdfHref} downloadLinks:${downloadLink?.length || 0}`);

                    // Also look for any data-url or onclick with PDF
                    const dataUrlMatch = body.match(/data-url="([^"]*\.pdf[^"]*)"/i);
                    const onclickPdf = body.match(/onclick="[^"]*([^"]*\.pdf[^"]*)/i);

                    // Dump a chunk of the body around "Download PDF" or "View in browser"
                    const downloadPdfIdx = body.indexOf('Download PDF');
                    const viewBrowserIdx = body.indexOf('View in browser');
                    if (downloadPdfIdx > -1) {
                        log.info(`[${modelNumber}] HTML around "Download PDF": ...${body.substring(Math.max(0, downloadPdfIdx - 100), downloadPdfIdx + 200)}...`);
                    }
                    if (viewBrowserIdx > -1) {
                        log.info(`[${modelNumber}] HTML around "View in browser": ...${body.substring(Math.max(0, viewBrowserIdx - 100), viewBrowserIdx + 200)}...`);
                    }

                    const foundInPost = cdnMatch?.[0] || cpdfMatch?.[0] || anyPdfHref?.[1] || dataUrlMatch?.[1];
                    if (foundInPost) {
                        const fullUrl = foundInPost.startsWith('http') ? foundInPost : `https://www.manualslib.com${foundInPost}`;
                        log.info(`[${modelNumber}] ✓ Found CDN URL in POST response: ${fullUrl.substring(0, 80)}`);
                        await fetchAndUploadPdf(fullUrl, request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
                        return;
                    }
                }

                // Reload the page to see if the session now has download access
                await page.reload({ waitUntil: 'domcontentloaded' });
                await page.waitForTimeout(3000);
            }
        } else {
            log.info(`[${modelNumber}] No reCAPTCHA found`);
            // Try clicking Get Manual directly
            const btn = await page.$('button:has-text("Get manual"), a:has-text("Get manual")');
            if (btn) { await btn.click(); await page.waitForTimeout(5000); }
        }

        // Step 6: Screenshot after click
        const ss2 = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-afterclick-${safeModel}-${retryCount}`, ss2, { contentType: 'image/png' });

        // Step 7: Check for "Something went wrong" after click
        const bodyText = await page.textContent('body').catch(() => '');
        if (bodyText?.includes('Something went wrong')) {
            log.warning(`[${modelNumber}] "Something went wrong" after click — retiring session, retrying`);
            if (session) session.retire();
            throw new Error('Something went wrong after click. Retrying with fresh session.');
        }

        // Step 8: Look for download/view links
        log.info(`[${modelNumber}] Looking for PDF download links...`);

        // Check the /download POST response for a CDN URL
        if (downloadPostResponse) {
            log.info(`[${modelNumber}] Analyzing download POST response...`);
            // Look for CDN URLs in the response
            const cdnMatch = downloadPostResponse.match(/https?:\/\/data[12]\.manualslib\.com[^\s"'<>]+\.pdf/i);
            const cpdfMatch = downloadPostResponse.match(/https?:\/\/[^\s"'<>]*cpdf[^\s"'<>]+\.pdf/i);
            const anyPdfMatch = downloadPostResponse.match(/https?:\/\/[^\s"'<>]+\.pdf/i);
            const foundUrl = cdnMatch?.[0] || cpdfMatch?.[0] || anyPdfMatch?.[0];
            if (foundUrl) {
                log.info(`[${modelNumber}] ✓ Found CDN URL in POST response: ${foundUrl.substring(0, 80)}`);
                await fetchAndUploadPdf(foundUrl, request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
                return;
            }
        }

        // Check intercepted responses
        if (interceptedResponses.length > 0) {
            log.info(`[${modelNumber}] ✓ Intercepted PDF response: ${interceptedResponses[0]}`);
            await fetchAndUploadPdf(interceptedResponses[0], request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
            return;
        }

        // Poll for hrefs to populate — ManualsLib fills them via JS after POST response
        log.info(`[${modelNumber}] Polling for non-empty download hrefs (up to 15s)...`);
        let pdfLink = null;
        for (let poll = 0; poll < 15; poll++) {
            await page.waitForTimeout(1000);
            pdfLink = await page.evaluate(() => {
                const links = Array.from(document.querySelectorAll('a'));
                for (const a of links) {
                    const text = (a.textContent || '').toLowerCase();
                    const href = a.href || a.getAttribute('href') || '';
                    if ((text.includes('download pdf') || text.includes('view in browser') || text.includes('view pdf')) && href && href.length > 10 && href.startsWith('http')) {
                        return href;
                    }
                    if (href.includes('data2.manualslib.com') || href.includes('data1.manualslib.com') || (href.includes('.pdf') && href.includes('manualslib'))) {
                        return href;
                    }
                }
                return null;
            });
            if (pdfLink) {
                log.info(`[${modelNumber}] ✓ href populated after ${poll + 1}s: ${pdfLink.substring(0, 80)}`);
                break;
            }
        }

        if (pdfLink) {
            await fetchAndUploadPdf(pdfLink, request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
            return;
        }

        // Legacy selector check
        const legacyLink = await page.$(
            'a[href*="data2.manualslib.com"], a[href*="data1.manualslib.com"], a[href*="cpdf"]'
        );

        if (legacyLink) {
            const href = await legacyLink.getAttribute('href');
            if (href && href.length > 10) {
                const fullUrl = href.startsWith('http') ? href : `https://www.manualslib.com${href}`;
                log.info(`[${modelNumber}] ✓ Found legacy PDF link: ${fullUrl.substring(0, 80)}`);
                await fetchAndUploadPdf(fullUrl, request.url, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl);
                return;
            }
        }

        // Log all links on the page for debugging
        const allLinks = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('a')).map(a => ({
                text: (a.textContent || '').trim().substring(0, 50),
                href: (a.href || '').substring(0, 100),
            })).filter(l => l.text.toLowerCase().includes('download') || l.text.toLowerCase().includes('pdf') || l.text.toLowerCase().includes('view') || l.text.toLowerCase().includes('manual') || l.href.includes('.pdf'));
        });
        log.info(`[${modelNumber}] Relevant links on page: ${JSON.stringify(allLinks).substring(0, 500)}`);

        // Fallback
        log.info(`[${modelNumber}] No PDF link found — saving ManualsLib URL`);
        await saveSource(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'LINK_ONLY' });

    } catch (err) {
        if (err.message.includes('Retrying with fresh session')) {
            throw err; // Let Crawlee retry
        }
        log.warning(`[${modelNumber}] Error: ${err.message}`);
        await saveSource(supabaseId, manualPageUrl || request.url);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: request.url, verification_status: 'ERROR' });
    }
});

// ── Helpers ─────────────────────────────────────────────────────────────────

async function fetchAndUploadPdf(pdfUrl, referer, supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl) {
    const pdfResp = await fetch(pdfUrl, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'Referer': referer },
        redirect: 'follow', signal: AbortSignal.timeout(60000),
    });

    if (!pdfResp.ok) {
        log.warning(`[${modelNumber}] PDF fetch failed: HTTP ${pdfResp.status}`);
        await saveSource(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'FETCH_FAILED' });
        return;
    }

    const pdfBuffer = Buffer.from(await pdfResp.arrayBuffer());

    if (pdfBuffer.length < 1000 || pdfBuffer[0] !== 0x25 || pdfBuffer[1] !== 0x50 || pdfBuffer[2] !== 0x44 || pdfBuffer[3] !== 0x46) {
        log.warning(`[${modelNumber}] Not a valid PDF (${pdfBuffer.length} bytes)`);
        await saveSource(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'NOT_PDF' });
        return;
    }

    // Verify model in PDF text
    let verificationStatus = 'NEEDS_REVIEW';
    const text = extractPdfText(pdfBuffer);
    const exactUpper = originalModel.toUpperCase().replace(/[^A-Z0-9]/g, '');
    const baseUpper = stripColorCode(originalModel).toUpperCase().replace(/[^A-Z0-9]/g, '');
    const textClean = text.replace(/[^A-Z0-9]/g, '');
    if (textClean.includes(exactUpper) || textClean.includes(baseUpper)) {
        verificationStatus = 'VERIFIED';
        log.info(`[${modelNumber}] ✓ VERIFIED — model found in PDF`);
    }

    // Upload
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
    }

    log.info(`✓ ${brand} ${modelNumber} — ${verificationStatus} (${Math.round(pdfBuffer.length / 1024)} KB)`);
    results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: verificationStatus });
}

async function saveSource(supabaseId, url) {
    if (supabaseId === 'test') return; // Skip for hardcoded test
    await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
        method: 'PATCH',
        headers: { 'apikey': supabaseServiceKey, 'Authorization': `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
        body: JSON.stringify({ source_url: url, last_verified_at: new Date().toISOString() }),
    });
}

// ── Crawler ─────────────────────────────────────────────────────────────────

if (crawlRequests.length > 0) {
    const crawler = new PlaywrightCrawler({
        requestHandler: router,
        maxConcurrency: 1,
        navigationTimeoutSecs: 30,
        requestHandlerTimeoutSecs: 180,
        maxRequestRetries: 3,
        headless: true,
        useSessionPool: true,
        sessionPoolOptions: { maxPoolSize: 10 },
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

// ── Output ──────────────────────────────────────────────────────────────────

const downloaded = results.filter(r => r.verification_status === 'VERIFIED' || r.verification_status === 'NEEDS_REVIEW');
const notFound = results.filter(r => r.verification_status === 'NOT_FOUND');

await Actor.pushData({
    totalProcessed: models.length,
    pdfsDownloaded: downloaded.length,
    verified: results.filter(r => r.verification_status === 'VERIFIED').length,
    needsReview: results.filter(r => r.verification_status === 'NEEDS_REVIEW').length,
    linkOnly: results.filter(r => r.verification_status === 'LINK_ONLY').length,
    notFound: notFound.length,
    timestamp: new Date().toISOString(),
    results,
});

log.info(`Done! ${downloaded.length} PDFs (${results.filter(r => r.verification_status === 'VERIFIED').length} verified), ${results.filter(r => r.verification_status === 'LINK_ONLY').length} links, ${notFound.length} not found`);
await Actor.exit();
