-- Phase X feedback: targeted add / repair of verified Fairfield County
-- CT trash haulers + cleanup of one fabricated row.
--
-- Sourcing methodology for this batch:
--   1. User flagged "Redding Sanitation" as a known-real, biggest-in-area
--      trash hauler that didn't surface in find-a-pro.
--   2. Discovery: the slug `redding-sanitation` already existed in the
--      catalog (created 2026-04-11) but as an empty placeholder row —
--      name only, no phone, no website, no regions. Won't ever surface
--      in regional search. This UPSERT populates the missing fields.
--   3. Verified data via multiple independent sources: company's own
--      website (reddingsanitation.com), Yelp, BuzzFile listing, SAFER
--      FMCSA registration (USDOT 2528451), Town of Redding transfer
--      station page. 60+ year-old company at 701 Redding Rd.
--
-- Country Waste Services added in the same pass — same area (Ridgefield,
-- Redding, Wilton, Danbury, Weston, New Canaan, Brookfield), verified
-- via their own published service-area page. Two haulers in the catalog
-- gives residents an actual choice in find-a-pro.
--
-- Deleting `sd1-ne` ("Sanitation District 1") because the website
-- sd1.org resolves to Sanitation District No. 1 of Northern Kentucky —
-- a sewer/wastewater utility serving 3 KY counties near Cincinnati.
-- The row was tagged with 40+ Fairfield County CT towns including
-- Bethel, Redding, Wilton, Stamford, etc., which is fabricated regional
-- coverage that would surface a non-existent vendor to homeowners.
-- Zero `utility_accounts` link to this provider_id (verified pre-delete).
--
-- NEW SEED ROWS ONLY when independently corroborated. Do not extend
-- this pattern to "fill out" the catalog without verification — fake
-- look-alikes (like sd1-ne) erode trust far more than missing entries.

-- Redding Sanitation: UPSERT so an existing empty placeholder row gets
-- repaired with verified data, AND a fresh install gets a fully-populated
-- row. Either way the row ends up correct.
INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions)
VALUES (
    'Redding Sanitation',
    'redding-sanitation',
    'trash',
    'https://reddingsanitation.com',
    '(203) 938-3391',
    -- Verified: located at 701 Redding Rd, Redding CT 06896. Service
    -- area not published on their site; conservative regions list
    -- here uses Redding + immediately neighboring towns where private
    -- haulers in this region typically cover. Adjust if user-reported
    -- coverage proves otherwise.
    ARRAY['CT', 'Fairfield', 'Redding', 'Georgetown', 'Bethel', 'Easton', 'Weston', 'Wilton', 'Ridgefield', 'Newtown']
)
ON CONFLICT (slug) DO UPDATE SET
    website = EXCLUDED.website,
    phone = EXCLUDED.phone,
    regions = EXCLUDED.regions,
    provider_type = EXCLUDED.provider_type
WHERE
    -- Only overwrite when the existing row is empty/placeholder. Don't
    -- clobber a row that's been edited since seeding (e.g. user-corrected
    -- phone/website data).
    (utility_providers.phone IS NULL OR utility_providers.phone = '')
    AND (utility_providers.website IS NULL OR utility_providers.website = '')
    AND (utility_providers.regions IS NULL OR cardinality(utility_providers.regions) = 0);

INSERT INTO utility_providers (name, slug, provider_type, website, phone, regions)
VALUES (
    'Country Waste Services',
    'country-waste-services',
    'trash',
    'https://countrywasteservice.com',
    '(203) 792-2525',
    -- Verified service area from company's published page.
    ARRAY['CT', 'Fairfield', 'Ridgefield', 'Redding', 'Wilton', 'Danbury', 'Weston', 'New Canaan', 'Brookfield']
)
ON CONFLICT (slug) DO UPDATE SET
    website = EXCLUDED.website,
    phone = EXCLUDED.phone,
    regions = EXCLUDED.regions,
    provider_type = EXCLUDED.provider_type
WHERE
    (utility_providers.phone IS NULL OR utility_providers.phone = '')
    AND (utility_providers.website IS NULL OR utility_providers.website = '')
    AND (utility_providers.regions IS NULL OR cardinality(utility_providers.regions) = 0);

DELETE FROM utility_providers WHERE slug = 'sd1-ne';
