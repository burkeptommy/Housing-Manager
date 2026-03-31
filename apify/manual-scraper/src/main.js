/**
 * Haven Equipment Manual Scraper v9 — Production
 *
 * Pipeline:
 * 1. Fetch uncached models from Supabase equipment_catalog
 * 2. Google Search (site:manualslib.com) to find manual pages
 * 3. URL rewrite /manual/ -> /download/ to reach CAPTCHA gate
 * 4. 2Captcha reCAPTCHA v2 solve + single clean token injection
 * 5. CDN URL extraction via network interception + DOM polling
 * 6. PDF fetch (with session cookies), validation, model verification
 * 7. Upload to Supabase storage + multi-model mapping
 */

import { Actor, log } from 'apify';
import { PlaywrightCrawler, createPlaywrightRouter } from '@crawlee/playwright';
import { Solver } from '2captcha-ts';
import { setTimeout as sleep } from 'node:timers/promises';
import { chromium } from 'playwright-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';

// Apply stealth plugin — hides headless browser fingerprints
chromium.use(StealthPlugin());

/** Random delay between min and max ms to avoid robotic timing */
function humanDelay(minMs = 1000, maxMs = 3000) {
    return sleep(Math.floor(Math.random() * (maxMs - minMs)) + minMs);
}

// ── Helper Functions ───────────────────────────────────────────────────────

function extractPdfText(buffer, maxBytes = 500_000) {
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

function isValidPdf(buffer) {
    return buffer.length >= 1000 && buffer[0] === 0x25 && buffer[1] === 0x50 && buffer[2] === 0x44 && buffer[3] === 0x46;
}

function verifyModelInPdf(pdfBuffer, modelNumber) {
    const text = extractPdfText(pdfBuffer);
    const textClean = text.replace(/[^A-Z0-9]/g, '');
    const exactUpper = modelNumber.toUpperCase().replace(/[^A-Z0-9]/g, '');
    const baseUpper = stripColorCode(modelNumber).toUpperCase().replace(/[^A-Z0-9]/g, '');
    return textClean.includes(exactUpper) || textClean.includes(baseUpper);
}

async function extractSitekey(page) {
    const iframe = await page.$('iframe[src*="recaptcha/api2/anchor"]');
    if (!iframe) return null;
    const src = await iframe.getAttribute('src');
    const match = src?.match(/k=([^&]+)/);
    return match?.[1] || null;
}

async function solveCaptchaAndInject(page, pageUrl, solver) {
    const sitekey = await extractSitekey(page);
    if (!sitekey) return { success: false, reason: 'no_recaptcha' };

    log.info(`Solving reCAPTCHA (sitekey: ${sitekey.substring(0, 12)}...)...`);
    const solution = await solver.recaptcha({
        pageurl: pageUrl,
        googlekey: sitekey,
        pollingInterval: 5000,
    });
    const token = solution.data;
    log.info(`2Captcha solved. Token: ${token.substring(0, 30)}...`);

    // Set the textarea AND call the callback.
    // The callback sets up the page state for the download.
    // ManualsLib uses "captcha" as the POST field name (not g-recaptcha-response).
    const result = await page.evaluate((tok) => {
        const info = [];

        // Set ALL recaptcha response textareas
        document.querySelectorAll(
            'textarea[name="g-recaptcha-response"], #g-recaptcha-response'
        ).forEach(el => {
            el.style.display = 'block';
            el.value = tok;
            el.innerHTML = tok;
            info.push('textarea_set');
        });

        // Override grecaptcha.getResponse to return our token
        try {
            if (typeof grecaptcha !== 'undefined') {
                grecaptcha.getResponse = () => tok;
                info.push('getResponse_overridden');
            }
        } catch (e) {}

        // Call the callback — this makes an AJAX POST to /download with captcha=TOKEN
        // which is the ACTUAL download flow (not a form submission)
        const rcDiv = document.querySelector('.g-recaptcha[data-callback], [data-callback]');
        if (rcDiv) {
            const cbName = rcDiv.getAttribute('data-callback');
            if (cbName && typeof window[cbName] === 'function') {
                try { window[cbName](tok); info.push(`callback:${cbName}`); }
                catch (e) { info.push(`callback-err:${e.message}`); }
            }
        }
        if (!info.some(i => i.startsWith('callback:'))) {
            // Try known callback names
            for (const name of ['recaptchaCallback', 'onRecaptchaSuccess', 'onSubmit']) {
                if (typeof window[name] === 'function') {
                    try { window[name](tok); info.push(`callback:${name}`); break; }
                    catch (e) {}
                }
            }
        }

        return { info, called: true };
    }, token);

    log.info(`Injection result: ${result.info.join(', ')}`);
    return { success: true, details: result.info, token };
}

async function extractCdnUrl(page, interceptState, timeoutMs = 25_000) {
    const CDN_RE = /https?:\/\/data[12]\.manualslib\.com[^\s"'<>]+/i;
    const PDF_RE = /https?:\/\/[^\s"'<>]*\.pdf[^\s"'<>]*/i;
    const start = Date.now();

    while (Date.now() - start < timeoutMs) {
        // Source 1: Network-intercepted PDF URLs
        if (interceptState.pdfUrls.length > 0) {
            return interceptState.pdfUrls[0];
        }

        // Source 2: Check ALL accumulated POST responses for PDF URLs
        for (const body of interceptState.postResponses) {
            // Try JSON parse — ManualsLib returns {"url":"...","customPdfPath":"..."}
            try {
                const json = JSON.parse(body);
                if (json.error && json.error !== '') continue; // error response, skip
                const pdfPath = json.customPdfPath || json.url;
                if (pdfPath) {
                    const fullUrl = pdfPath.startsWith('//') ? `https:${pdfPath}` : pdfPath;
                    return fullUrl;
                }
            } catch { /* not JSON, try regex */ }

            const cdnMatch = body.match(CDN_RE);
            if (cdnMatch) return cdnMatch[0];
            const pdfMatch = body.match(PDF_RE);
            if (pdfMatch) return pdfMatch[0];
        }

        // Source 3: DOM selectors for populated hrefs
        const domUrl = await page.evaluate(() => {
            const selectors = [
                'a.download-url[href]', 'a.view-url[href]',
                '.download-url a[href]', '.view-url a[href]',
                'a[href*="data1.manualslib.com"]', 'a[href*="data2.manualslib.com"]',
            ];
            for (const sel of selectors) {
                const el = document.querySelector(sel);
                const href = el?.href || el?.getAttribute('href') || '';
                if (href.length > 10 && href.startsWith('http')) return href;
            }
            // Check any link with .pdf in href
            const allLinks = document.querySelectorAll('a[href*=".pdf"]');
            for (const a of allLinks) {
                const href = a.href || a.getAttribute('href') || '';
                if (href.includes('manualslib') && href.length > 10) return href;
            }
            return null;
        }).catch(() => null);

        if (domUrl) return domUrl;

        // Source 4: Full page HTML regex scan (expensive, do less frequently)
        if ((Date.now() - start) % 2500 < 500) {
            const html = await page.content().catch(() => '');
            const htmlCdn = html.match(CDN_RE);
            if (htmlCdn) return htmlCdn[0];
        }

        await sleep(500);
    }

    return null;
}

// ── Actor Init ─────────────────────────────────────────────────────────────

await Actor.init();

Actor.on('aborting', async () => {
    log.warning('Actor aborting — cleaning up...');
    await sleep(1000);
    await Actor.exit();
});

const input = await Actor.getInput() ?? {};
const {
    supabaseUrl = '', supabaseServiceKey = '', twoCaptchaApiKey = '',
    batchSize = 50, manufacturerSlug = null, onlyMissing = true,
} = input;

if (!supabaseUrl || !supabaseServiceKey || !twoCaptchaApiKey) {
    log.error('Missing required input: supabaseUrl, supabaseServiceKey, or twoCaptchaApiKey');
    await Actor.exit({ exitCode: 1 });
}

const solver = new Solver(twoCaptchaApiKey);

// ── Supabase: Fetch models ────────────────────────────────────────────────

log.info('Fetching models from Supabase...');

let cachedIds = new Set();
if (onlyMissing) {
    const resp = await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?select=catalog_entry_id&file_size_bytes=gt.0&limit=10000`, {
        headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}` },
    });
    cachedIds = new Set((await resp.json()).map(m => m.catalog_entry_id));
}

let allModels = [];
let offset = 0;
while (true) {
    let url = `${supabaseUrl}/rest/v1/equipment_catalog?select=id,model_number,model_name,equipment_manufacturers!inner(name,slug),equipment_categories!inner(name)&limit=1000&offset=${offset}&order=id`;
    if (manufacturerSlug) url += `&equipment_manufacturers.slug=eq.${manufacturerSlug}`;
    const resp = await fetch(url, { headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}` } });
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
    await Actor.pushData({ totalProcessed: 0, pdfsDownloaded: 0, verified: 0, needsReview: 0, linkOnly: 0, notFound: 0, multiModelMapped: 0, results: [] });
    await Actor.exit();
}

// ── Google Search: Find ManualsLib pages ──────────────────────────────────

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

    if (i + SEARCH_BATCH < models.length) await sleep(2000);
}

log.info(`Found ManualsLib pages for ${modelToUrl.size}/${models.length} models`);

// ── Build crawl requests ───────────────────────────────────────────────────

const results = [];
let multiModelTotal = 0;
const crawlRequests = [];

for (const [catalogId, info] of modelToUrl) {
    const cleanUrl = info.url.split('?')[0].split('#')[0];
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
    if (!modelToUrl.has(model.id)) {
        results.push({ supabase_id: model.id, brand: model.equipment_manufacturers.name, original_model: model.model_number, pdf_url: null, verification_status: 'NOT_FOUND', multi_model_count: 0 });
    }
}

// ── Supabase helpers ───────────────────────────────────────────────────────

async function saveSourceUrl(supabaseId, url) {
    await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
        method: 'PATCH',
        headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
        body: JSON.stringify({ source_url: url, last_verified_at: new Date().toISOString() }),
    });
}

async function uploadPdfToSupabase(pdfBuffer, storagePath, supabaseId, manualPageUrl) {
    const uploadResp = await fetch(`${supabaseUrl}/storage/v1/object/equipment-manuals/${storagePath}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/pdf', 'x-upsert': 'true' },
        body: pdfBuffer,
    });
    if (uploadResp.ok) {
        await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${supabaseId}&manual_type=eq.owners_manual`, {
            method: 'PATCH',
            headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
            body: JSON.stringify({ source_url: manualPageUrl, file_path: storagePath, file_size_bytes: pdfBuffer.length, last_verified_at: new Date().toISOString() }),
        });
    }
    return uploadResp.ok;
}

async function detectMultiModelMatches(pdfBuffer, primaryCatalogId, brandSlug, storagePath, manualPageUrl) {
    const text = extractPdfText(pdfBuffer);
    const textClean = text.replace(/[^A-Z0-9]/g, '');

    // Fetch all models for this brand
    const resp = await fetch(
        `${supabaseUrl}/rest/v1/equipment_catalog?select=id,model_number&equipment_manufacturers!inner(slug)&equipment_manufacturers.slug=eq.${brandSlug}&limit=5000`,
        { headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}` } },
    );
    if (!resp.ok) return [];
    const brandModels = await resp.json();

    const matched = [];
    for (const model of brandModels) {
        if (model.id === primaryCatalogId) continue;
        const modelUpper = model.model_number.toUpperCase().replace(/[^A-Z0-9]/g, '');
        if (modelUpper.length < 5) continue; // skip short model numbers to avoid false matches
        // Must contain both letters and numbers to be specific enough
        if (!/[A-Z]/.test(modelUpper) || !/[0-9]/.test(modelUpper)) continue;
        const baseUpper = stripColorCode(model.model_number).toUpperCase().replace(/[^A-Z0-9]/g, '');
        if (textClean.includes(modelUpper) || (baseUpper.length >= 5 && textClean.includes(baseUpper))) {
            matched.push(model);
        }
    }

    // UPSERT equipment_manuals rows for each matched model
    for (const model of matched) {
        const checkResp = await fetch(
            `${supabaseUrl}/rest/v1/equipment_manuals?catalog_entry_id=eq.${model.id}&manual_type=eq.owners_manual&select=id`,
            { headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}` } },
        );
        const existing = await checkResp.json();
        const payload = {
            source_url: manualPageUrl,
            file_path: storagePath,
            file_size_bytes: pdfBuffer.length,
            last_verified_at: new Date().toISOString(),
        };

        if (existing.length > 0) {
            await fetch(`${supabaseUrl}/rest/v1/equipment_manuals?id=eq.${existing[0].id}`, {
                method: 'PATCH',
                headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
                body: JSON.stringify(payload),
            });
        } else {
            await fetch(`${supabaseUrl}/rest/v1/equipment_manuals`, {
                method: 'POST',
                headers: { apikey: supabaseServiceKey, Authorization: `Bearer ${supabaseServiceKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
                body: JSON.stringify({
                    catalog_entry_id: model.id,
                    manual_type: 'owners_manual',
                    title: `${model.model_number} Owner's Manual`,
                    ...payload,
                }),
            });
        }
    }

    if (matched.length > 0) {
        log.info(`Multi-model: mapped ${matched.length} additional models: ${matched.map(m => m.model_number).join(', ')}`);
    }
    return matched;
}

async function fetchAndUploadPdf(pdfUrl, pageContext, metadata) {
    const { supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl } = metadata;

    // Try with session cookies first (CDN may require them)
    let pdfBuffer;
    const cookies = await pageContext.cookies().catch(() => []);
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');
    const baseHeaders = { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' };

    for (const attempt of [1, 2]) {
        try {
            const headers = attempt === 1
                ? { ...baseHeaders, Referer: manualPageUrl, Cookie: cookieHeader }
                : { ...baseHeaders, Referer: manualPageUrl };
            const resp = await fetch(pdfUrl, { headers, redirect: 'follow', signal: AbortSignal.timeout(60_000) });
            if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
            pdfBuffer = Buffer.from(await resp.arrayBuffer());
            break;
        } catch (err) {
            if (attempt === 2) {
                log.warning(`[${modelNumber}] PDF fetch failed after 2 attempts: ${err.message}`);
                await saveSourceUrl(supabaseId, manualPageUrl);
                results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'FETCH_FAILED', multi_model_count: 0 });
                return;
            }
            log.info(`[${modelNumber}] PDF fetch attempt ${attempt} failed (${err.message}), retrying without cookies...`);
        }
    }

    if (!isValidPdf(pdfBuffer)) {
        log.warning(`[${modelNumber}] Not a valid PDF (${pdfBuffer.length} bytes)`);
        await saveSourceUrl(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'NOT_PDF', multi_model_count: 0 });
        return;
    }

    const verified = verifyModelInPdf(pdfBuffer, originalModel);
    const status = verified ? 'VERIFIED' : 'NEEDS_REVIEW';

    // Only upload + map PDFs that are VERIFIED (model number found in PDF text).
    // NEEDS_REVIEW means Google may have matched the wrong manual — save source URL only.
    if (!verified) {
        log.warning(`[${modelNumber}] Model not found in PDF text — saving source URL only (NEEDS_REVIEW)`);
        await saveSourceUrl(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'NEEDS_REVIEW', multi_model_count: 0 });
        return;
    }

    const storagePath = `${brandSlug}/${safeModel}/owners_manual.pdf`;
    const uploaded = await uploadPdfToSupabase(pdfBuffer, storagePath, supabaseId, manualPageUrl);

    if (!uploaded) {
        log.warning(`[${modelNumber}] Supabase upload failed`);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'UPLOAD_FAILED', multi_model_count: 0 });
        return;
    }

    // Multi-model detection — only for VERIFIED PDFs
    const extraModels = await detectMultiModelMatches(pdfBuffer, supabaseId, brandSlug, storagePath, manualPageUrl);
    multiModelTotal += extraModels.length;

    log.info(`${brand} ${modelNumber} -- VERIFIED (${Math.round(pdfBuffer.length / 1024)} KB, +${extraModels.length} multi-model)`);
    results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: pdfUrl, verification_status: 'VERIFIED', multi_model_count: extraModels.length });
}

// ── Router ─────────────────────────────────────────────────────────────────

const router = createPlaywrightRouter();

router.addHandler('MANUALSLIB', async ({ page, request, session }) => {
    const { supabaseId, modelNumber, brand, brandSlug, originalModel, manualPageUrl } = request.userData;
    const safeModel = modelNumber.replace(/[^a-zA-Z0-9_-]/g, '_');
    const retryCount = request.retryCount || 0;
    const metadata = { supabaseId, modelNumber, brand, brandSlug, originalModel, safeModel, manualPageUrl };

    log.info(`[${brand} ${modelNumber}] Attempt ${retryCount + 1} -- ${request.url}`);

    // 1. Wait for page load + human-like settle time
    await page.waitForLoadState('domcontentloaded', { timeout: 20_000 }).catch(() => {});
    await humanDelay(2000, 4000);

    // 2. Network interception — BEFORE any CAPTCHA work
    const interceptState = { pdfUrls: [], postResponses: [] };

    // Log ALL requests (not just responses) to see what's being sent
    page.on('request', (req) => {
        if (req.method() === 'POST' && req.url().includes('manualslib.com')) {
            const postData = req.postData() || '';
            log.info(`[${modelNumber}] POST request -> ${req.url().substring(0, 80)} | body: ${postData.substring(0, 200)}`);
        }
    });

    page.on('response', async (res) => {
        try {
            const url = res.url();
            const ct = res.headers()['content-type'] || '';

            // Capture direct PDF responses
            if (ct.includes('application/pdf') || url.endsWith('.pdf') || url.includes('cpdf')) {
                interceptState.pdfUrls.push(url);
                log.info(`[${modelNumber}] Intercepted PDF: ${url.substring(0, 80)}`);
            }

            // Capture ALL POST responses from manualslib.com
            if (url.includes('manualslib.com') && res.request().method() === 'POST') {
                const body = await res.text();
                interceptState.postResponses.push(body);
                log.info(`[${modelNumber}] POST response #${interceptState.postResponses.length} from ${url.substring(0, 80)} (${res.status()}, ${body.length} chars): ${body.substring(0, 300)}`);
            }
        } catch (e) { /* response already disposed, ignore */ }
    });

    try {
        // 3. Debug screenshot
        const ss = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-page-${safeModel}-${retryCount}`, ss, { contentType: 'image/png' });

        // 4. Check for "Something went wrong"
        const bodyText = await page.textContent('body').catch(() => '');
        if (bodyText?.includes('Something went wrong')) {
            log.warning(`[${modelNumber}] "Something went wrong" — retiring session`);
            session?.retire();
            throw new Error('Something went wrong. Retrying with fresh session.');
        }

        // 5. Detect CAPTCHA type
        const hasRecaptcha = await page.$('iframe[src*="recaptcha/api2/anchor"]');
        const hasHcaptcha = await page.$('iframe[src*="hcaptcha.com"]');

        if (hasHcaptcha) {
            log.warning(`[${modelNumber}] hCaptcha detected — not supported, saving source URL`);
            await saveSourceUrl(supabaseId, manualPageUrl);
            results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'HCAPTCHA_UNSUPPORTED', multi_model_count: 0 });
            return;
        }

        let captchaToken = null;
        if (hasRecaptcha) {
            const captchaResult = await solveCaptchaAndInject(page, request.url, solver);
            captchaToken = captchaResult.token;
            if (!captchaResult.success) {
                log.warning(`[${modelNumber}] CAPTCHA injection failed: ${captchaResult.reason || captchaResult.details?.join(', ')}`);
            }
        } else {
            log.info(`[${modelNumber}] No CAPTCHA found — trying direct access`);
        }

        // 6. Submit the CAPTCHA token to get download links
        // Human-like pause after CAPTCHA solve before taking action
        await humanDelay(1500, 3000);

        if (hasRecaptcha && captchaToken) {
            // After callback, click the "Get manual" button — it's an <a> tag that triggers
            // a jQuery AJAX POST to /download with the captcha token.
            // The callback just enables the button; the click makes the actual POST.
            await humanDelay(500, 1500);

            // Log all clickable elements near the CAPTCHA for debugging
            const pageElements = await page.evaluate(() => {
                const els = document.querySelectorAll('a.btn, a[class*="manual"], a[class*="download"], button[class*="manual"], .get-manual, #get-manual');
                return Array.from(els).map(el => ({ tag: el.tagName, class: el.className, text: (el.textContent || '').trim().substring(0, 50), href: el.href?.substring(0, 80) || '', id: el.id }));
            }).catch(() => []);
            log.info(`[${modelNumber}] Clickable elements: ${JSON.stringify(pageElements).substring(0, 500)}`);

            // Click the "Get manual" button: <button id="get-manual-button" class="button-get-manual btn btn-lg btn-success">
            const getManualBtn = await page.$('#get-manual-button, .button-get-manual, button:has-text("Get manual"), a:has-text("Get manual")');
            if (getManualBtn) {
                log.info(`[${modelNumber}] Clicking "Get manual" button...`);
                await humanDelay(300, 800);
                await getManualBtn.click().catch(() => {});
                await humanDelay(5000, 8000);
            } else {
                log.warning(`[${modelNumber}] No "Get manual" element found`);
            }

            // Check for server errors in captured responses
            const errorResponse = interceptState.postResponses.find(body => {
                try { const j = JSON.parse(body); return j.error && j.error.includes('Something went wrong'); } catch { return false; }
            });
            if (errorResponse) {
                log.warning(`[${modelNumber}] Server returned error — retiring session`);
                session?.retire();
                throw new Error('Server error. Retrying.');
            }
        } else {
            // No CAPTCHA — try clicking download buttons
            const btn = await page.$('a:has-text("Get manual"), button:has-text("Get manual"), a:has-text("Download"), button:has-text("Download")');
            if (btn) {
                log.info(`[${modelNumber}] Clicking download button...`);
                await humanDelay(500, 1500);
                await btn.click().catch(() => {});
                await humanDelay(2000, 4000);
            }
        }

        // 7. Extract CDN URL
        log.info(`[${modelNumber}] Extracting CDN URL...`);
        const cdnUrl = await extractCdnUrl(page, interceptState, 25_000);

        // 8. Debug screenshot post-extraction
        const ss2 = await page.screenshot({ fullPage: true });
        await Actor.setValue(`debug-post-${safeModel}-${retryCount}`, ss2, { contentType: 'image/png' });

        if (cdnUrl) {
            log.info(`[${modelNumber}] CDN URL found: ${cdnUrl.substring(0, 80)}`);
            await fetchAndUploadPdf(cdnUrl, page.context(), metadata);
            return;
        }

        // 9. No CDN URL — check for errors
        const bodyAfter = await page.textContent('body').catch(() => '');
        if (bodyAfter?.includes('Something went wrong')) {
            log.warning(`[${modelNumber}] "Something went wrong" after extraction — retrying`);
            session?.retire();
            throw new Error('Something went wrong post-extraction. Retrying.');
        }

        if (bodyAfter?.includes('rate limit') || bodyAfter?.includes('too many requests')) {
            log.warning(`[${modelNumber}] Rate limited — retrying`);
            session?.retire();
            throw new Error('Rate limited. Retrying with fresh session.');
        }

        // 10. Log page state for debugging
        if (interceptState.postResponses.length > 0) {
            log.info(`[${modelNumber}] ${interceptState.postResponses.length} POST responses captured, none had PDF URLs. Bodies: ${interceptState.postResponses.map(b => b.substring(0, 100)).join(' | ')}`);
        } else {
            log.info(`[${modelNumber}] No /download POST response was captured`);
        }
        const links = await page.evaluate(() => {
            return Array.from(document.querySelectorAll('a')).map(a => ({
                text: (a.textContent || '').trim().substring(0, 50),
                href: (a.href || '').substring(0, 100),
            })).filter(l => l.text.toLowerCase().includes('download') || l.text.toLowerCase().includes('pdf') || l.text.toLowerCase().includes('view') || l.href.includes('.pdf'));
        }).catch(() => []);
        log.info(`[${modelNumber}] Page links: ${JSON.stringify(links).substring(0, 500)}`);

        // 11. Fallback: save source URL
        log.info(`[${modelNumber}] No PDF link found — saving source URL`);
        await saveSourceUrl(supabaseId, manualPageUrl);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: manualPageUrl, verification_status: 'LINK_ONLY', multi_model_count: 0 });

    } catch (err) {
        if (err.message.includes('Retrying')) throw err; // Let Crawlee retry
        log.warning(`[${modelNumber}] Error: ${err.message}`);
        await saveSourceUrl(supabaseId, manualPageUrl || request.url);
        results.push({ supabase_id: supabaseId, brand, original_model: originalModel, pdf_url: request.url, verification_status: 'ERROR', multi_model_count: 0 });
    }
});

// ── Crawler ────────────────────────────────────────────────────────────────

if (crawlRequests.length > 0) {
    const crawler = new PlaywrightCrawler({
        requestHandler: router,
        maxConcurrency: 1,
        navigationTimeoutSecs: 30,
        requestHandlerTimeoutSecs: 180,
        maxRequestRetries: 3,
        headless: false, // Headful — Apify uses Xvfb, locally opens a browser window
        useSessionPool: true,
        sessionPoolOptions: { maxPoolSize: 10 },
        proxyConfiguration: Actor.isAtHome()
            ? await Actor.createProxyConfiguration({ groups: ['RESIDENTIAL'], useApifyProxy: true })
            : undefined,
        browserPoolOptions: { useFingerprints: true },
        launchContext: {
            // Use stealth-patched chromium from playwright-extra
            launcher: chromium,
            launchOptions: {
                headless: false,
                args: ['--disable-dev-shm-usage', '--no-sandbox', '--disable-blink-features=AutomationControlled'],
            },
        },
    });
    await crawler.run(crawlRequests);
}

// ── Output ─────────────────────────────────────────────────────────────────

const downloaded = results.filter(r => ['VERIFIED', 'NEEDS_REVIEW'].includes(r.verification_status));
const summary = {
    totalProcessed: models.length,
    pdfsDownloaded: downloaded.length,
    verified: results.filter(r => r.verification_status === 'VERIFIED').length,
    needsReview: results.filter(r => r.verification_status === 'NEEDS_REVIEW').length,
    linkOnly: results.filter(r => r.verification_status === 'LINK_ONLY').length,
    notFound: results.filter(r => r.verification_status === 'NOT_FOUND').length,
    multiModelMapped: multiModelTotal,
    timestamp: new Date().toISOString(),
    results,
};

await Actor.pushData(summary);
log.info(`Done! ${downloaded.length} PDFs (${summary.verified} verified), ${summary.linkOnly} links, ${summary.notFound} not found, ${multiModelTotal} multi-model mappings`);
await Actor.exit();
