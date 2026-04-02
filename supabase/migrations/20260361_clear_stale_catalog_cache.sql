-- One-time: clear stale catalog cache data that was populated with wrong
-- catalog matches (e.g., fridge showing dishwasher data). The new matching
-- logic in the app will re-populate correctly on next load.
UPDATE home_systems SET
  catalog_series = NULL,
  catalog_model_name = NULL,
  catalog_features = '{}',
  reliability_score = NULL,
  score_summary = NULL,
  catalog_fuel_type = NULL,
  catalog_enriched_at = NULL,
  cached_manual_links = '[]';
