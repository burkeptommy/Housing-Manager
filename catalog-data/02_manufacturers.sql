-- ============================================================================
-- Kitchen Appliance Manufacturers
-- ============================================================================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, website_url, support_url, support_phone, tier, description) VALUES

-- Value & Budget
('Amana', 'amana', 'Whirlpool Corporation', 'US', 'https://www.amana.com', 'https://www.amana.com/support', '1-866-616-2664', 'budget',
 'Entry-level, reliable, bare-bones appliances. Backbone of starter homes, rentals, and budget-conscious renovations.'),

('Hotpoint', 'hotpoint', 'GE Appliances (Haier)', 'US', 'https://www.hotpoint.com', 'https://www.hotpoint.com/support', '1-800-626-2005', 'budget',
 'Very common in apartment complexes and property management. Manufactured by GE.'),

('Frigidaire', 'frigidaire', 'Electrolux Group', 'US', 'https://www.frigidaire.com', 'https://www.frigidaire.com/support', '1-800-374-4432', 'budget',
 'A staple for affordable refrigerators and electric ranges. Base line of the Electrolux family.'),

('Beko', 'beko', 'Arcelik (Koc Holding)', 'Turkey', 'https://www.beko.com/us-en', 'https://www.beko.com/us-en/support', '1-888-352-2356', 'budget',
 'European brand gaining ground in the US with energy-efficient, compact units at lower price points.'),

-- Mainstream & Mid-Range
('Whirlpool', 'whirlpool', 'Whirlpool Corporation', 'US', 'https://www.whirlpool.com', 'https://www.whirlpool.com/support', '1-866-698-2538', 'mainstream',
 'The most ubiquitous appliance brand in the US. Reliable, easy to repair, parts available everywhere.'),

('GE Appliances', 'ge-appliances', 'GE Appliances (Haier)', 'US', 'https://www.geappliances.com', 'https://www.geappliances.com/support', '1-800-626-2005', 'mainstream',
 'The workhorse of the American kitchen. Extensive options across standard sizes.'),

('Samsung', 'samsung', 'Samsung Electronics', 'South Korea', 'https://www.samsung.com/us/home-appliances/', 'https://www.samsung.com/us/support/', '1-800-726-7864', 'mainstream',
 'Dominates mid-to-high-end tech space with Family Hub touchscreens and modern aesthetics.'),

('LG', 'lg', 'LG Electronics', 'South Korea', 'https://www.lg.com/us/kitchen-appliances/', 'https://www.lg.com/us/support', '1-800-243-0000', 'mainstream',
 'Heavily focused on smart connectivity, InstaView doors, and high-performing ranges.'),

('Maytag', 'maytag', 'Whirlpool Corporation', 'US', 'https://www.maytag.com', 'https://www.maytag.com/support', '1-800-344-1274', 'mainstream',
 'Marketed for rugged durability and long-term warranties on core components.'),

-- Premium & Mass-Luxury
('KitchenAid', 'kitchenaid', 'Whirlpool Corporation', 'US', 'https://www.kitchenaid.com', 'https://www.kitchenaid.com/support', '1-800-541-6390', 'premium',
 'Premium tier of Whirlpool family. Known for heavy-duty professional-style ranges and iconic stand mixers.'),

('Bosch', 'bosch', 'BSH Home Appliances (Robert Bosch GmbH)', 'Germany', 'https://www.bosch-home.com/us/', 'https://www.bosch-home.com/us/support', '1-800-944-2904', 'premium',
 'Undisputed king of the premium dishwasher market. Highly respected for sleek wall ovens and induction cooktops.'),

('GE Profile', 'ge-profile', 'GE Appliances (Haier)', 'US', 'https://www.geappliances.com/ge-profile/', 'https://www.geappliances.com/support', '1-800-626-2005', 'premium',
 'GE step-up line integrating high-end smart tech and sleeker modern profiles.'),

('Cafe', 'cafe', 'GE Appliances (Haier)', 'US', 'https://www.cafeappliances.com', 'https://www.cafeappliances.com/support', '1-800-626-2005', 'premium',
 'Highly customizable. Famous for matte finishes and customizable hardware in copper, bronze, brass.'),

('Fisher & Paykel', 'fisher-paykel', 'Haier Group', 'New Zealand', 'https://www.fisherpaykel.com/us/', 'https://www.fisherpaykel.com/us/support.html', '1-888-936-7872', 'premium',
 'Known for distinct modular appliances like the DishDrawer and elegant flush-fit fridges.'),

('Electrolux', 'electrolux', 'Electrolux Group', 'Sweden', 'https://www.electrolux.com/us/', 'https://www.electrolux.com/us/support/', '1-877-435-3287', 'premium',
 'Premium parent to Frigidaire. Modern minimalist designs and high-performance induction cooking.'),

-- Luxury
('Thermador', 'thermador', 'BSH Home Appliances (Robert Bosch GmbH)', 'Germany', 'https://www.thermador.com', 'https://www.thermador.com/us/support', '1-800-735-4328', 'luxury',
 'Famous for the Star Burner gas ranges and massive built-in refrigerator columns. Part of the Bosch family.'),

('JennAir', 'jennair', 'Whirlpool Corporation', 'US', 'https://www.jennair.com', 'https://www.jennair.com/support', '1-800-536-6247', 'luxury',
 'Whirlpool true luxury line. Known for striking obsidian interiors and high-end downdraft ranges.'),

('Monogram', 'monogram', 'GE Appliances (Haier)', 'US', 'https://www.monogram.com', 'https://www.monogram.com/support', '1-800-444-1845', 'luxury',
 'GE absolute top-tier luxury. Commercial-grade materials, precision machining, custom-panel ready.'),

('Miele', 'miele', 'Miele & Cie. KG', 'Germany', 'https://www.mieleusa.com', 'https://www.mieleusa.com/e/support-7594.htm', '1-800-999-1360', 'luxury',
 'High-end German engineering built to last 20 years. Famous for built-in plumbed whole-bean coffee systems.'),

('Dacor', 'dacor', 'Samsung Electronics', 'US', 'https://www.dacor.com', 'https://www.dacor.com/support', '1-800-793-0093', 'luxury',
 'Samsung ultra-luxury architect-focused line with heavily integrated smart-home tech.'),

-- Ultra-Luxury & Specialty
('Sub-Zero', 'sub-zero', 'Sub-Zero Group, Inc.', 'US', 'https://www.subzero-wolf.com/sub-zero', 'https://www.subzero-wolf.com/assistance', '1-800-222-7820', 'ultra-luxury',
 'The gold standard in luxury refrigeration. Dual-zone wine preservation columns. Built in Madison, WI.'),

('Wolf', 'wolf', 'Sub-Zero Group, Inc.', 'US', 'https://www.subzero-wolf.com/wolf', 'https://www.subzero-wolf.com/assistance', '1-800-222-7820', 'ultra-luxury',
 'Cooking counterpart to Sub-Zero. Iconic red knobs, dual-stacked gas burners, professional-grade convection.'),

('Cove', 'cove', 'Sub-Zero Group, Inc.', 'US', 'https://www.subzero-wolf.com/cove', 'https://www.subzero-wolf.com/assistance', '1-800-222-7820', 'ultra-luxury',
 'Dishwasher counterpart to Sub-Zero and Wolf. Completes the ultra-luxury kitchen trinity.'),

('Gaggenau', 'gaggenau', 'BSH Home Appliances (Robert Bosch GmbH)', 'Germany', 'https://www.gaggenau.com/us/', 'https://www.gaggenau.com/us/service-support', '1-877-442-4436', 'ultra-luxury',
 'Pinnacle of modern European luxury. Handle-less push-open doors, extreme minimalism, combi-steam ovens.'),

('La Cornue', 'la-cornue', 'La Cornue SAS (Middleby Corporation)', 'France', 'https://www.lacornue.com', 'https://www.lacornue.com/contact', NULL, 'ultra-luxury',
 'French hand-crafted bespoke ranges. Custom-built to order, can cost as much as a luxury car.');
