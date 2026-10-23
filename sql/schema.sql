PRAGMA foreign_keys = ON;
DROP VIEW IF EXISTS fx_horizon_metrics;
DROP VIEW IF EXISTS fx_lagged;
DROP VIEW IF EXISTS normalized_fx;
DROP VIEW IF EXISTS complete_dates;
DROP TABLE IF EXISTS exposures;
DROP TABLE IF EXISTS raw_fx;
DROP TABLE IF EXISTS currencies;

CREATE TABLE currencies (
    currency TEXT PRIMARY KEY,
    source_series TEXT NOT NULL UNIQUE,
    quote_convention TEXT NOT NULL CHECK (
        quote_convention IN ('USD_PER_FCY', 'FCY_PER_USD')
    )
);

-- One source observation per date and currency. Missing rates remain NULL.
CREATE TABLE raw_fx (
    date TEXT NOT NULL,
    currency TEXT NOT NULL REFERENCES currencies(currency),
    raw_rate REAL CHECK (raw_rate IS NULL OR raw_rate > 0),
    PRIMARY KEY (date, currency)
);

-- Hypothetical constant, unhedged foreign-currency cash holdings.
CREATE TABLE exposures (
    currency TEXT PRIMARY KEY REFERENCES currencies(currency),
    amount_fcy REAL NOT NULL CHECK (amount_fcy > 0)
);
