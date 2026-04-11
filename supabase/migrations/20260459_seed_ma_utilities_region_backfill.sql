-- ============================================================================
-- Massachusetts Utility Providers -- Region Backfill
-- ============================================================================
-- Existing statewide providers (Eversource, National Grid, Spectrum, etc.)
-- have regions = ARRAY['MA'] but no county or town granularity. This means
-- they won't surface when the provider picker ranks by town/county match.
--
-- This migration appends county names and town names to the regions array
-- of every MA-tagged provider so they rank properly for users in Essex,
-- Middlesex, Norfolk, and Plymouth counties.
--
-- Each UPDATE is idempotent: the WHERE guard checks that the county name
-- is NOT already in the array, so re-running this migration is safe.
-- We use array_cat to append rather than replace.
--
-- Provider types covered: electric, natural_gas, internet_cable, oil,
-- propane, trash, water, security, solar, landscaping, pest_control.
-- ============================================================================

-- ============================================================================
-- ESSEX COUNTY (33 towns)
-- ============================================================================

UPDATE public.utility_providers SET regions = array_cat(regions, ARRAY[
    'Essex',
    'Amesbury','Andover','Beverly','Boxford','Danvers','Essex','Georgetown',
    'Gloucester','Groveland','Hamilton','Haverhill','Ipswich','Lawrence',
    'Lynn','Lynnfield','Manchester-by-the-Sea','Marblehead','Merrimac',
    'Methuen','Middleton','Nahant','Newbury','Newburyport','North Andover',
    'Peabody','Rockport','Rowley','Salem','Salisbury','Saugus','Swampscott',
    'Topsfield','Wenham','West Newbury'
])
WHERE 'MA' = ANY(regions)
AND NOT 'Essex' = ANY(regions)
AND provider_type IN (
    'electric','natural_gas','internet_cable','oil','propane',
    'trash','water','security','solar','landscaping','pest_control'
);

-- ============================================================================
-- MIDDLESEX COUNTY (54 towns)
-- ============================================================================

UPDATE public.utility_providers SET regions = array_cat(regions, ARRAY[
    'Middlesex',
    'Acton','Arlington','Ashby','Ashland','Ayer','Bedford','Belmont',
    'Billerica','Boxborough','Burlington','Cambridge','Carlisle','Chelmsford',
    'Concord','Dracut','Dunstable','Everett','Framingham','Groton',
    'Holliston','Hopkinton','Hudson','Lexington','Lincoln','Littleton',
    'Lowell','Malden','Marlborough','Maynard','Medford','Melrose',
    'Natick','Newton','North Reading','Pepperell','Reading','Sherborn',
    'Shirley','Somerville','Stoneham','Stow','Sudbury','Tewksbury',
    'Townsend','Tyngsborough','Wakefield','Waltham','Watertown','Wayland',
    'Westford','Weston','Wilmington','Winchester','Woburn'
])
WHERE 'MA' = ANY(regions)
AND NOT 'Middlesex' = ANY(regions)
AND provider_type IN (
    'electric','natural_gas','internet_cable','oil','propane',
    'trash','water','security','solar','landscaping','pest_control'
);

-- ============================================================================
-- NORFOLK COUNTY (27 towns)
-- ============================================================================

UPDATE public.utility_providers SET regions = array_cat(regions, ARRAY[
    'Norfolk',
    'Avon','Braintree','Brookline','Canton','Cohasset','Dedham','Dover',
    'Foxborough','Franklin','Holbrook','Medfield','Medway','Millis',
    'Milton','Needham','Norfolk','Norwood','Plainville','Quincy',
    'Randolph','Sharon','Stoughton','Walpole','Wellesley','Westwood',
    'Weymouth','Wrentham'
])
WHERE 'MA' = ANY(regions)
AND NOT 'Norfolk' = ANY(regions)
AND provider_type IN (
    'electric','natural_gas','internet_cable','oil','propane',
    'trash','water','security','solar','landscaping','pest_control'
);

-- ============================================================================
-- PLYMOUTH COUNTY (27 towns)
-- ============================================================================

UPDATE public.utility_providers SET regions = array_cat(regions, ARRAY[
    'Plymouth',
    'Abington','Bridgewater','Brockton','Carver','Duxbury',
    'East Bridgewater','Halifax','Hanover','Hanson','Hingham','Hull',
    'Kingston','Lakeville','Marion','Marshfield','Mattapoisett',
    'Middleborough','Norwell','Pembroke','Plymouth','Plympton',
    'Rochester','Rockland','Scituate','Wareham','West Bridgewater',
    'Whitman'
])
WHERE 'MA' = ANY(regions)
AND NOT 'Plymouth' = ANY(regions)
AND provider_type IN (
    'electric','natural_gas','internet_cable','oil','propane',
    'trash','water','security','solar','landscaping','pest_control'
);
