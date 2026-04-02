-- Function for delimiter-normalized model number search.
-- Strips hyphens, underscores, dots, and spaces from both the search query
-- and stored model numbers for fuzzy matching.
-- Example: "BOVA60HDN1M20G" matches "BOVA-60HDN1-M20G"

CREATE OR REPLACE FUNCTION search_model_normalized(
  search_query TEXT,
  result_limit INTEGER DEFAULT 15
)
RETURNS TABLE(id UUID, model_number TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT ec.id, ec.model_number
  FROM equipment_catalog ec
  WHERE lower(replace(replace(replace(replace(ec.model_number, '-', ''), '_', ''), '.', ''), ' ', ''))
    LIKE '%' || lower(search_query) || '%'
  ORDER BY ec.is_current_model DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;
