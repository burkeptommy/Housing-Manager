-- ============================================================================
-- Norfolk County + Plymouth County, MA -- Local Utility Providers
-- ============================================================================
-- Norfolk County: ~27 towns south/southwest of Boston (Quincy to Franklin).
-- Plymouth County: ~27 towns on the South Shore (Brockton to Plymouth).
-- Five sections:
--   1. Norfolk County municipal water departments
--   2. Norfolk County municipal trash / DPW
--   3. Plymouth County municipal water departments
--   4. Plymouth County municipal trash / DPW
--   5. South Shore oil and propane dealers (serving both counties)
--
-- All inserts use ON CONFLICT (slug) DO NOTHING so re-running is safe.
-- ============================================================================

-- ============================================================================
-- SECTION 1: MUNICIPAL WATER DEPARTMENTS -- Norfolk County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Braintree Water Department', 'braintree-water-dept', 'water', 'https://braintreema.gov/263/Water-Sewer', '781-794-8240', ARRAY['Braintree','MA','Norfolk']),
    ('Brookline Water Department', 'brookline-water-dept', 'water', 'https://brooklinema.gov/170/Water-Sewer-Division', '617-730-2160', ARRAY['Brookline','MA','Norfolk']),
    ('Canton Water Department', 'canton-water-dept', 'water', 'https://town.canton.ma.us/234/Water-Department', '781-575-6660', ARRAY['Canton','MA','Norfolk']),
    ('Dedham Water Department', 'dedham-water-dept', 'water', 'https://dedham-ma.gov/departments/water-sewer', '781-751-9180', ARRAY['Dedham','MA','Norfolk']),
    ('Franklin Water Department', 'franklin-water-dept', 'water', 'https://franklinma.gov/water-sewer-department', '508-520-4901', ARRAY['Franklin','MA','Norfolk']),
    ('Milton Water Department', 'milton-water-dept', 'water', 'https://townofmilton.org/water-department', '617-898-4848', ARRAY['Milton','MA','Norfolk']),
    ('Needham Water Department', 'needham-water-dept', 'water', 'https://needhamma.gov/268/Water-Sewer', '781-455-7550', ARRAY['Needham','MA','Norfolk']),
    ('Norwood Water Department', 'norwood-water-dept', 'water', 'https://norwoodma.gov/departments/water_department.php', '781-762-1413', ARRAY['Norwood','MA','Norfolk']),
    ('Quincy Water Department', 'quincy-water-dept', 'water', 'https://quincyma.gov/government/pw_commissioner/water.cfm', '617-376-1900', ARRAY['Quincy','MA','Norfolk']),
    ('Stoughton Water Department', 'stoughton-water-dept', 'water', 'https://stoughton-ma.gov/water-sewer', '781-344-2129', ARRAY['Stoughton','MA','Norfolk']),
    ('Wellesley Water Department', 'wellesley-water-dept', 'water', 'https://wellesleyma.gov/298/Water-Division', '781-235-7600', ARRAY['Wellesley','MA','Norfolk']),
    ('Weymouth Water Department', 'weymouth-water-dept', 'water', 'https://weymouth.ma.us/water-sewer-department', '781-340-5015', ARRAY['Weymouth','MA','Norfolk']),
    ('Walpole Water Department', 'walpole-water-dept', 'water', 'https://walpole-ma.gov/water-sewer-department', '508-660-7345', ARRAY['Walpole','MA','Norfolk']),
    ('Medfield Water Department', 'medfield-water-dept', 'water', 'https://town.medfield.net/283/Water-Sewer', '508-906-3028', ARRAY['Medfield','MA','Norfolk'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 2: MUNICIPAL TRASH / DPW -- Norfolk County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Braintree DPW - Trash & Recycling', 'braintree-dpw-trash', 'trash', 'https://braintreema.gov/260/Public-Works', '781-794-8240', ARRAY['Braintree','MA','Norfolk']),
    ('Brookline DPW - Trash', 'brookline-dpw-trash', 'trash', 'https://brooklinema.gov/168/Sanitation-Division', '617-730-2156', ARRAY['Brookline','MA','Norfolk']),
    ('Dedham DPW - Trash', 'dedham-dpw-trash', 'trash', 'https://dedham-ma.gov/departments/public-works', '781-751-9350', ARRAY['Dedham','MA','Norfolk']),
    ('Milton DPW - Solid Waste', 'milton-dpw-trash', 'trash', 'https://townofmilton.org/public-works', '617-898-4900', ARRAY['Milton','MA','Norfolk']),
    ('Needham DPW - Trash', 'needham-dpw-trash', 'trash', 'https://needhamma.gov/267/Public-Works', '781-455-7549', ARRAY['Needham','MA','Norfolk']),
    ('Norwood DPW - Trash & Recycling', 'norwood-dpw-trash', 'trash', 'https://norwoodma.gov/departments/public_works.php', '781-762-1413', ARRAY['Norwood','MA','Norfolk']),
    ('Quincy DPW - Trash & Recycling', 'quincy-dpw-trash', 'trash', 'https://quincyma.gov/government/pw_commissioner/trash.cfm', '617-376-1900', ARRAY['Quincy','MA','Norfolk']),
    ('Wellesley DPW - Trash', 'wellesley-dpw-trash', 'trash', 'https://wellesleyma.gov/296/Recycling-Disposal-Facility', '781-235-7600', ARRAY['Wellesley','MA','Norfolk']),
    ('Weymouth DPW - Trash', 'weymouth-dpw-trash', 'trash', 'https://weymouth.ma.us/public-works-department', '781-340-5000', ARRAY['Weymouth','MA','Norfolk']),
    ('Franklin DPW - Trash', 'franklin-dpw-trash', 'trash', 'https://franklinma.gov/public-works', '508-520-4909', ARRAY['Franklin','MA','Norfolk'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 3: MUNICIPAL WATER DEPARTMENTS -- Plymouth County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Brockton Water Department', 'brockton-water-dept', 'water', 'https://brockton.ma.us/government/departments/water-department', '508-580-7807', ARRAY['Brockton','MA','Plymouth']),
    ('Duxbury Water Department', 'duxbury-water-dept', 'water', 'https://duxbury-ma.gov/191/Water-Department', '781-934-1104', ARRAY['Duxbury','MA','Plymouth']),
    ('Halifax Water Department', 'halifax-water-dept', 'water', 'https://halifax-ma.org/water-department', '781-293-1736', ARRAY['Halifax','MA','Plymouth']),
    ('Hanover Water Department', 'hanover-water-dept', 'water', 'https://hanover-ma.gov/water-department', '781-826-3502', ARRAY['Hanover','MA','Plymouth']),
    ('Hingham Water Department', 'hingham-water-dept', 'water', 'https://hingham-ma.gov/305/Water-Department', '781-741-1430', ARRAY['Hingham','MA','Plymouth']),
    ('Kingston Water Department', 'kingston-water-dept', 'water', 'https://kingstonmass.org/water-department', '781-585-0504', ARRAY['Kingston','MA','Plymouth']),
    ('Marshfield Water Department', 'marshfield-water-dept', 'water', 'https://marshfield-ma.gov/water-department', '781-834-5575', ARRAY['Marshfield','MA','Plymouth']),
    ('Middleborough Water Department', 'middleborough-water-dept', 'water', 'https://middleborough.com/water-department', '508-946-2415', ARRAY['Middleborough','MA','Plymouth']),
    ('Pembroke Water Department', 'pembroke-water-dept', 'water', 'https://pembroke-ma.gov/water-department', '781-709-1413', ARRAY['Pembroke','MA','Plymouth']),
    ('Plymouth Water Department', 'plymouth-water-dept', 'water', 'https://plymouth-ma.gov/389/Water-Division', '508-747-1620', ARRAY['Plymouth','MA','Plymouth']),
    ('Rockland Water Department', 'rockland-water-dept', 'water', 'https://rockland-ma.gov/water-department', '781-878-0961', ARRAY['Rockland','MA','Plymouth']),
    ('Scituate Water Department', 'scituate-water-dept', 'water', 'https://scituatema.gov/water-department', '781-545-8735', ARRAY['Scituate','MA','Plymouth']),
    ('Whitman Water Department', 'whitman-water-dept', 'water', 'https://whitman-ma.gov/water-department', '781-447-7600', ARRAY['Whitman','MA','Plymouth'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 4: MUNICIPAL TRASH / DPW -- Plymouth County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Brockton DPW - Trash & Recycling', 'brockton-dpw-trash', 'trash', 'https://brockton.ma.us/government/departments/dpw', '508-580-7850', ARRAY['Brockton','MA','Plymouth']),
    ('Duxbury DPW - Solid Waste', 'duxbury-dpw-trash', 'trash', 'https://duxbury-ma.gov/193/Transfer-Station', '781-934-1104', ARRAY['Duxbury','MA','Plymouth']),
    ('Hingham DPW - Trash & Recycling', 'hingham-dpw-trash', 'trash', 'https://hingham-ma.gov/310/Trash-Recycling', '781-741-1430', ARRAY['Hingham','MA','Plymouth']),
    ('Kingston DPW - Trash', 'kingston-dpw-trash', 'trash', 'https://kingstonmass.org/recycling-center', '781-585-0509', ARRAY['Kingston','MA','Plymouth']),
    ('Marshfield DPW - Trash', 'marshfield-dpw-trash', 'trash', 'https://marshfield-ma.gov/public-works', '781-834-5575', ARRAY['Marshfield','MA','Plymouth']),
    ('Plymouth DPW - Solid Waste', 'plymouth-dpw-trash', 'trash', 'https://plymouth-ma.gov/390/Solid-Waste', '508-747-1620', ARRAY['Plymouth','MA','Plymouth']),
    ('Scituate DPW - Trash', 'scituate-dpw-trash', 'trash', 'https://scituatema.gov/public-works', '781-545-8735', ARRAY['Scituate','MA','Plymouth']),
    ('Hanover DPW - Trash & Recycling', 'hanover-dpw-trash', 'trash', 'https://hanover-ma.gov/public-works', '781-826-3502', ARRAY['Hanover','MA','Plymouth']),
    ('Pembroke DPW - Trash', 'pembroke-dpw-trash', 'trash', 'https://pembroke-ma.gov/public-works', '781-709-1413', ARRAY['Pembroke','MA','Plymouth'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 5: SOUTH SHORE OIL & PROPANE -- Norfolk + Plymouth Counties
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    -- Heating Oil
    ('South Shore Oil', 'south-shore-oil', 'oil', 'https://southshoreoil.com', '781-659-4540', ARRAY['MA','Norfolk','Plymouth','Norwell','Hingham','Scituate','Hanover']),
    ('Hingham Fuel Company', 'hingham-fuel-co', 'oil', 'https://hinghamfuel.com', '781-749-0540', ARRAY['MA','Norfolk','Plymouth','Hingham','Hull','Cohasset','Weymouth']),
    ('Duxbury Oil & Propane', 'duxbury-oil-propane', 'oil', 'https://duxburyoil.com', '781-934-2211', ARRAY['MA','Plymouth','Duxbury','Kingston','Pembroke','Marshfield']),
    ('Plymouth Fuel Company', 'plymouth-fuel-co', 'oil', 'https://plymouthfuel.com', '508-746-2100', ARRAY['MA','Plymouth','Plymouth','Carver','Middleborough','Kingston']),
    ('Braintree Oil Company', 'braintree-oil-co', 'oil', 'https://braintreeoil.com', '781-843-1560', ARRAY['MA','Norfolk','Braintree','Weymouth','Quincy','Holbrook']),
    ('Quincy Fuel Service', 'quincy-fuel-service', 'oil', 'https://quincyfuel.com', '617-472-5500', ARRAY['MA','Norfolk','Quincy','Braintree','Milton','Randolph']),
    ('Marshfield Oil Company', 'marshfield-oil-co', 'oil', 'https://marshfieldoil.com', '781-837-0950', ARRAY['MA','Plymouth','Marshfield','Scituate','Duxbury','Pembroke']),
    ('Canton Fuel', 'canton-fuel', 'oil', 'https://cantonfuel.com', '781-828-1330', ARRAY['MA','Norfolk','Canton','Stoughton','Sharon','Norwood']),
    ('Norwell Oil Service', 'norwell-oil-service', 'oil', 'https://norwelloil.com', '781-659-2212', ARRAY['MA','Plymouth','Norwell','Hanover','Rockland','Hanson']),
    ('Franklin Fuel', 'franklin-fuel', 'oil', 'https://franklinfuel.com', '508-528-1422', ARRAY['MA','Norfolk','Franklin','Medway','Millis','Wrentham']),
    ('Walpole Oil Service', 'walpole-oil-service', 'oil', 'https://walpoleoil.com', '508-668-0200', ARRAY['MA','Norfolk','Walpole','Norwood','Sharon','Foxborough']),
    ('Abington Fuel', 'abington-fuel', 'oil', 'https://abingtonfuel.com', '781-878-1033', ARRAY['MA','Plymouth','Abington','Whitman','Rockland','Hanson']),

    -- Propane
    ('Blue Hills Propane', 'blue-hills-propane', 'propane', 'https://bluehillspropane.com', '781-828-7070', ARRAY['MA','Norfolk','Canton','Milton','Braintree','Randolph','Stoughton']),
    ('South Shore Propane', 'south-shore-propane', 'propane', 'https://southshorepropane.com', '781-826-9880', ARRAY['MA','Norfolk','Plymouth','Hanover','Norwell','Pembroke','Marshfield']),
    ('Quincy Propane Service', 'quincy-propane-service', 'propane', 'https://quincypropane.com', '617-328-3300', ARRAY['MA','Norfolk','Quincy','Weymouth','Braintree','Milton']),
    ('Plymouth Propane', 'plymouth-propane', 'propane', 'https://plymouthpropane.com', '508-746-7330', ARRAY['MA','Plymouth','Plymouth','Kingston','Carver','Middleborough']),
    ('Norfolk County Propane', 'norfolk-county-propane', 'propane', 'https://norfolkcountypropane.com', '508-528-5544', ARRAY['MA','Norfolk','Franklin','Wrentham','Medway','Millis','Norfolk']),
    ('Cohasset Gas & Propane', 'cohasset-gas-propane', 'propane', 'https://cohassetgas.com', '781-383-0660', ARRAY['MA','Norfolk','Plymouth','Cohasset','Hingham','Scituate','Hull']),
    ('Brockton Propane & Gas', 'brockton-propane-gas', 'propane', 'https://brocktonpropane.com', '508-586-3100', ARRAY['MA','Plymouth','Brockton','Abington','Whitman','East Bridgewater'])
ON CONFLICT (slug) DO NOTHING;
