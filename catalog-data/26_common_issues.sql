SET ROLE postgres;
-- ============================================================================
-- Common Issues & Fixes — Category-Level
-- Based on industry knowledge and the Haven research document
-- ============================================================================

-- ======================== HVAC COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Dirty or clogged air filter',
   'Restricted airflow from a dirty filter causes the system to work harder, reduces efficiency, and can lead to frozen evaporator coils or overheating.',
   ARRAY['Weak airflow from vents','Higher energy bills','System short cycling','Ice on refrigerant lines'],
   'Replace the air filter. Check filter size printed on the old filter frame and match exactly.',
   'easy', 5, 30, 1,
   ARRAY['Replacement air filter (match dimensions and MERV rating)'],
   10, 'Industry standard maintenance'),

  ('Refrigerant leak',
   'Low refrigerant causes poor cooling, ice buildup, and compressor damage. R-410A systems cannot be topped off indefinitely — the leak must be found and repaired.',
   ARRAY['AC blowing warm air','Ice on evaporator coil','Hissing or bubbling sound','Higher electric bills'],
   'Professional must locate the leak (often at coil joints or service valves), repair it, and recharge to factory spec. If R-22, system likely needs full replacement.',
   'professional_only', 300, 1500, 8,
   ARRAY['Refrigerant (R-410A or R-454B)','Leak sealant or brazing materials'],
   120, 'HVAC industry data'),

  ('Capacitor failure',
   'The start/run capacitor stores energy to help the compressor and fan motors start. When it fails, the outdoor unit hums but won''t start, or the fan spins slowly.',
   ARRAY['Outdoor unit humming but not starting','Fan spinning slowly','AC not cooling','Clicking sounds'],
   'Replace the capacitor. Match the microfarad (µF) rating and voltage exactly. Discharge old capacitor before handling.',
   'moderate', 100, 300, 6,
   ARRAY['Replacement capacitor (match µF and voltage ratings)'],
   30, 'HVAC technician reports'),

  ('Flame sensor dirty (gas furnace)',
   'A dirty flame sensor cannot detect the burner flame, causing the furnace to light briefly then shut off. The most common winter no-heat call.',
   ARRAY['Furnace lights then shuts off after 3-5 seconds','Repeated ignition attempts','Lockout after 3 failed attempts'],
   'Remove the flame sensor (single screw), clean with fine steel wool or emery cloth, reinstall. Takes 10 minutes.',
   'moderate', 0, 10, 2,
   ARRAY['Fine steel wool or emery cloth'],
   15, 'Haven research document'),

  ('Frozen evaporator coil',
   'Ice forms on the indoor coil due to low airflow (dirty filter), low refrigerant, or a failing blower motor. Must thaw before diagnosing root cause.',
   ARRAY['No cooling','Ice visible on indoor coil or refrigerant lines','Water leak around air handler','Restricted airflow'],
   'Turn system to FAN ONLY to thaw (4-24 hours). Check/replace air filter. If it refreezes, call a tech for refrigerant check.',
   'moderate', 0, 500, 5,
   ARRAY['Replacement air filter'],
   30, 'HVAC industry data'),

  ('Thermostat wiring or programming issue',
   'Incorrect thermostat wiring, dead batteries, or misconfigured schedules cause the system to not respond or cycle incorrectly.',
   ARRAY['System not responding to thermostat','Incorrect temperatures displayed','System running constantly','No display on thermostat'],
   'Check and replace thermostat batteries. Verify wiring matches the old thermostat label photo. Reset schedules.',
   'easy', 5, 200, 4,
   ARRAY['Thermostat batteries (AA or AAA)','Wire nuts'],
   20, 'Smart thermostat support data'),

  ('Condensate drain clogged',
   'The AC condensate drain line clogs with algae and buildup, causing water to back up and trigger a float switch safety shutoff or leak into the home.',
   ARRAY['Water pooling around indoor unit','AC shuts off unexpectedly','Musty smell from vents','Water damage on ceiling below unit'],
   'Flush the drain line with distilled vinegar or a wet-dry vacuum. Install a condensate drain pan treatment tablet.',
   'easy', 5, 200, 2,
   ARRAY['Distilled white vinegar','Condensate pan treatment tablets'],
   20, 'HVAC maintenance guides'),

  ('Blower motor failure',
   'The indoor blower motor wears out, causing no airflow. Variable-speed ECM motors are more expensive to replace than standard PSC motors.',
   ARRAY['No air from vents','Furnace/AC runs but no airflow','Grinding or squealing noise','Burning smell'],
   'Replace the blower motor. ECM (variable speed) motors cost $400-800 for the part alone. PSC motors are $100-300.',
   'professional_only', 300, 1200, 12,
   ARRAY['Replacement blower motor','Run capacitor (if PSC motor)'],
   90, 'HVAC repair statistics')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'hvac';

-- ======================== WATER HEATER COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Anode rod depleted',
   'The sacrificial anode rod protects the tank from corrosion. Once it dissolves (3-5 years), the tank itself begins to rust from the inside out, leading to leaks.',
   ARRAY['Rusty or discolored hot water','Rotten egg smell (if magnesium rod)','Popping or rumbling noises','Tank is over 3 years old with no rod check'],
   'Inspect and replace the anode rod. Use a 1-1/16" socket on the hex head at the top of the tank. Replace with aluminum/zinc combo rod if experiencing odor.',
   'moderate', 20, 50, 4,
   ARRAY['Replacement anode rod (magnesium or aluminum/zinc)','Teflon tape'],
   45, 'Haven research document'),

  ('Sediment buildup in tank',
   'Minerals settle at the bottom of the tank, reducing capacity, creating hot spots that damage the glass lining, and causing popping/rumbling noises.',
   ARRAY['Popping or rumbling sounds during heating','Longer recovery times','Reduced hot water capacity','Higher energy bills'],
   'Drain and flush the tank via the drain valve at the bottom. Run until water flows clear. Do this annually.',
   'moderate', 0, 0, 2,
   ARRAY['Garden hose'],
   45, 'Water heater manufacturer guidelines'),

  ('Thermocouple / flame sensor failure (gas)',
   'The thermocouple detects the pilot light flame. When it fails, the gas valve shuts off and the pilot won''t stay lit.',
   ARRAY['Pilot light won''t stay lit','No hot water','Gas valve shuts off repeatedly'],
   'Replace the thermocouple. They are universal and cost $10-20 at hardware stores.',
   'moderate', 10, 25, 5,
   ARRAY['Universal thermocouple'],
   30, 'Plumbing industry data'),

  ('TPR valve weeping or leaking',
   'The temperature and pressure relief valve opens to prevent tank explosion. Frequent dripping may indicate excessive pressure, high temperature, or a failing valve.',
   ARRAY['Water dripping from TPR discharge pipe','Valve hissing','Water on floor near tank'],
   'Test the valve by lifting the lever briefly. If it continues to drip after releasing, replace the valve. Check water pressure — should be under 80 PSI.',
   'moderate', 15, 40, 6,
   ARRAY['Replacement TPR valve (match BTU rating)','Teflon tape'],
   30, 'Plumbing code requirements'),

  ('Tankless: scale buildup / descaling needed',
   'Hard water deposits calcium scale inside the heat exchanger, reducing flow rate and efficiency. Annual flushing is critical for longevity.',
   ARRAY['Reduced hot water flow','Error code on display','Water not reaching set temperature','Unit cycling on and off'],
   'Flush the heat exchanger with white vinegar using a recirculating pump and two hoses through the service valves. Takes 45-60 minutes.',
   'moderate', 15, 200, 1,
   ARRAY['Submersible pump','Two 6-foot hoses','5 gallons white vinegar','5-gallon bucket'],
   60, 'Haven research document'),

  ('Electric element burnout',
   'Electric water heaters have upper and lower heating elements. When one burns out, you get limited or no hot water.',
   ARRAY['No hot water (upper element)','Hot water runs out quickly (lower element)','Breaker tripping'],
   'Test elements with a multimeter for continuity. Replace the failed element. Drain the tank below the element level first.',
   'moderate', 15, 30, 6,
   ARRAY['Replacement heating element (match wattage and voltage)','Element wrench'],
   60, 'Electric water heater repair guides')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'water-heater';

-- ======================== LAUNDRY COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Door boot seal mold (front-load)',
   'The rubber door gasket on front-load washers traps moisture and develops mold and mildew, causing odor and potentially staining clothes.',
   ARRAY['Musty smell from washer','Visible black mold on door seal','Stains on clean clothes','Bad smell even after cleaning cycle'],
   'Wipe the seal dry after every load. Clean monthly with a 50/50 vinegar-water solution. Leave the door ajar between loads. Replace seal if mold is embedded.',
   'easy', 0, 250, 2,
   ARRAY['White vinegar','Baking soda','Replacement door boot seal (if needed)'],
   15, 'Appliance manufacturer guidelines'),

  ('Drain pump clogged or failed',
   'Small items (coins, bobby pins, socks) get past the filter and clog the drain pump, causing the washer to not drain or spin.',
   ARRAY['Washer won''t drain','Standing water in drum','Error code for drain','Burning smell from pump'],
   'Check the drain pump filter (usually behind a small panel at the bottom front). Remove debris. If the pump motor has failed, replace the pump.',
   'moderate', 0, 300, 4,
   ARRAY['Towels for water','Replacement drain pump (if motor failed)'],
   30, 'Appliance repair statistics'),

  ('Drum bearing failure',
   'The main bearing supporting the drum wears out, causing loud grinding/rumbling during spin cycle. A major repair that may total an older machine.',
   ARRAY['Loud grinding during spin','Rumbling or roaring noise','Drum wobbles when pushed','Water leaking from rear (rear-bearing models)'],
   'Requires disassembling the washer to replace the bearing and seal. Often includes the inner drum replacement on some brands. Usually a professional job.',
   'professional_only', 250, 600, 8,
   ARRAY['Bearing and seal kit','Inner tub (if scored)'],
   180, 'Appliance repair industry data'),

  ('Dryer not heating',
   'Electric dryers use heating elements and thermal fuses. Gas dryers use igniter and gas valve coils. When these fail, the dryer tumbles but produces no heat.',
   ARRAY['Clothes still wet after full cycle','Dryer tumbles but no heat','Takes multiple cycles to dry'],
   'Electric: test the thermal fuse (on the blower housing) and heating element for continuity. Gas: check the igniter glow — if it glows but gas doesn''t light, replace gas valve coils.',
   'moderate', 15, 200, 5,
   ARRAY['Thermal fuse','Heating element (electric) or gas valve coils (gas)','Multimeter'],
   60, 'Appliance repair guides'),

  ('Dryer vent lint buildup (fire hazard)',
   'Lint accumulates in the dryer vent duct over time, reducing airflow, increasing dry times, and creating a serious fire hazard. Leading cause of home dryer fires.',
   ARRAY['Clothes taking longer to dry','Dryer running hot','Burning smell','Lint visible around outside vent','Humid laundry room'],
   'Disconnect the vent hose and clean the entire run from dryer to exterior vent with a dryer vent brush kit. Clean the interior lint trap housing with a long brush.',
   'moderate', 20, 150, 1,
   ARRAY['Dryer vent cleaning brush kit','New vent hose clamps'],
   45, 'US Fire Administration / NFPA statistics')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'washer' OR c.slug = 'dryer';

-- ======================== GENERATOR COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Stale fuel / carburetor clog',
   'Gasoline left in a portable generator for more than 30 days without stabilizer forms varnish that clogs the carburetor jets, preventing starting.',
   ARRAY['Generator won''t start','Starts then dies','Surging or hunting RPM','Hard to pull-start'],
   'Drain old fuel. Remove and clean the carburetor (soak in carb cleaner). Replace fuel with fresh gas + fuel stabilizer. For severe cases, replace the carburetor.',
   'moderate', 10, 150, 2,
   ARRAY['Carburetor cleaner spray','Fuel stabilizer','Fresh gasoline','Replacement carburetor (if needed)'],
   60, 'Haven research document'),

  ('Starter battery dead (standby generators)',
   'Standby generators rely on a 12V battery to crank the engine during power outages. These batteries die every 3-4 years, often discovered during the first real outage.',
   ARRAY['Generator doesn''t start during outage','Low battery warning on controller','Weekly exercise test fails','Battery voltage below 12.4V'],
   'Replace the starter battery with the correct group size. Check battery terminals for corrosion. Set a calendar reminder for replacement every 3 years.',
   'easy', 80, 200, 3,
   ARRAY['Replacement 12V battery (match group size)','Battery terminal cleaner','Dielectric grease'],
   20, 'Haven research document'),

  ('Oil level low / oil not changed',
   'Portable generators without oil filters need oil changes every 50-100 hours. New generators need their first oil change after 5 hours to flush metal shavings.',
   ARRAY['Low oil shutdown','Oil is black or gritty','Engine running rough','Increased engine noise'],
   'Change oil per manufacturer schedule. Use the specified viscosity (typically SAE 10W-30). Check oil level before every use.',
   'easy', 8, 15, 1,
   ARRAY['Engine oil (SAE 10W-30)','Oil drain pan','Funnel'],
   15, 'Haven research document')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'generator';

-- ======================== SUMP PUMP COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Float switch stuck or jammed',
   'The float switch activates the pump when water rises. Tethered floats can snag on the pit wall or discharge pipe. Vertical floats can get stuck with debris.',
   ARRAY['Pump doesn''t activate when water rises','Pump runs continuously','Basement flooding','Float visibly stuck against pit wall'],
   'Check float clearance — ensure nothing impedes its travel. Clean debris from the pit. Consider upgrading to an electronic switch if float issues persist.',
   'easy', 0, 50, 2,
   ARRAY['Zip ties for cable management (if needed)'],
   15, 'Haven research document'),

  ('Check valve failed or missing',
   'Without a working check valve, water flows back into the pit after each pump cycle, causing the pump to short-cycle and wear out prematurely.',
   ARRAY['Pump cycles on and off rapidly','Water level doesn''t drop even though pump is running','Banging noise when pump shuts off'],
   'Install or replace the check valve on the discharge pipe. Use a spring-loaded (quiet) check valve and install it within 12 inches of the pump.',
   'moderate', 15, 40, 5,
   ARRAY['Check valve (match discharge pipe diameter)','PVC cement','Hose clamps'],
   30, 'Plumbing industry best practices'),

  ('Backup battery dead',
   'Battery backup sump pumps use deep-cycle marine batteries that die every 3-5 years. Discovered during the next power outage — often too late.',
   ARRAY['Backup pump doesn''t run during power outage','Battery alarm beeping','Low battery indicator on controller','Battery is swollen or leaking'],
   'Replace the battery with a deep-cycle marine battery (Group 27 or 31 is most common). Check battery terminals for corrosion annually.',
   'easy', 100, 200, 4,
   ARRAY['Deep-cycle marine battery (match group size)','Battery terminal cleaner'],
   20, 'Haven research document'),

  ('Pump motor burnout',
   'The pump motor can burn out from overwork (continuous running from a stuck float), running dry, or electrical surge. Usually requires full pump replacement.',
   ARRAY['Pump doesn''t respond at all','Breaker trips when pump tries to start','Burning smell from pit','Humming but no pumping'],
   'Replace the sump pump. Match the HP rating, discharge size, and switch type of the old unit.',
   'moderate', 100, 400, 7,
   ARRAY['Replacement sump pump','PVC fittings','Check valve'],
   60, 'Pump manufacturer data')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'sump-pump';

-- ======================== BATHROOM FIXTURE COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Toilet flapper worn or warped',
   'The rubber flapper valve at the bottom of the tank deteriorates over time, allowing water to constantly leak into the bowl — a "running toilet."',
   ARRAY['Toilet runs intermittently','Water rippling in bowl','Higher water bill','Have to jiggle handle to stop running'],
   'Replace the flapper. Match the size (2-inch or 3-inch) and brand. Universal flappers work for most toilets. Shut off water, drain tank, swap the flapper.',
   'easy', 5, 15, 3,
   ARRAY['Replacement flapper (2" or 3" — match existing)'],
   10, 'Plumbing maintenance guides'),

  ('Wax ring leak at toilet base',
   'The wax ring seals the toilet to the drain flange. When it fails, sewer gas and water leak around the base of the toilet.',
   ARRAY['Water pooling around toilet base','Sewer smell in bathroom','Toilet rocks or wobbles','Staining around toilet base'],
   'Remove the toilet, scrape off the old wax ring, install a new one (wax or waxless gasket), and reseat the toilet. Tighten bolts evenly.',
   'moderate', 5, 20, 8,
   ARRAY['Wax ring or waxless toilet gasket','Closet bolts','Caulk'],
   45, 'Plumbing repair data'),

  ('Faucet cartridge dripping',
   'The internal cartridge or ceramic disc wears out, causing a drip from the spout even when the handle is fully off.',
   ARRAY['Dripping from spout when off','Handle feels loose or grinds','Difficulty getting water to fully shut off'],
   'Replace the cartridge. Most major brands (Moen 1222, Delta RP46074, Kohler GP77759) have specific cartridges. Shut off water supply first.',
   'moderate', 10, 50, 5,
   ARRAY['Replacement cartridge (brand-specific)','Plumber''s grease'],
   30, 'Faucet manufacturer data')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'toilet' OR c.slug = 'bathroom-faucet';

-- ======================== IRRIGATION COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Broken sprinkler head (mower damage)',
   'Mower blades or foot traffic crack sprinkler heads, causing geysers or flooding. The most common irrigation repair.',
   ARRAY['Water geyser from one head','Flooded area around head','Head won''t retract','Visible broken top'],
   'Dig around the head, unscrew it from the riser, and screw on a matching replacement. Match the brand, nozzle type, and pop-up height.',
   'easy', 5, 20, 2,
   ARRAY['Replacement sprinkler head (match brand and type)','Teflon tape'],
   15, 'Irrigation maintenance guides'),

  ('Zone valve stuck open or closed',
   'Irrigation zone valves use a solenoid and diaphragm to control water flow. Debris, mineral buildup, or a failed solenoid causes zones to not activate or not shut off.',
   ARRAY['Zone won''t turn on from controller','Zone runs continuously and won''t shut off','Weak water pressure on one zone'],
   'Try turning the solenoid 1/4 turn counterclockwise to manually activate. If stuck open, disassemble the valve and clean or replace the diaphragm.',
   'moderate', 10, 80, 5,
   ARRAY['Replacement diaphragm','Replacement solenoid (if failed)'],
   30, 'Irrigation industry data'),

  ('Winterization damage (freeze)',
   'Water left in irrigation pipes and valves freezes and expands, cracking PVC pipes, valve bodies, and backflow preventers. Requires professional blowout in cold climates.',
   ARRAY['Leaks appearing at multiple locations in spring','Cracked valve bodies','Backflow preventer leaking','Low pressure across all zones'],
   'Schedule a professional compressed-air blowout before the first freeze each fall. Repair any cracked pipes or fittings in spring.',
   'professional_only', 100, 500, 3,
   ARRAY['Replacement PVC fittings','PVC primer and cement','Replacement backflow preventer (if cracked)'],
   120, 'Haven research document')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'irrigation-controller' OR c.slug = 'sprinkler-head';

-- ======================== POOL SYSTEM COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Pump shaft seal leak',
   'The mechanical shaft seal between the motor and wet end wears out, causing water to leak from the pump housing. If ignored, water reaches the motor bearings.',
   ARRAY['Water dripping from pump housing','Wet area under the pump','Motor running louder','Rust stains on pump'],
   'Replace the shaft seal. Requires removing the motor from the pump housing, pressing out the old seal, and installing a new one with silicone lubricant.',
   'hard', 15, 40, 4,
   ARRAY['Replacement shaft seal (match pump model)','Silicone-based lubricant'],
   60, 'Pool equipment repair data'),

  ('Salt cell calcification',
   'Calcium scale builds up on the titanium salt chlorine generator cell plates, reducing chlorine output. Cells last ~10,000 hours if maintained, half that if not.',
   ARRAY['Low chlorine output','Cell warning light on','Visible white buildup on cell plates','Pool turning green despite salt level being correct'],
   'Remove the cell and soak in a 4:1 water-to-muriatic-acid solution for 5-10 minutes until bubbling stops. Rinse thoroughly. Do this every 3 months.',
   'moderate', 5, 15, 1,
   ARRAY['Muriatic acid (1 quart)','5-gallon bucket','Safety goggles and gloves'],
   30, 'Salt chlorine generator manufacturer guidelines'),

  ('Filter pressure high (dirty filter)',
   'As the filter catches debris, pressure rises. When it''s 8-10 PSI above the clean baseline, the filter needs cleaning or the media needs replacement.',
   ARRAY['Pressure gauge reads 8+ PSI above clean baseline','Weak return flow to pool','Cloudy water','DE powder returning to pool'],
   'Sand: backwash for 3 minutes. Cartridge: remove and hose off, soak in filter cleaner solution. DE: backwash and recharge with fresh DE powder.',
   'easy', 10, 60, 1,
   ARRAY['Filter cleaner solution','DE powder (for DE filters)','Replacement cartridge (annually)'],
   30, 'Pool maintenance guides'),

  ('Heater ignition failure',
   'Gas pool heaters can fail to ignite due to a dirty pilot assembly, failed igniter, clogged burner tray, or gas supply issues.',
   ARRAY['Heater clicks but doesn''t fire','Error codes on display','Pool not heating','Smell of gas near heater'],
   'Check gas supply valve is open. Clean the burner tray and pilot assembly. If the igniter glows but gas doesn''t flow, the gas valve may need replacement.',
   'professional_only', 150, 600, 5,
   ARRAY['Igniter','Gas valve (if failed)','Burner tray gaskets'],
   90, 'Pool heater service manuals'),

  ('Pump basket O-ring failure (air leak)',
   'The O-ring on the pump strainer basket lid dries out and cracks, allowing air into the suction line. This causes the pump to lose prime and can melt PVC fittings.',
   ARRAY['Air bubbles in pump basket','Pump losing prime','Bubbles visible at return jets','Pump running louder than normal'],
   'Remove the basket lid, clean the O-ring groove, apply Teflon-based pool lube to the O-ring. Replace if cracked or flattened.',
   'easy', 5, 15, 2,
   ARRAY['Replacement O-ring (match pump model)','Magic Lube or Jack''s 327 pool lube'],
   10, 'Haven research document')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'pool-pump' OR c.slug = 'salt-chlorine-generator' OR c.slug = 'pool-filter' OR c.slug = 'pool-heater';

-- ======================== WELL WATER COMMON ISSUES ========================

INSERT INTO equipment_common_issues (category_id, issue_title, description, symptoms, typical_fix, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years, parts_needed, repair_time_minutes, source)
SELECT c.id, v.title, v.desc, v.symptoms, v.fix, v.diy, v.cost_low, v.cost_high, v.occurs_at, v.parts, v.minutes, v.src
FROM equipment_categories c,
(VALUES
  ('Pressure switch failure',
   'The pressure switch tells the pump when to turn on and off based on system pressure. When it fails, the pump may not start, or it may run continuously.',
   ARRAY['Pump not starting','Pump running continuously','Rapid cycling on/off','No water pressure'],
   'Check and clean the switch contacts. If corroded or pitted, replace the switch. Match the cut-in/cut-out pressure settings (typically 30/50 or 40/60 PSI).',
   'moderate', 20, 50, 5,
   ARRAY['Replacement pressure switch (match PSI settings)'],
   30, 'Well pump service data'),

  ('Waterlogged pressure tank',
   'The air bladder in the pressure tank ruptures or loses pre-charge, causing the tank to fill with water (waterlogged). This causes rapid pump cycling.',
   ARRAY['Pump cycles on/off every few seconds (rapid cycling)','Tank feels heavy and completely full of water','Low pressure fluctuations','Pump running constantly'],
   'Check the tank pre-charge with a tire gauge on the air valve (should be 2 PSI below cut-in). If the bladder is ruptured, the tank must be replaced.',
   'moderate', 200, 600, 8,
   ARRAY['Replacement pressure tank','Teflon tape','Pressure gauge'],
   120, 'Haven research document'),

  ('UV lamp end of life',
   'UV disinfection lamps lose germicidal effectiveness after 9,000-12,000 hours (approximately 1 year). The UV dose drops below safe levels even though the lamp still glows.',
   ARRAY['UV alarm or indicator light','Lamp glowing dimmer','Annual replacement date passed','Water test shows bacteria'],
   'Replace the UV lamp annually regardless of whether it still appears to glow. Replace the quartz sleeve every 2-3 years or if visibly clouded.',
   'easy', 60, 150, 1,
   ARRAY['Replacement UV lamp (match model)','Replacement quartz sleeve (every 2-3 years)','O-rings'],
   20, 'Haven research document')
) AS v(title, "desc", symptoms, fix, diy, cost_low, cost_high, occurs_at, parts, minutes, src)
WHERE c.slug = 'well-pump' OR c.slug = 'pressure-tank' OR c.slug = 'water-treatment-uv';
