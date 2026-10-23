-- The window calculations already exist in fx_horizon_metrics.
-- It is now safe to filter to the latest common date.
SELECT date, previous_date, observations, currency, raw_rate,
       usd_per_fcy, amount_fcy, fx_return_pct,
       previous_value_usd, current_value_usd, fx_translation_change_usd
FROM fx_horizon_metrics
WHERE date = (SELECT MAX(date) FROM normalized_fx)
  AND previous_rate IS NOT NULL
ORDER BY observations, currency;
