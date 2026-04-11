-- ============================================================================
-- Middlesex County, MA -- Local Utility Providers
-- ============================================================================
-- Covers ~54 towns from Metro West through the Lowell/Concord corridor.
-- Three sections:
--   1. Municipal water departments
--   2. Municipal trash / DPW services
--   3. Local heating oil and propane dealers serving the county
--
-- All inserts use ON CONFLICT (slug) DO NOTHING so re-running is safe.
-- ============================================================================

-- ============================================================================
-- SECTION 1: MUNICIPAL WATER DEPARTMENTS -- Middlesex County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Arlington Water Department', 'arlington-water-dept', 'water', 'https://arlingtonma.gov/departments/public-works/water-sewer', '781-316-3108', ARRAY['Arlington','MA','Middlesex']),
    ('Billerica Water Department', 'billerica-water-dept', 'water', 'https://town.billerica.ma.us/196/Water-Department', '978-671-0940', ARRAY['Billerica','MA','Middlesex']),
    ('Burlington Water Department', 'burlington-water-dept', 'water', 'https://burlington.org/301/Water-Department', '781-270-1670', ARRAY['Burlington','MA','Middlesex']),
    ('Cambridge Water Department', 'cambridge-water-dept-mx', 'water', 'https://cambridgema.gov/water', '617-349-4770', ARRAY['Cambridge','MA','Middlesex']),
    ('Chelmsford Water District', 'chelmsford-water-district', 'water', 'https://chelmsfordwater.com', '978-256-2381', ARRAY['Chelmsford','MA','Middlesex']),
    ('Concord Water Department', 'concord-water-dept', 'water', 'https://concordma.gov/443/Water-Sewer-Division', '978-318-3250', ARRAY['Concord','MA','Middlesex']),
    ('Framingham Water Department', 'framingham-water-dept', 'water', 'https://framinghamma.gov/2837/Water-Division', '508-532-6050', ARRAY['Framingham','MA','Middlesex']),
    ('Hudson Water Department', 'hudson-water-dept', 'water', 'https://townofhudson.org/water-department', '978-562-9192', ARRAY['Hudson','MA','Middlesex']),
    ('Lexington Water Department', 'lexington-water-dept', 'water', 'https://lexingtonma.gov/public-works/water-sewer', '781-274-8325', ARRAY['Lexington','MA','Middlesex']),
    ('Lowell Regional Water Utility', 'lowell-regional-water', 'water', 'https://lowellma.gov/479/Water-Utility', '978-674-4258', ARRAY['Lowell','MA','Middlesex']),
    ('Malden Water Department', 'malden-water-dept', 'water', 'https://cityofmalden.org/452/Water-Department', '781-397-7170', ARRAY['Malden','MA','Middlesex']),
    ('Marlborough Water Department', 'marlborough-water-dept', 'water', 'https://marlborough-ma.gov/281/Water-Department', '508-624-6910', ARRAY['Marlborough','MA','Middlesex']),
    ('Medford Water Department', 'medford-water-dept', 'water', 'https://medfordma.org/departments/water', '781-393-2480', ARRAY['Medford','MA','Middlesex']),
    ('Melrose Water Department', 'melrose-water-dept', 'water', 'https://cityofmelrose.org/public-works/water', '781-979-4170', ARRAY['Melrose','MA','Middlesex']),
    ('Natick Water Department', 'natick-water-dept', 'water', 'https://natickma.gov/399/Water-Sewer', '508-647-6550', ARRAY['Natick','MA','Middlesex']),
    ('Newton Water Department', 'newton-water-dept', 'water', 'https://newtonma.gov/government/public-works/water-sewer', '617-796-1420', ARRAY['Newton','MA','Middlesex']),
    ('Reading Water Department', 'reading-water-dept', 'water', 'https://readingma.gov/291/Water-Department', '781-942-9070', ARRAY['Reading','MA','Middlesex']),
    ('Somerville Water Department', 'somerville-water-dept', 'water', 'https://somervillema.gov/departments/water-sewer', '617-625-6600', ARRAY['Somerville','MA','Middlesex']),
    ('Stoneham Water Department', 'stoneham-water-dept', 'water', 'https://stoneham-ma.gov/water-sewer', '781-279-2696', ARRAY['Stoneham','MA','Middlesex']),
    ('Tewksbury Water Department', 'tewksbury-water-dept', 'water', 'https://tewksbury-ma.gov/water-department', '978-640-4370', ARRAY['Tewksbury','MA','Middlesex']),
    ('Wakefield Water Department', 'wakefield-water-dept', 'water', 'https://wakefield.ma.us/water-sewer', '781-246-6384', ARRAY['Wakefield','MA','Middlesex']),
    ('Waltham Water Department', 'waltham-water-dept', 'water', 'https://city.waltham.ma.us/water-department', '781-314-3420', ARRAY['Waltham','MA','Middlesex']),
    ('Watertown Water Department', 'watertown-water-dept', 'water', 'https://watertown-ma.gov/341/Water-Sewer', '617-972-6420', ARRAY['Watertown','MA','Middlesex']),
    ('Woburn Water Department', 'woburn-water-dept', 'water', 'https://woburnma.gov/departments/water-department', '781-897-5898', ARRAY['Woburn','MA','Middlesex'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 2: MUNICIPAL TRASH / DPW -- Middlesex County
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    ('Arlington DPW - Trash & Recycling', 'arlington-dpw-trash', 'trash', 'https://arlingtonma.gov/departments/public-works/trash-recycling', '781-316-3108', ARRAY['Arlington','MA','Middlesex']),
    ('Cambridge DPW - Trash', 'cambridge-dpw-trash', 'trash', 'https://cambridgema.gov/Services/trashrecycling', '617-349-4800', ARRAY['Cambridge','MA','Middlesex']),
    ('Framingham DPW - Solid Waste', 'framingham-dpw-trash', 'trash', 'https://framinghamma.gov/2840/Recycling-Solid-Waste', '508-532-6002', ARRAY['Framingham','MA','Middlesex']),
    ('Lexington DPW - Trash & Recycling', 'lexington-dpw-trash', 'trash', 'https://lexingtonma.gov/public-works/refuse-disposal', '781-274-8300', ARRAY['Lexington','MA','Middlesex']),
    ('Lowell DPW - Solid Waste', 'lowell-dpw-trash', 'trash', 'https://lowellma.gov/491/Solid-Waste', '978-674-4309', ARRAY['Lowell','MA','Middlesex']),
    ('Malden DPW - Trash', 'malden-dpw-trash', 'trash', 'https://cityofmalden.org/454/Trash-Recycling', '781-397-7160', ARRAY['Malden','MA','Middlesex']),
    ('Medford DPW - Trash', 'medford-dpw-trash', 'trash', 'https://medfordma.org/departments/public-works/trash', '781-393-2417', ARRAY['Medford','MA','Middlesex']),
    ('Newton DPW - Trash & Recycling', 'newton-dpw-trash', 'trash', 'https://newtonma.gov/government/public-works/trash-recycling', '617-796-1000', ARRAY['Newton','MA','Middlesex']),
    ('Somerville DPW - Trash', 'somerville-dpw-trash', 'trash', 'https://somervillema.gov/departments/dpw/trash-recycling', '311', ARRAY['Somerville','MA','Middlesex']),
    ('Waltham DPW - Solid Waste', 'waltham-dpw-trash', 'trash', 'https://city.waltham.ma.us/public-works/solid-waste', '781-314-3800', ARRAY['Waltham','MA','Middlesex']),
    ('Marlborough DPW - Trash', 'marlborough-dpw-trash', 'trash', 'https://marlborough-ma.gov/282/Trash-Recycling', '508-624-6910', ARRAY['Marlborough','MA','Middlesex']),
    ('Natick DPW - Trash & Recycling', 'natick-dpw-trash', 'trash', 'https://natickma.gov/398/Trash-Recycling', '508-647-6550', ARRAY['Natick','MA','Middlesex']),
    ('Woburn DPW - Trash', 'woburn-dpw-trash', 'trash', 'https://woburnma.gov/departments/public-works/trash-recycling', '781-897-5890', ARRAY['Woburn','MA','Middlesex']),
    ('Billerica DPW - Trash', 'billerica-dpw-trash', 'trash', 'https://town.billerica.ma.us/195/Public-Works', '978-671-0931', ARRAY['Billerica','MA','Middlesex']),
    ('Burlington DPW - Trash', 'burlington-dpw-trash', 'trash', 'https://burlington.org/300/Public-Works', '781-270-1660', ARRAY['Burlington','MA','Middlesex'])
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SECTION 3: LOCAL OIL & PROPANE DEALERS -- Middlesex County / Metro West
-- ============================================================================

INSERT INTO public.utility_providers (name, slug, provider_type, website, phone, regions) VALUES
    -- Heating Oil
    ('Metro West Oil', 'metro-west-oil', 'oil', 'https://metrowestoil.com', '508-655-1050', ARRAY['MA','Middlesex','Natick','Framingham','Ashland','Holliston']),
    ('Concord Fuel Company', 'concord-fuel-co', 'oil', 'https://concordfuel.com', '978-369-5580', ARRAY['MA','Middlesex','Concord','Lincoln','Carlisle','Acton']),
    ('Stow Oil Company', 'stow-oil-company', 'oil', 'https://stowoil.com', '978-897-5252', ARRAY['MA','Middlesex','Stow','Maynard','Hudson','Bolton']),
    ('Suburban Fuel of Framingham', 'suburban-fuel-framingham', 'oil', 'https://suburbanfuelframingham.com', '508-872-3331', ARRAY['MA','Middlesex','Framingham','Natick','Wayland','Sherborn']),
    ('Middlesex Oil Company', 'middlesex-oil-company', 'oil', 'https://middlesexoil.com', '978-452-7300', ARRAY['MA','Middlesex','Lowell','Chelmsford','Tewksbury','Dracut']),
    ('Nashoba Valley Oil', 'nashoba-valley-oil', 'oil', 'https://nashobavalleyoil.com', '978-448-6636', ARRAY['MA','Middlesex','Groton','Pepperell','Dunstable','Townsend','Ayer']),
    ('Winchester Fuel', 'winchester-fuel', 'oil', 'https://winchesterfuel.com', '781-729-2510', ARRAY['MA','Middlesex','Winchester','Woburn','Stoneham','Medford']),
    ('Lexington Oil & Propane', 'lexington-oil-propane', 'oil', 'https://lexingtonoil.com', '781-862-4545', ARRAY['MA','Middlesex','Lexington','Bedford','Burlington','Lincoln']),
    ('Waltham Fuel Service', 'waltham-fuel-service', 'oil', 'https://walthamfuel.com', '781-893-7400', ARRAY['MA','Middlesex','Waltham','Watertown','Weston','Newton']),
    ('Acton Oil & Gas', 'acton-oil-gas', 'oil', 'https://actonoilgas.com', '978-263-1050', ARRAY['MA','Middlesex','Acton','Boxborough','Littleton','Westford']),
    ('Somerville Fuel', 'somerville-fuel', 'oil', 'https://somervillefuel.com', '617-625-7580', ARRAY['MA','Middlesex','Somerville','Cambridge','Medford','Malden']),
    ('Tyngsborough Fuel', 'tyngsborough-fuel', 'oil', 'https://tyngsboroughfuel.com', '978-649-7811', ARRAY['MA','Middlesex','Tyngsborough','Dunstable','Pepperell','Dracut']),
    ('Wayland Oil Service', 'wayland-oil-service', 'oil', 'https://waylandoil.com', '508-358-2101', ARRAY['MA','Middlesex','Wayland','Sudbury','Weston','Lincoln']),
    ('Hopkinton Fuel', 'hopkinton-fuel', 'oil', 'https://hopkintonfuel.com', '508-435-3515', ARRAY['MA','Middlesex','Hopkinton','Holliston','Ashland','Sherborn']),

    -- Propane
    ('Assabet Valley Propane', 'assabet-valley-propane', 'propane', 'https://assabetpropane.com', '978-562-2500', ARRAY['MA','Middlesex','Hudson','Maynard','Stow','Bolton','Berlin']),
    ('Concord Propane', 'concord-propane', 'propane', 'https://concordpropane.com', '978-369-8700', ARRAY['MA','Middlesex','Concord','Carlisle','Lincoln','Bedford','Acton']),
    ('Lowell Propane Service', 'lowell-propane-service', 'propane', 'https://lowellpropane.com', '978-453-1880', ARRAY['MA','Middlesex','Lowell','Chelmsford','Tewksbury','Billerica']),
    ('Westford Gas & Propane', 'westford-gas-propane', 'propane', 'https://westfordgas.com', '978-692-4455', ARRAY['MA','Middlesex','Westford','Littleton','Groton','Chelmsford']),
    ('Sudbury Propane', 'sudbury-propane', 'propane', 'https://sudburypropane.com', '978-443-2020', ARRAY['MA','Middlesex','Sudbury','Wayland','Maynard','Framingham']),
    ('Arlington Propane & Gas', 'arlington-propane-gas', 'propane', 'https://arlingtonpropane.com', '781-643-5300', ARRAY['MA','Middlesex','Arlington','Medford','Somerville','Cambridge'])
ON CONFLICT (slug) DO NOTHING;
