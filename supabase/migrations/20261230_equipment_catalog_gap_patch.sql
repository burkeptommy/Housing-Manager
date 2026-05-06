-- Equipment catalog gap patch — Phase 1.5 of the expansion.
--
-- After running the full Phase 2 sweep on 456 brands and verifying the AO
-- Smith case end-to-end, an audit surfaced a handful of brands and
-- categories that should have been in the original Phase 1 seed but
-- weren't. This migration fills those gaps.
--
-- Scope: residential homes $450K+ (all tiers, budget through ultra-luxury),
-- not exclusively HNW. Adds brands across the full price spectrum where
-- they were missing.
--
-- Idempotent: ON CONFLICT DO NOTHING throughout so re-running is safe.

BEGIN;

-- ============================================================================
-- Missing categories
-- ============================================================================

INSERT INTO equipment_categories (name, slug, room, typical_lifespan_years, description) VALUES
  ('Hot Tub', 'hot-tub', 'outdoor', 15, 'Self-contained hot tubs and portable spas'),
  ('Spa Equipment', 'spa-equipment', 'outdoor', 12, 'Spa pumps, heaters, controllers'),
  ('Sauna', 'sauna', 'living', 25, 'Indoor and outdoor saunas (traditional and infrared)'),
  ('Steam Generator', 'steam-generator', 'bath', 12, 'Steam shower generators and controls'),
  ('Smart Window Treatments', 'smart-window-treatments', 'living', 12, 'Motorized blinds, shades, and drapery systems'),
  ('Ceiling Fan', 'ceiling-fan', 'living', 15, 'Indoor and outdoor ceiling fans'),
  ('Skylight', 'skylight', 'exterior', 25, 'Fixed and venting skylights, sun tunnels'),
  ('Range Hood Insert (Standalone)', 'range-hood-liner', 'kitchen', 15, 'Custom-cabinet range hood liners and inserts'),
  ('Whole-Home Audio Amplifier', 'audio-amplifier', 'living', 15, 'Multi-zone amplifiers for distributed audio'),
  ('Tankless Recirculation Pump', 'tankless-recirc-pump', 'plumbing', 12, 'On-demand hot water recirculation pumps')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- Missing manufacturers — across all price tiers
-- ============================================================================

INSERT INTO equipment_manufacturers (name, slug, parent_company, country_of_origin, tier) VALUES
  -- HNW kitchen brands missing from Phase 1
  ('Bertazzoni', 'bertazzoni', 'Bertazzoni S.p.A.', 'Italy', 'luxury'),
  ('Capital Cooking', 'capital', 'Capital Cooking Equipment', 'United States', 'luxury'),
  ('Fhiaba', 'fhiaba', 'Fhiaba S.p.A.', 'Italy', 'luxury'),
  ('Liebherr', 'liebherr', 'Liebherr Group', 'Germany', 'luxury'),
  ('True Residential', 'true-residential', 'True Manufacturing', 'United States', 'luxury'),
  ('Smeg', 'smeg', 'Smeg S.p.A.', 'Italy', 'premium'),
  ('Perlick', 'perlick', 'Perlick Corporation', 'United States', 'luxury'),

  -- Mainstream to premium kitchen / range hoods
  ('Best by Broan', 'best-by-broan', 'Broan-NuTone', 'United States', 'mainstream'),
  ('Vent-A-Hood', 'vent-a-hood', 'Vent-A-Hood', 'United States', 'premium'),
  ('Zephyr', 'zephyr', 'Zephyr Ventilation', 'United States', 'premium'),
  ('Faber', 'faber', 'Franke Group', 'Italy', 'premium'),
  ('Broan', 'broan', 'Broan-NuTone', 'United States', 'mainstream'),

  -- Luxury bath fixtures missing from Phase 1
  ('Graff', 'graff', 'Meridian International Group', 'United States', 'luxury'),
  ('Lefroy Brooks', 'lefroy-brooks', 'Lefroy Brooks', 'United Kingdom', 'luxury'),
  ('Perrin & Rowe', 'perrin-and-rowe', 'House of Rohl', 'United Kingdom', 'luxury'),
  ('Samuel Heath', 'samuel-heath', 'Samuel Heath & Sons', 'United Kingdom', 'luxury'),
  ('THG Paris', 'thg-paris', 'THG Paris', 'France', 'ultra-luxury'),

  -- HVAC / specialty heating + cooling
  ('Spacepak', 'spacepak', 'Mestek', 'United States', 'premium'),
  ('Unico', 'unico-system', 'Unico Inc.', 'United States', 'premium'),
  ('Chiltrix', 'chiltrix', 'Chiltrix Inc.', 'United States', 'premium'),
  ('SpacePak', 'spacepak-mestek', 'Mestek', 'United States', 'premium'),
  ('Sanyo', 'sanyo-hvac', 'Panasonic', 'Japan', 'mainstream'),
  ('Ductless Aire', 'ductless-aire', 'Total Home Supply', 'United States', 'budget'),
  ('Pioneer Mini Split', 'pioneer-mini-split', 'Parker-Davis HVAC', 'United States', 'budget'),

  -- Skylights + window treatments
  ('Velux', 'velux', 'VELUX Group', 'Denmark', 'premium'),
  ('Solatube', 'solatube', 'Solatube International', 'United States', 'premium'),
  ('Sun Tunnel', 'sun-tunnel', 'VELUX Group', 'Denmark', 'mainstream'),
  ('Hunter Douglas', 'hunter-douglas', 'Hunter Douglas', 'Netherlands', 'premium'),
  ('Somfy', 'somfy', 'Somfy Group', 'France', 'premium'),
  ('Lutron Serena', 'lutron-serena', 'Lutron Electronics', 'United States', 'premium'),

  -- Ceiling fans
  ('Hunter Fan Company', 'hunter-fan', 'Hunter Fan Company', 'United States', 'mainstream'),
  ('Casablanca', 'casablanca', 'Hunter Fan Company', 'United States', 'premium'),
  ('Big Ass Fans', 'big-ass-fans', 'Big Ass Fans', 'United States', 'premium'),
  ('Minka Aire', 'minka-aire', 'Minka Group', 'United States', 'mainstream'),
  ('Modern Forms', 'modern-forms', 'Modern Forms', 'United States', 'premium'),
  ('Emerson Fans', 'emerson-fans', 'Emerson Electric', 'United States', 'mainstream'),

  -- Saunas + steam
  ('Helo Sauna', 'helo-sauna', 'Helo Group', 'Finland', 'premium'),
  ('TyloHelo', 'tylohelo', 'TyloHelo Group', 'Sweden', 'luxury'),
  ('Saunum', 'saunum', 'Saunum', 'Estonia', 'premium'),
  ('Almost Heaven Saunas', 'almost-heaven-saunas', 'Almost Heaven Saunas', 'United States', 'mainstream'),
  ('Mr. Steam', 'mr-steam', 'Sussman-Automatic', 'United States', 'premium'),
  ('ThermaSol', 'thermasol', 'ThermaSol', 'United States', 'premium'),
  ('Steamist', 'steamist', 'Steamist', 'United States', 'premium'),
  ('Kohler Steam', 'kohler-steam', 'Kohler', 'United States', 'premium'),

  -- Hot tubs + spas
  ('Hot Spring Spas', 'hot-spring-spas', 'Watkins Wellness', 'United States', 'premium'),
  ('Caldera Spas', 'caldera-spas', 'Watkins Wellness', 'United States', 'premium'),
  ('Sundance Spas', 'sundance-spas', 'Jacuzzi Brands', 'United States', 'premium'),
  ('Bullfrog Spas', 'bullfrog-spas', 'Bullfrog Spas', 'United States', 'premium'),
  ('Master Spas', 'master-spas', 'Master Spas', 'United States', 'mainstream'),
  ('Cal Spas', 'cal-spas', 'Cal Spas', 'United States', 'mainstream'),
  ('Marquis Spas', 'marquis-spas', 'Marquis Spas', 'United States', 'premium'),
  ('Dimension One Spas', 'dimension-one-spas', 'Jacuzzi Brands', 'United States', 'premium'),
  ('Balboa Water Group', 'balboa-water-group', 'Balboa Water Group', 'United States', 'mainstream'),
  ('Gecko Alliance', 'gecko-alliance', 'Gecko Alliance', 'Canada', 'mainstream'),

  -- Recirculation + plumbing valves
  ('Watts Premier', 'watts-premier', 'Watts Water Technologies', 'United States', 'mainstream'),
  ('Taco Comfort Solutions', 'taco-comfort', 'Taco Comfort Solutions', 'United States', 'premium'),
  ('Bell & Gossett', 'bell-and-gossett', 'Xylem Inc.', 'United States', 'premium'),
  ('Armstrong Pumps', 'armstrong-pumps', 'Armstrong Fluid Technology', 'Canada', 'premium'),

  -- More HVAC mid-tier brands the Phase 1 seed missed
  ('Coleman HVAC', 'coleman-hvac-johnson', 'Johnson Controls', 'United States', 'mainstream'),
  ('Tempstar', 'tempstar', 'Carrier Global', 'United States', 'mainstream'),
  ('Comfortmaker', 'comfortmaker', 'Carrier Global', 'United States', 'mainstream'),
  ('Maytag HVAC', 'maytag-hvac', 'Nortek Air Solutions', 'United States', 'mainstream'),

  -- Mid-tier window/door brands
  ('Ply Gem', 'ply-gem', 'Cornerstone Building Brands', 'United States', 'mainstream'),
  ('Atrium Windows', 'atrium-windows', 'Cornerstone Building Brands', 'United States', 'mainstream'),
  ('Reeb', 'reeb', 'Reeb Millwork', 'United States', 'mainstream')

ON CONFLICT DO NOTHING;

COMMIT;
