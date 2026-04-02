-- ============================================================
-- Purpose:
--   Create SQL views used for feature engineering for the
--   Olympic medal prediction project.
--
-- What this file does:
--   1. Builds country-level historical medal rate features
--   2. Builds sport-level medal rate features
--   3. Builds athlete experience features
--   4. Combines all features into a final model-ready view
--
-- Output views:
--   - country_medal_rate
--   - sport_medal_rate
--   - athlete_experience
--   - model_dataset
--
-- How to run:
--   psql olympics_db -f sql/features/create_features.sql
-- ============================================================

-- ------------------------------------------------------------
-- View 1: country_medal_rate
-- Purpose:
--   Measure how strong each country is historically by
--   calculating the percentage of athlete entries that result
--   in a medal.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS country_medal_rate CASCADE;

CREATE VIEW country_medal_rate AS
SELECT
    a.nationality AS country_code,
    COUNT(*) AS total_entries,
    COUNT(*) FILTER (WHERE r.medal != 'No Medal') AS total_medals,
    ROUND(
        COUNT(*) FILTER (WHERE r.medal != 'No Medal')::decimal
        / COUNT(*), 3
    ) AS medal_rate
FROM results r
JOIN athletes a ON r.athlete_id = a.athlete_id
GROUP BY a.nationality
;



-- ------------------------------------------------------------
-- View 2: sport_medal_rate
-- Purpose:
--   Measure how frequently athlete entries in each sport result
--   in medals. This acts as a rough "sport competitiveness"
--   or medal-likelihood feature.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS sport_medal_rate CASCADE;

CREATE VIEW sport_medal_rate AS
SELECT
    sport,
    COUNT(*) AS total_entries,
    COUNT(*) FILTER (WHERE medal != 'No Medal') AS medal_count,
    ROUND(
        COUNT(*) FILTER (WHERE medal != 'No Medal')::decimal
        / COUNT(*), 3
    ) AS sport_medal_rate
FROM results
GROUP BY sport;



-- ------------------------------------------------------------
-- View 3: athlete_experience
-- Purpose:
--   Estimate athlete experience by counting how many result
--   records each athlete has in the dataset.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS athlete_experience CASCADE;

CREATE VIEW athlete_experience AS
SELECT
    athlete_id,
    COUNT(*) AS num_events
FROM results
GROUP BY athlete_id;



-- ------------------------------------------------------------
-- View 4: model_dataset
-- Purpose:
--   Create the final model-ready dataset by combining result
--   records with engineered country-, sport-, and athlete-level
--   features.
--
-- Notes:
--   This view will be used in Python for training a medal
--   prediction model.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS model_dataset CASCADE;

CREATE VIEW model_dataset AS
SELECT
    r.athlete_id,
    r.sport,
    r.event,
    r.team_or_individual,
    r.medal,
    c.medal_rate AS country_strength,
    s.sport_medal_rate,
    e.num_events AS athlete_experience
FROM results r
JOIN athletes a
    ON r.athlete_id = a.athlete_id
JOIN country_medal_rate c
    ON a.nationality = c.country_code
JOIN sport_medal_rate s
    ON r.sport = s.sport
JOIN athlete_experience e
    ON r.athlete_id = e.athlete_id;
