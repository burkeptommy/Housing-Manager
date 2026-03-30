SET ROLE postgres;
-- ============================================================================
-- Typical Service Schedules — Category-Level Maintenance Tasks
-- Based on manufacturer guidelines and the Haven research document
-- ============================================================================

-- ======================== HVAC ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Replace air filter', 'Replace the HVAC air filter. Match exact dimensions (e.g., 20x25x4) and MERV rating the blower motor can handle. Higher MERV = more restriction.', 3, 15, true, false, ARRAY['Air filter (match dimensions and MERV rating)']),
  ('Clean condenser coils (outdoor unit)', 'Spray the outdoor condenser coil with a garden hose to remove dirt, leaves, and cottonwood. Straighten bent fins with a fin comb.', 12, 0, true, false, ARRAY['Garden hose','Fin comb (if fins are bent)']),
  ('Clear condensate drain line', 'Flush the AC condensate drain line with distilled vinegar or use a wet-dry vacuum on the outdoor end to prevent clogs and water damage.', 6, 5, true, false, ARRAY['Distilled white vinegar','Condensate pan tablets']),
  ('Professional HVAC tune-up', 'Annual professional inspection: check refrigerant charge, electrical connections, capacitor health, duct leakage, and combustion analysis for gas systems.', 12, 150, false, true, NULL),
  ('Clean flame sensor (gas furnace)', 'Remove and clean the flame sensor with fine steel wool or emery cloth. Prevents the most common winter no-heat failure.', 12, 0, true, false, ARRAY['Fine steel wool or emery cloth']),
  ('Check refrigerant charge', 'Professional check of refrigerant levels. Low charge indicates a leak that must be repaired — do not just top off.', 12, 100, false, true, NULL),
  ('Inspect ductwork', 'Check accessible ductwork for disconnections, crushed flex duct, and air leaks. Seal with mastic or metal tape (not duct tape).', 24, 0, true, false, ARRAY['Mastic sealant or aluminum tape']),
  ('Test thermostat calibration', 'Compare thermostat reading to a known-accurate thermometer placed nearby. Recalibrate or replace if off by more than 2°F.', 12, 0, true, false, ARRAY['Accurate thermometer'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'hvac';

-- ======================== WATER HEATER ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Flush tank sediment', 'Drain 2-3 gallons from the tank bottom via the drain valve to flush mineral sediment. Prevents hot spots, noise, and efficiency loss.', 12, 0, true, false, ARRAY['Garden hose']),
  ('Inspect anode rod', 'Check the sacrificial anode rod condition. Replace if less than 1/2 inch diameter or coated in calcium. Extend tank life by years.', 36, 30, true, false, ARRAY['Replacement anode rod (magnesium or aluminum/zinc)','1-1/16 inch socket']),
  ('Test TPR valve', 'Lift the temperature and pressure relief valve lever briefly to verify it opens and reseats. Water should flow freely when lifted. Replace if it drips after.', 12, 0, true, false, NULL),
  ('Descale tankless unit', 'Flush the tankless heat exchanger with white vinegar using a recirculating pump through the service valves. Critical for hard water areas.', 12, 15, true, false, ARRAY['Submersible pump','Two 6-foot hoses','5 gallons white vinegar','5-gallon bucket']),
  ('Check expansion tank pre-charge', 'Test the expansion tank air pressure with a tire gauge. Should match the incoming water pressure. Recharge if low.', 12, 0, true, false, ARRAY['Tire pressure gauge','Bicycle pump']),
  ('Check gas connections for leaks', 'Apply soapy water solution to gas connections and watch for bubbles. Any bubbles = immediate shutoff and repair.', 12, 0, true, false, ARRAY['Dish soap','Spray bottle'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'water-heater';

-- ======================== LAUNDRY ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Clean door gasket (front-load)', 'Wipe the rubber door boot seal dry after every use. Monthly deep clean with vinegar solution. Leave door ajar between loads.', 1, 0, true, false, ARRAY['White vinegar','Microfiber cloth']),
  ('Run washer cleaning cycle', 'Run an empty hot cycle with washer cleaner or 2 cups of white vinegar monthly to prevent odor, mold, and residue buildup.', 1, 3, true, false, ARRAY['Washer cleaner tablets or white vinegar']),
  ('Clean drain pump filter (front-load)', 'Open the small access panel at the bottom front. Place a towel and shallow pan to catch water. Unscrew the filter and remove debris.', 3, 0, true, false, ARRAY['Towels','Shallow pan']),
  ('Inspect washer hoses', 'Check rubber supply hoses for bulging, cracking, or corrosion at connections. Replace rubber hoses with braided stainless steel.', 6, 20, true, false, ARRAY['Braided stainless steel washer hoses (if upgrading)']),
  ('Clean dryer lint duct', 'Disconnect the vent hose from the dryer and wall. Clean the entire duct run with a dryer vent brush. Clean the lint trap housing with a long brush.', 12, 20, true, false, ARRAY['Dryer vent cleaning brush kit','New hose clamps']),
  ('Level the machine', 'Check and adjust leveling feet. An unlevel washer causes excessive vibration, noise, and premature bearing wear.', 12, 0, true, false, ARRAY['Bubble level','Adjustable wrench'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'washer' OR c.slug = 'dryer';

-- ======================== GENERATOR ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Change engine oil', 'Change oil per manufacturer schedule. New generators: first change after 5 hours to flush metal shavings. Then every 50-100 hours or annually.', 6, 10, true, false, ARRAY['Engine oil (SAE 10W-30)','Oil drain pan','Funnel']),
  ('Replace spark plug', 'Remove, inspect, and replace the spark plug. Gap to manufacturer spec. Prevents hard starting and misfires.', 12, 5, true, false, ARRAY['Replacement spark plug (match engine)']),
  ('Replace air filter', 'Clean or replace the engine air filter. Paper filters must be replaced; foam filters can be washed and re-oiled.', 12, 8, true, false, ARRAY['Replacement air filter']),
  ('Add fuel stabilizer', 'Add fuel stabilizer to the gas tank before storage. Run the engine for 5 minutes to circulate stabilized fuel through the carburetor.', 6, 8, true, false, ARRAY['Fuel stabilizer (e.g., Sta-Bil)']),
  ('Exercise standby generator', 'Standby generators should run a self-test weekly (usually auto-configured). Verify the exercise schedule is active and log completion.', 1, 0, true, false, NULL),
  ('Replace starter battery (standby)', 'Replace the 12V starter battery every 3 years — before storm season. Test voltage with a multimeter (should be 12.6V+ when charged).', 36, 120, true, false, ARRAY['Replacement 12V battery (match group size)','Battery terminal cleaner']),
  ('Inspect transfer switch', 'Annual professional inspection of the automatic transfer switch: check contacts, test operation, verify utility sense circuitry.', 12, 200, false, true, NULL)
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'generator';

-- ======================== SUMP PUMP ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Test pump operation', 'Pour a 5-gallon bucket of water into the sump pit. Verify the pump activates, pumps the water out, and shuts off. Do this every 3 months and before storm season.', 3, 0, true, false, ARRAY['5-gallon bucket']),
  ('Clean inlet screen and pit', 'Remove the pump and clean the inlet screen of debris, gravel, and sediment. Clean the pit walls and bottom.', 6, 0, true, false, ARRAY['Garden hose','Wet-dry vacuum']),
  ('Test battery backup', 'Unplug the primary pump and verify the battery backup activates when water rises. Check battery voltage and water level (if applicable).', 3, 0, true, false, ARRAY['Multimeter']),
  ('Replace backup battery', 'Replace the deep-cycle marine battery every 3-5 years. Check terminals for corrosion. Replace before spring rain season.', 42, 150, true, false, ARRAY['Deep-cycle marine battery (Group 27 or 31)','Battery terminal cleaner']),
  ('Inspect check valve', 'Verify the check valve is installed and functioning. Listen for water falling back into the pit when the pump shuts off — if you hear it, the valve has failed.', 12, 0, true, false, NULL),
  ('Inspect discharge line', 'Check the outdoor discharge point is clear of ice, debris, and dirt. Ensure water flows freely away from the foundation.', 3, 0, true, false, NULL)
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'sump-pump';

-- ======================== WELL WATER ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Test water quality', 'Annual water test for bacteria (coliform), nitrates, pH, hardness, iron, and manganese. More frequent testing if system changes or after heavy rain.', 12, 50, true, false, ARRAY['Water test kit or lab submission']),
  ('Check pressure tank pre-charge', 'With pump off and system drained, check the air valve pressure with a tire gauge. Should be 2 PSI below cut-in pressure (e.g., 28 PSI for a 30/50 switch).', 6, 0, true, false, ARRAY['Tire pressure gauge','Bicycle pump']),
  ('Replace UV lamp', 'UV disinfection lamps must be replaced every 12 months regardless of appearance. The germicidal output drops below safe levels even though the lamp still glows.', 12, 80, true, false, ARRAY['Replacement UV lamp (match model)','O-rings']),
  ('Replace UV quartz sleeve', 'The quartz sleeve protects the UV lamp from water contact. Replace every 2-3 years or if visibly clouded or etched.', 30, 50, true, false, ARRAY['Replacement quartz sleeve','O-rings']),
  ('Refill water softener salt', 'Check salt level monthly and refill as needed. Use the correct salt type for your unit (crystals, pellets, or potassium chloride).', 2, 15, true, false, ARRAY['Water softener salt (40-lb bag)']),
  ('Replace whole-house filter cartridges', 'Replace sediment and carbon filter cartridges per manufacturer schedule. Record the micron size and sequence.', 6, 30, true, false, ARRAY['Replacement filter cartridges (match micron size)','Filter wrench','Bucket']),
  ('Clean or replace iron filter media', 'Iron filter media (birm, greensand, catalytic carbon) needs regeneration chemical refills or full media replacement on a schedule.', 12, 50, true, false, ARRAY['Regeneration chemical (potassium permanganate for greensand)','Replacement media (every 5-10 years)'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'well-pump' OR c.slug = 'pressure-tank' OR c.slug = 'water-treatment-softener' OR c.slug = 'water-treatment-whole-house' OR c.slug = 'water-treatment-uv';

-- ======================== BATHROOM FIXTURES ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Clean faucet aerators', 'Unscrew the aerator from the faucet spout, disassemble, and soak in vinegar to dissolve mineral buildup. Rinse and reassemble.', 6, 0, true, false, ARRAY['White vinegar','Small bowl']),
  ('Check toilet flapper', 'Add food coloring to the tank and wait 15 minutes. If color appears in the bowl without flushing, the flapper needs replacement.', 12, 0, true, false, ARRAY['Food coloring']),
  ('Re-caulk tub/shower', 'Remove old caulk around the tub-to-tile and shower pan joints. Clean with mold remover, let dry, and apply fresh silicone caulk.', 12, 10, true, false, ARRAY['Silicone caulk','Caulk gun','Caulk removal tool','Mold remover spray']),
  ('Inspect supply line connections', 'Check under-sink and toilet supply line connections for drips, corrosion, or bulging. Replace braided stainless steel supply lines every 8-10 years.', 12, 0, true, false, ARRAY['Braided stainless steel supply lines (if replacing)']),
  ('Clean showerhead', 'Soak the showerhead in a bag of white vinegar overnight to dissolve mineral deposits. Scrub spray holes with a toothbrush.', 6, 0, true, false, ARRAY['White vinegar','Plastic bag','Rubber band'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'toilet' OR c.slug = 'bathroom-faucet' OR c.slug = 'shower-system' OR c.slug = 'bathtub';

-- ======================== IRRIGATION ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Spring startup inspection', 'Turn on each zone sequentially and walk the yard. Check for broken heads, clogged nozzles, misaligned spray patterns, and leaks.', 12, 0, true, false, ARRAY['Replacement heads (to have on hand)']),
  ('Winterization blowout', 'Hire a landscaper to blow compressed air through all zones to clear water from pipes before the first freeze. Critical in cold climates.', 12, 80, false, true, NULL),
  ('Adjust sprinkler heads', 'Check and adjust spray patterns so water hits the lawn/garden, not sidewalks, driveways, or the house. Straighten tilted heads.', 6, 0, true, false, ARRAY['Rotor adjustment tool (Hunter/Rain Bird key)']),
  ('Annual backflow preventer test', 'Many municipalities require an annual certified test of the irrigation backflow preventer. Schedule with a certified plumber. Keep the test report for records.', 12, 75, false, true, NULL),
  ('Replace controller backup battery', 'Replace the CR2032 or 9V backup battery in the irrigation controller to preserve programming during power outages.', 12, 5, true, false, ARRAY['CR2032 battery or 9V battery']),
  ('Clean drip emitters', 'Flush drip lines by opening the end caps and running water for 2-3 minutes. Replace clogged emitters.', 6, 0, true, false, ARRAY['Replacement drip emitters (if clogged)'])
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'irrigation-controller' OR c.slug = 'sprinkler-head' OR c.slug = 'backflow-preventer';

-- ======================== POOL SYSTEMS ========================

INSERT INTO equipment_service_schedules (category_id, task_name, description, frequency_months, estimated_cost, diy_possible, professional_recommended, parts_needed)
SELECT c.id, v.task, v.desc, v.freq, v.cost, v.diy, v.pro, v.parts
FROM equipment_categories c,
(VALUES
  ('Test water chemistry', 'Test pH (7.2-7.6), free chlorine (1-3 ppm), alkalinity (80-120 ppm), and cyanuric acid (30-50 ppm). Adjust as needed.', 1, 5, true, false, ARRAY['Test strips or liquid test kit','pH increaser/decreaser','Chlorine','Alkalinity increaser']),
  ('Clean pump strainer basket', 'Turn off the pump, release pressure, open the strainer lid, and remove debris from the basket. Check the O-ring for cracks.', 1, 0, true, false, ARRAY['Pool lube for O-ring']),
  ('Backwash or clean filter', 'Sand/DE: backwash when pressure rises 8-10 PSI above clean baseline. Cartridge: remove and hose off. Replace cartridge annually.', 3, 15, true, false, ARRAY['DE powder (for DE filters)','Replacement cartridge (annually)','Filter cleaner solution']),
  ('Inspect and lube O-rings', 'Check all O-rings on the pump lid, filter, and chlorinator for cracks. Apply Teflon-based pool lube to prevent air leaks.', 6, 5, true, false, ARRAY['Pool O-ring lube (Jack''s 327 or Magic Lube)']),
  ('Clean salt cell', 'Remove the salt chlorine generator cell and soak in a 4:1 water-to-muriatic-acid solution until bubbling stops (5-10 minutes). Rinse thoroughly.', 3, 5, true, false, ARRAY['Muriatic acid','5-gallon bucket','Safety goggles and gloves']),
  ('Pool opening (spring)', 'Remove cover, reinstall drain plugs, prime pump, start filtration, shock the pool, balance chemistry, and inspect all equipment.', 12, 200, true, true, ARRAY['Pool shock','Opening chemical kit','Drain plugs','Winterization plugs removal']),
  ('Pool closing (winterization)', 'Lower water level, blow out plumbing lines, install winterization plugs and skimmer gizmo, add closing chemicals, install cover.', 12, 200, true, true, ARRAY['Winterization plugs','Skimmer gizmo','Pool antifreeze','Closing chemical kit','Pool cover']),
  ('Inspect pool heater', 'Check gas connections, clean burner tray, inspect heat exchanger for soot or corrosion, verify ignition, and check pressure switch.', 12, 150, false, true, NULL)
) AS v(task, "desc", freq, cost, diy, pro, parts)
WHERE c.slug = 'pool-pump' OR c.slug = 'pool-filter' OR c.slug = 'salt-chlorine-generator' OR c.slug = 'pool-heater';
