-- Use common complete dates so all currencies have identical comparison dates.
CREATE VIEW complete_dates AS
SELECT date
FROM raw_fx
GROUP BY date
HAVING COUNT(*) = (SELECT COUNT(*) FROM currencies)
   AND COUNT(raw_rate) = (SELECT COUNT(*) FROM currencies);

-- Standardize every rate to USD per one foreign-currency unit.
CREATE VIEW normalized_fx AS
SELECT r.date, r.currency, r.raw_rate,
       CASE WHEN c.quote_convention = 'FCY_PER_USD'
            THEN 1.0 / r.raw_rate
            ELSE r.raw_rate
       END AS usd_per_fcy
FROM raw_fx AS r
JOIN currencies AS c ON r.currency = c.currency
JOIN complete_dates AS d ON r.date = d.date;

-- Calculate lags BEFORE restricting results to the latest date.
CREATE VIEW fx_lagged AS
SELECT date, currency, raw_rate, usd_per_fcy,
       LAG(date, 1) OVER w AS date_1,
       LAG(date, 5) OVER w AS date_5,
       LAG(date, 21) OVER w AS date_21,
       LAG(usd_per_fcy, 1) OVER w AS rate_1,
       LAG(usd_per_fcy, 5) OVER w AS rate_5,
       LAG(usd_per_fcy, 21) OVER w AS rate_21
FROM normalized_fx
WINDOW w AS (PARTITION BY currency ORDER BY date);

-- Make one row per date, currency and comparison horizon.
CREATE VIEW fx_horizon_metrics AS
WITH horizons AS (
    SELECT date, currency, raw_rate, usd_per_fcy,
           1 AS observations, date_1 AS previous_date, rate_1 AS previous_rate
    FROM fx_lagged
    UNION ALL
    SELECT date, currency, raw_rate, usd_per_fcy, 5, date_5, rate_5
    FROM fx_lagged
    UNION ALL
    SELECT date, currency, raw_rate, usd_per_fcy, 21, date_21, rate_21
    FROM fx_lagged
)
SELECT h.*, e.amount_fcy,
       100.0 * (h.usd_per_fcy / h.previous_rate - 1.0) AS fx_return_pct,
       e.amount_fcy * h.previous_rate AS previous_value_usd,
       e.amount_fcy * h.usd_per_fcy AS current_value_usd,
       e.amount_fcy * (h.usd_per_fcy - h.previous_rate) AS fx_translation_change_usd
FROM horizons AS h
JOIN exposures AS e ON h.currency = e.currency;
