-- Utility/service provider accounts for properties.
-- Tracks providers like electric, internet, security, gas, water, trash.
CREATE TABLE utility_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  provider_type TEXT NOT NULL, -- electric, internet_cable, security, natural_gas, water, trash, propane, oil, solar, other
  provider_name TEXT NOT NULL,
  provider_slug TEXT, -- for logo lookup
  account_number TEXT,
  phone TEXT,
  website TEXT,
  monthly_cost DECIMAL(10,2),
  plan_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_utility_accounts_property ON utility_accounts(property_id);

ALTER TABLE utility_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their household utility accounts"
  ON utility_accounts FOR SELECT
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can manage their household utility accounts"
  ON utility_accounts FOR INSERT
  WITH CHECK (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can update their household utility accounts"
  ON utility_accounts FOR UPDATE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can delete their household utility accounts"
  ON utility_accounts FOR DELETE
  USING (household_id IN (SELECT household_id FROM users WHERE id = auth.uid()));

-- Utility providers catalog — common providers users can pick from
CREATE TABLE utility_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  provider_type TEXT NOT NULL, -- electric, internet_cable, security, natural_gas, water, trash
  logo_url TEXT, -- Brandfetch CDN URL
  brand_color TEXT, -- hex color for card accent e.g. '#00629B'
  website TEXT,
  phone TEXT,
  regions TEXT[] DEFAULT '{}', -- states/regions where available e.g. {'CT','NY','MA'}
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed major providers with Brandfetch logo URLs and brand colors
INSERT INTO utility_providers (name, slug, provider_type, logo_url, brand_color, website, phone, regions) VALUES
-- Electric
('Eversource', 'eversource', 'electric', 'https://asset.brandfetch.io/idH5VQoB_j/idCmMbg9Fq.svg', '#00629B', 'https://eversource.com', '800-286-2000', '{CT,MA,NH}'),
('National Grid', 'national-grid', 'electric', 'https://asset.brandfetch.io/id2S3ssFJN/idFWv3XjFX.svg', '#003DA5', 'https://nationalgrid.com', '800-642-4272', '{NY,MA,RI}'),
('ConEdison', 'conedison', 'electric', 'https://asset.brandfetch.io/idchmO5eMU/idOjGKSUvh.svg', '#003DA5', 'https://coned.com', '800-752-6633', '{NY,NJ}'),
('Duke Energy', 'duke-energy', 'electric', 'https://asset.brandfetch.io/idkXVW_YbF/idF9nIGdT9.svg', '#00789E', 'https://duke-energy.com', '800-777-9898', '{NC,SC,FL,IN,OH,KY}'),
('Florida Power & Light', 'fpl', 'electric', 'https://asset.brandfetch.io/idM30Bgifl/idT3k3JNKM.svg', '#005DAA', 'https://fpl.com', '800-468-8243', '{FL}'),
('Pacific Gas & Electric', 'pge', 'electric', 'https://asset.brandfetch.io/id0E8CYUcC/idROWJRc_V.svg', '#004B87', 'https://pge.com', '800-743-5000', '{CA}'),
('Southern California Edison', 'sce', 'electric', NULL, '#E31837', 'https://sce.com', '800-655-4555', '{CA}'),
('Dominion Energy', 'dominion-energy', 'electric', 'https://asset.brandfetch.io/idALMm2Moj/id4CXlW9Wb.svg', '#1B365D', 'https://dominionenergy.com', '866-366-4357', '{VA,NC,SC}'),
('Entergy', 'entergy', 'electric', NULL, '#00263A', 'https://entergy.com', '800-368-3749', '{LA,TX,AR,MS}'),
('ComEd', 'comed', 'electric', NULL, '#00693C', 'https://comed.com', '800-334-7661', '{IL}'),
('PSEG', 'pseg', 'electric', 'https://asset.brandfetch.io/idG8PlK6RW/idlFp2y-_Y.svg', '#0072CE', 'https://pseg.com', '800-436-7734', '{NJ,NY}'),
('Xcel Energy', 'xcel-energy', 'electric', NULL, '#0065A4', 'https://xcelenergy.com', '800-895-4999', '{MN,CO,WI,TX,NM}'),
('Georgia Power', 'georgia-power', 'electric', NULL, '#003057', 'https://georgiapower.com', '888-660-5890', '{GA}'),
('CenterPoint Energy', 'centerpoint', 'electric', NULL, '#003B5C', 'https://centerpointenergy.com', '800-332-7143', '{TX,IN,MN,OH}'),

-- Internet/Cable
('Xfinity', 'xfinity', 'internet_cable', 'https://asset.brandfetch.io/id6xUhKXvn/idIi5RD8tR.svg', '#6138F5', 'https://xfinity.com', '800-934-6489', '{}'),
('Spectrum', 'spectrum', 'internet_cable', 'https://asset.brandfetch.io/iduASI-P0e/idmDDM4nyV.svg', '#0050AA', 'https://spectrum.com', '833-267-6094', '{}'),
('AT&T', 'att', 'internet_cable', 'https://asset.brandfetch.io/idawOgYMtY/idFKoVKHSp.svg', '#009FDB', 'https://att.com', '800-288-2020', '{}'),
('Verizon Fios', 'verizon-fios', 'internet_cable', 'https://asset.brandfetch.io/id2S_hpmoU/idYHO_M_1V.svg', '#CD040B', 'https://verizon.com/fios', '800-837-4966', '{}'),
('T-Mobile Home Internet', 'tmobile-home', 'internet_cable', 'https://asset.brandfetch.io/idMjPC5Gu2/idj8UlTTR7.svg', '#E20074', 'https://t-mobile.com/home-internet', '844-275-9310', '{}'),
('Google Fiber', 'google-fiber', 'internet_cable', 'https://asset.brandfetch.io/idnN4SIe_b/idR9_nwJ5x.svg', '#4285F4', 'https://fiber.google.com', '866-777-7550', '{}'),
('Frontier', 'frontier', 'internet_cable', NULL, '#FF0037', 'https://frontier.com', '800-921-8101', '{}'),
('Cox', 'cox', 'internet_cable', NULL, '#F36F21', 'https://cox.com', '800-234-3993', '{}'),
('Optimum', 'optimum', 'internet_cable', NULL, '#003DA5', 'https://optimum.com', '866-200-7273', '{NY,NJ,CT,PA}'),
('Starlink', 'starlink', 'internet_cable', NULL, '#000000', 'https://starlink.com', NULL, '{}'),

-- Security
('ADT', 'adt', 'security', 'https://asset.brandfetch.io/idMXJz_D0a/id-_gQX1RQ.svg', '#003DA5', 'https://adt.com', '800-716-3640', '{}'),
('Vivint', 'vivint', 'security', 'https://asset.brandfetch.io/idUd_0aBjr/idWPfB1ky_.svg', '#000000', 'https://vivint.com', '855-832-1550', '{}'),
('SimpliSafe', 'simplisafe', 'security', 'https://asset.brandfetch.io/id0L1PfedP/idqzMC-JUE.svg', '#1A2C5B', 'https://simplisafe.com', '888-957-4675', '{}'),
('Ring', 'ring', 'security', 'https://asset.brandfetch.io/ideJhfwPy3/idKa2fhM0T.svg', '#1C9AD6', 'https://ring.com', '800-656-1918', '{}'),
('Brinks Home', 'brinks-home', 'security', NULL, '#002855', 'https://brinkshome.com', '800-447-9239', '{}'),

-- Natural Gas
('National Grid Gas', 'national-grid-gas', 'natural_gas', 'https://asset.brandfetch.io/id2S3ssFJN/idFWv3XjFX.svg', '#003DA5', 'https://nationalgrid.com', '800-642-4272', '{NY,MA,RI}'),
('Southern Connecticut Gas', 'southern-ct-gas', 'natural_gas', NULL, '#005A9C', 'https://soconngas.com', '800-659-8299', '{CT}'),
('Connecticut Natural Gas', 'ct-natural-gas', 'natural_gas', NULL, '#003B5C', 'https://cngcorp.com', '800-989-0900', '{CT}'),
('SoCalGas', 'socalgas', 'natural_gas', NULL, '#003057', 'https://socalgas.com', '800-427-2200', '{CA}'),

-- Water
('American Water', 'american-water', 'water', NULL, '#0072CE', 'https://amwater.com', '800-272-1325', '{}'),
('Aquarion', 'aquarion', 'water', NULL, '#0077C0', 'https://aquarion.com', '800-732-9678', '{CT,MA,NH}'),

-- Trash/Recycling
('Waste Management', 'waste-management', 'trash', 'https://asset.brandfetch.io/idKZRu3JIn/idkB2bz1XG.svg', '#007749', 'https://wm.com', '866-797-9018', '{}'),
('Republic Services', 'republic-services', 'trash', NULL, '#004B87', 'https://republicservices.com', '800-433-1875', '{}'),

-- Propane
('Suburban Propane', 'suburban-propane', 'propane', NULL, '#E31837', 'https://suburbanpropane.com', '800-776-7263', '{}'),
('AmeriGas', 'amerigas', 'propane', NULL, '#003DA5', 'https://amerigas.com', '800-263-7442', '{}'),

-- Oil
('Petro Home Services', 'petro-home', 'oil', NULL, '#003B5C', 'https://petro.com', '800-645-4328', '{NY,NJ,CT,PA,MA,RI}'),
('Sippin Energy', 'sippin-energy', 'oil', NULL, '#1B3A5C', 'https://sippinenergy.com', '800-600-4992', '{CT}');
