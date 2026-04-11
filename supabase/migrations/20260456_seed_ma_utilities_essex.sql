-- ============================================================================
-- Essex County, MA -- Local Utility Providers
-- ============================================================================
-- Covers ~33 towns on the North Shore and Merrimack Valley.
-- Three sections:
--   1. Municipal water departments (towns large enough to run their own)
--   2. Municipal trash / DPW services
--   3. Local heating oil and propane dealers serving the county
--
-- All inserts use ON CONFLICT (slug) DO NOTHING so re-running is safe.
-- ============================================================================

-- ============================================================================
-- SECTION 1: MUNICIPAL WATER DEPARTMENTS -- Essex County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Andover Water Department', 'andover-water-dept', 'water', 'https://andoverma.gov/480/Water-Department', '978-623-8350', ARRAY['Andover','MA','Essex']),
    ('Beverly Water Department', 'beverly-water-dept', 'water', 'https://beverlyma.gov/399/Water-Sewer-Department', '978-921-6066', ARRAY['Beverly','MA','Essex']),
    ('Danvers Water Department', 'danvers-water-dept', 'water', 'https://danversma.gov/water-department', '978-777-0001', ARRAY['Danvers','MA','Essex']),
    ('Georgetown Water Department', 'georgetown-water-dept', 'water', 'https://georgetownma.gov/water-department', '978-352-5758', ARRAY['Georgetown','MA','Essex']),
    ('Gloucester Water Department', 'gloucester-water-dept', 'water', 'https://gloucester-ma.gov/230/Water-Department', '978-281-9775', ARRAY['Gloucester','MA','Essex']),
    ('Groveland Water Department', 'groveland-water-dept', 'water', 'https://grovelandma.com/water-department', '978-372-8207', ARRAY['Groveland','MA','Essex']),
    ('Haverhill Water Department', 'haverhill-water-dept', 'water', 'https://cityofhaverhill.com/departments/water', '978-374-2390', ARRAY['Haverhill','MA','Essex']),
    ('Ipswich Water Department', 'ipswich-water-dept', 'water', 'https://ipswichma.gov/178/Utilities-Department', '978-356-6635', ARRAY['Ipswich','MA','Essex']),
    ('Lawrence Water Department', 'lawrence-water-dept', 'water', 'https://cityoflawrence.com/240/Water-Department', '978-620-3080', ARRAY['Lawrence','MA','Essex']),
    ('Lynn Water & Sewer Commission', 'lynn-water-sewer', 'water', 'https://lynnwatersewer.org', '781-596-2400', ARRAY['Lynn','MA','Essex']),
    ('Marblehead Water & Sewer Commission', 'marblehead-water-sewer', 'water', 'https://marblehead.org/water-sewer', '781-631-0102', ARRAY['Marblehead','MA','Essex']),
    ('Merrimac Water Department', 'merrimac-water-dept', 'water', 'https://merrimac01860.info/water-department', '978-346-9589', ARRAY['Merrimac','MA','Essex']),
    ('Methuen Water Department', 'methuen-water-dept', 'water', 'https://cityofmethuen.net/water-department', '978-983-8545', ARRAY['Methuen','MA','Essex']),
    ('Newburyport Water Department', 'newburyport-water-dept', 'water', 'https://cityofnewburyport.com/water-department', '978-465-4464', ARRAY['Newburyport','MA','Essex']),
    ('North Andover Water Department', 'north-andover-water-dept', 'water', 'https://northandoverma.gov/water-department', '978-688-9575', ARRAY['North Andover','MA','Essex']),
    ('Peabody Water Department', 'peabody-water-dept', 'water', 'https://peabody-ma.gov/water-department', '978-531-2313', ARRAY['Peabody','MA','Essex']),
    ('Salem Water Department', 'salem-water-dept', 'water', 'https://salemma.gov/departments/water-sewer', '978-741-0636', ARRAY['Salem','MA','Essex']),
    ('Saugus Water Department', 'saugus-water-dept', 'water', 'https://saugus-ma.gov/water-department', '781-231-4168', ARRAY['Saugus','MA','Essex']),
    ('Swampscott Water Department', 'swampscott-water-dept', 'water', 'https://swampscottma.gov/public-works/water', '781-596-8854', ARRAY['Swampscott','MA','Essex'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 2: MUNICIPAL TRASH / DPW -- Essex County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Andover DPW - Solid Waste', 'andover-dpw-trash', 'trash', 'https://andoverma.gov/473/Solid-Waste-Recycling', '978-623-8710', ARRAY['Andover','MA','Essex']),
    ('Beverly DPW - Trash', 'beverly-dpw-trash', 'trash', 'https://beverlyma.gov/404/Trash-Recycling', '978-921-6066', ARRAY['Beverly','MA','Essex']),
    ('Danvers DPW - Solid Waste', 'danvers-dpw-trash', 'trash', 'https://danversma.gov/public-works', '978-774-1809', ARRAY['Danvers','MA','Essex']),
    ('Gloucester DPW - Trash & Recycling', 'gloucester-dpw-trash', 'trash', 'https://gloucester-ma.gov/230/Public-Works', '978-281-9780', ARRAY['Gloucester','MA','Essex']),
    ('Haverhill DPW - Solid Waste', 'haverhill-dpw-trash', 'trash', 'https://cityofhaverhill.com/departments/public-works', '978-374-2390', ARRAY['Haverhill','MA','Essex']),
    ('Lawrence DPW - Trash', 'lawrence-dpw-trash', 'trash', 'https://cityoflawrence.com/238/Public-Works', '978-620-3090', ARRAY['Lawrence','MA','Essex']),
    ('Lynn DPW - Trash & Recycling', 'lynn-dpw-trash', 'trash', 'https://cityoflynn.net/public-works', '781-477-7099', ARRAY['Lynn','MA','Essex']),
    ('Methuen DPW - Trash', 'methuen-dpw-trash', 'trash', 'https://cityofmethuen.net/public-works', '978-983-8585', ARRAY['Methuen','MA','Essex']),
    ('Newburyport DPW - Solid Waste', 'newburyport-dpw-trash', 'trash', 'https://cityofnewburyport.com/public-services', '978-465-4414', ARRAY['Newburyport','MA','Essex']),
    ('Peabody DPW - Trash', 'peabody-dpw-trash', 'trash', 'https://peabody-ma.gov/public-services', '978-531-1377', ARRAY['Peabody','MA','Essex']),
    ('Salem DPW - Trash & Recycling', 'salem-dpw-trash', 'trash', 'https://salemma.gov/departments/public-services', '978-744-1015', ARRAY['Salem','MA','Essex']),
    ('Saugus DPW - Trash', 'saugus-dpw-trash', 'trash', 'https://saugus-ma.gov/public-works', '781-231-4168', ARRAY['Saugus','MA','Essex'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 3: LOCAL OIL & PROPANE DEALERS -- Essex County / North Shore
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    -- Heating Oil
    ('Peterson Oil', 'peterson-oil', 'oil', 'https://petersonoil.com', '781-334-2131', ARRAY['MA','Essex','Lynnfield','Wakefield','Reading','North Reading']),
    ('Murray Oil Company', 'murray-oil-salem', 'oil', 'https://murrayoilco.com', '978-744-6500', ARRAY['MA','Essex','Salem','Peabody','Marblehead','Danvers']),
    ('McPhee Oil', 'mcphee-oil', 'oil', 'https://mcpheeoil.com', '978-356-2318', ARRAY['MA','Essex','Ipswich','Hamilton','Wenham','Essex','Topsfield']),
    ('North Shore Fuel', 'north-shore-fuel', 'oil', 'https://northshorefuel.com', '978-927-1010', ARRAY['MA','Essex','Beverly','Danvers','Salem','Wenham']),
    ('Merrimack Valley Oil', 'merrimack-valley-oil', 'oil', 'https://merrimackvalleyoil.com', '978-374-4060', ARRAY['MA','Essex','Haverhill','Methuen','North Andover','Lawrence']),
    ('Eastern Oil & Propane', 'eastern-oil-propane-danvers', 'oil', 'https://easternoilpropane.com', '978-774-0005', ARRAY['MA','Essex','Danvers','Middleton','Topsfield','Peabody']),
    ('Salem Oil Company', 'salem-oil-company', 'oil', 'https://salemoil.com', '978-744-1250', ARRAY['MA','Essex','Salem','Marblehead','Swampscott','Lynn']),
    ('Cape Ann Oil', 'cape-ann-oil', 'oil', 'https://capeannoil.com', '978-283-7780', ARRAY['MA','Essex','Gloucester','Rockport','Manchester-by-the-Sea','Essex']),
    ('Ipswich Oil & Propane', 'ipswich-oil-propane', 'oil', 'https://ipswichoilpropane.com', '978-356-2950', ARRAY['MA','Essex','Ipswich','Rowley','Newbury','Georgetown']),
    ('Newburyport Fuel Company', 'newburyport-fuel', 'oil', 'https://newburyportfuel.com', '978-462-5411', ARRAY['MA','Essex','Newburyport','Newbury','Salisbury','West Newbury']),
    ('Lynnfield Fuel', 'lynnfield-fuel', 'oil', 'https://lynnfieldfuel.com', '781-334-5600', ARRAY['MA','Essex','Lynnfield','Saugus','Wakefield']),
    ('Nahant Oil Service', 'nahant-oil-service', 'oil', 'https://nahantoil.com', '781-581-0110', ARRAY['MA','Essex','Nahant','Lynn','Swampscott']),
    ('Boxford Fuel & Heating', 'boxford-fuel-heating', 'oil', 'https://boxfordfuel.com', '978-887-5050', ARRAY['MA','Essex','Boxford','Georgetown','Topsfield','Middleton']),

    -- Propane
    ('Essex County Propane', 'essex-county-propane', 'propane', 'https://essexcountypropane.com', '978-468-1144', ARRAY['MA','Essex','Hamilton','Wenham','Ipswich','Topsfield','Boxford']),
    ('North Shore Propane', 'north-shore-propane', 'propane', 'https://northshorepropane.com', '978-927-6665', ARRAY['MA','Essex','Beverly','Danvers','Salem','Peabody','Middleton']),
    ('Merrimack Propane', 'merrimack-propane', 'propane', 'https://merrimackpropane.com', '978-373-0050', ARRAY['MA','Essex','Haverhill','Groveland','Merrimac','West Newbury']),
    ('Andover Propane & Gas', 'andover-propane-gas', 'propane', 'https://andoverpropane.com', '978-475-1800', ARRAY['MA','Essex','Andover','North Andover','Boxford','Lawrence']),
    ('Rockport Propane', 'rockport-propane', 'propane', 'https://rockportpropane.com', '978-546-3050', ARRAY['MA','Essex','Rockport','Gloucester','Manchester-by-the-Sea']),
    ('Salisbury Propane Service', 'salisbury-propane', 'propane', 'https://salisburypropane.com', '978-462-7200', ARRAY['MA','Essex','Salisbury','Newburyport','Newbury','Amesbury'])
ON CONFLICT (slug) DO NOTHING;
