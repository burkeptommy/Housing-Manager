-- Clear catalog cache so the improved matching logic repopulates correctly.
-- Model-number-first search will now find exact matches.
UPDATE home_systems SET
  catalog_series = NULL,
  catalog_model_name = NULL,
  catalog_features = '{}',
  reliability_score = NULL,
  score_summary = NULL,
  catalog_fuel_type = NULL,
  catalog_enriched_at = NULL,
  cached_manual_links = '[]';
