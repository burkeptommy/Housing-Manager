-- ============================================================================
-- Kitchen Appliance Categories
-- ============================================================================

INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description) VALUES
-- Primary categories
('Refrigerator', 'refrigerator', NULL, 'kitchen', 13, 'Full-size refrigerators and fridge-freezer combos'),
('Range', 'range', NULL, 'kitchen', 15, 'Freestanding and slide-in ranges combining oven and cooktop'),
('Wall Oven', 'wall-oven', NULL, 'kitchen', 14, 'Built-in single, double, and combination wall ovens'),
('Cooktop', 'cooktop', NULL, 'kitchen', 15, 'Built-in gas, electric, and induction cooktops'),
('Dishwasher', 'dishwasher', NULL, 'kitchen', 10, 'Built-in, portable, and drawer dishwashers'),
('Microwave', 'microwave', NULL, 'kitchen', 9, 'Over-the-range, countertop, built-in, and drawer microwaves'),
('Range Hood', 'range-hood', NULL, 'kitchen', 14, 'Wall-mount, island, under-cabinet, insert, and downdraft ventilation'),
('Freezer', 'freezer', NULL, 'kitchen', 11, 'Standalone upright and chest freezers'),
('Garbage Disposal', 'garbage-disposal', NULL, 'kitchen', 10, 'In-sink food waste disposers'),
('Wine & Beverage', 'wine-beverage', NULL, 'kitchen', 12, 'Wine coolers, beverage centers, and wine columns'),
('Ice Maker', 'ice-maker', NULL, 'kitchen', 8, 'Standalone and under-counter ice machines'),
('Warming Drawer', 'warming-drawer', NULL, 'kitchen', 15, 'Built-in warming and slow-cook drawers'),
('Coffee System', 'coffee-system', NULL, 'kitchen', 10, 'Built-in plumbed coffee machines and espresso systems'),
('Trash Compactor', 'trash-compactor', NULL, 'kitchen', 12, 'Built-in and freestanding trash compactors'),
('Vacuum Sealer Drawer', 'vacuum-sealer', NULL, 'kitchen', 15, 'Built-in vacuum sealer drawers (Gaggenau, Miele)'),
('Speed Oven', 'speed-oven', NULL, 'kitchen', 12, 'Combination convection-microwave speed ovens'),
('Steam Oven', 'steam-oven', NULL, 'kitchen', 12, 'Built-in steam and combi-steam ovens');

-- Refrigerator sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('French Door Refrigerator', 'refrigerator-french-door', 13, 'French door bottom-freezer refrigerators'),
    ('Side-by-Side Refrigerator', 'refrigerator-side-by-side', 13, 'Side-by-side door refrigerators'),
    ('Top Freezer Refrigerator', 'refrigerator-top-freezer', 14, 'Traditional top-freezer refrigerators'),
    ('Bottom Freezer Refrigerator', 'refrigerator-bottom-freezer', 13, 'Bottom-freezer refrigerators with swing or drawer'),
    ('Column Refrigerator', 'refrigerator-column', 15, 'Full-height built-in refrigerator columns (no freezer)'),
    ('Column Freezer', 'freezer-column', 15, 'Full-height built-in freezer columns'),
    ('4-Door Refrigerator', 'refrigerator-4-door', 13, 'Four-door or quad-door refrigerators'),
    ('Under-Counter Refrigerator', 'refrigerator-under-counter', 12, 'Compact under-counter refrigeration units'),
    ('Built-In Refrigerator', 'refrigerator-built-in', 15, 'Counter-depth built-in refrigerators with custom panel options')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'refrigerator';

-- Range sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Gas Range', 'range-gas', 15, 'Ranges with gas burners and gas or electric oven'),
    ('Electric Range', 'range-electric', 14, 'Ranges with electric/radiant cooktop and electric oven'),
    ('Dual Fuel Range', 'range-dual-fuel', 15, 'Gas burners with electric convection oven'),
    ('Induction Range', 'range-induction', 14, 'Ranges with induction cooktop and electric oven'),
    ('Pro/Commercial Range', 'range-pro', 18, 'Professional-style ranges with high-BTU burners')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'range';

-- Wall Oven sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Single Wall Oven', 'wall-oven-single', 14, 'Single built-in wall ovens'),
    ('Double Wall Oven', 'wall-oven-double', 14, 'Double built-in wall ovens'),
    ('Combo Wall Oven', 'wall-oven-combo', 13, 'Wall oven with built-in microwave above or below')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'wall-oven';

-- Cooktop sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Gas Cooktop', 'cooktop-gas', 15, 'Built-in gas cooktops'),
    ('Electric Cooktop', 'cooktop-electric', 14, 'Built-in radiant/smooth-top electric cooktops'),
    ('Induction Cooktop', 'cooktop-induction', 14, 'Built-in induction cooktops')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'cooktop';

-- Microwave sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Over-the-Range Microwave', 'microwave-otr', 9, 'Microwaves installed above the range with built-in ventilation'),
    ('Countertop Microwave', 'microwave-countertop', 8, 'Freestanding countertop microwave ovens'),
    ('Built-In Microwave', 'microwave-built-in', 10, 'Trim-kit built-in microwaves for cabinetry'),
    ('Microwave Drawer', 'microwave-drawer', 10, 'Pull-out drawer-style built-in microwaves')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'microwave';

-- Range Hood sub-categories
INSERT INTO equipment_categories (name, slug, parent_category_id, room, typical_lifespan_years, description)
SELECT sub.name, sub.slug, c.id, 'kitchen', sub.lifespan, sub.desc
FROM equipment_categories c,
(VALUES
    ('Wall Mount Range Hood', 'range-hood-wall', 14, 'Chimney-style wall-mounted range hoods'),
    ('Island Range Hood', 'range-hood-island', 14, 'Ceiling-mounted island range hoods'),
    ('Under-Cabinet Range Hood', 'range-hood-under-cabinet', 12, 'Range hoods mounted under wall cabinets'),
    ('Insert/Liner Range Hood', 'range-hood-insert', 14, 'Hood inserts for custom cabinetry'),
    ('Downdraft Ventilation', 'range-hood-downdraft', 14, 'Pop-up or built-in downdraft ventilation systems')
) AS sub(name, slug, lifespan, "desc")
WHERE c.slug = 'range-hood';
