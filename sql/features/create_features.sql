-- ============================================================
-- Purpose:
--   Create SQL views used for feature engineering for the
--   Olympic medal prediction project.
--
-- What this file does:
--   1. Builds country-level historical medal rate features
--   2. Builds sport-level medal rate features
--   3. Builds athlete experience features
--   4. Builds athlete history features
--   5. Builds country-by-sport strength features
--   6. Builds athlete age bucket features
--   7. Combines all features into a final model-ready view
--
-- Output views:
--   - country_medal_rate
--   - sport_medal_rate
--   - athlete_experience
--   - athlete_history
--   - country_sport_strength
--   - athlete_age_features
--   - model_dataset
--
-- How to run:
--   psql olympics_db -f sql/features/create_features.sql
-- ============================================================


-- ============================================================
-- Drop views in dependency order
--
-- Why:
--   model_dataset depends on all other feature-engineering
--   views, so it must be dropped first.
-- ============================================================

DROP VIEW IF EXISTS model_dataset;
DROP VIEW IF EXISTS athlete_age_features;
DROP VIEW IF EXISTS country_sport_strength;
DROP VIEW IF EXISTS athlete_history;
DROP VIEW IF EXISTS athlete_experience;
DROP VIEW IF EXISTS sport_medal_rate;
DROP VIEW IF EXISTS country_medal_rate;



-- ------------------------------------------------------------
-- View 1: country_medal_rate
--
-- Purpose:
--   Measure how strong each country is historically by
--   calculating the percentage of athlete entries that result
--   in a medal.
--
-- Why it matters:
--   Countries with stronger Olympic histories may produce
--   athletes more likely to medal.
-- ------------------------------------------------------------

CREATE VIEW country_medal_rate AS
SELECT
    a.nationality AS country_code,

    COUNT(*) AS total_entries,

    COUNT(*) FILTER (
        WHERE r.medal != 'No Medal'
    ) AS total_medals,

    ROUND(
        COUNT(*) FILTER (
            WHERE r.medal != 'No Medal'
        )::decimal / COUNT(*),
        3
    ) AS medal_rate

FROM results r

JOIN athletes a
ON r.athlete_id = a.athlete_id

GROUP BY a.nationality
;



-- ------------------------------------------------------------
-- View 2: sport_medal_rate
--
-- Purpose:
--   Measure how frequently athlete entries in each sport
--   result in medals.
--
-- Why it matters:
--   Some sports may historically have higher or lower medal
--   likelihoods.
-- ------------------------------------------------------------

CREATE VIEW sport_medal_rate AS
SELECT
    sport,

    COUNT(*) AS total_entries,

    COUNT(*) FILTER (
        WHERE medal != 'No Medal'
    ) AS medal_count,

    ROUND(
        COUNT(*) FILTER (
            WHERE medal != 'No Medal'
        )::decimal / COUNT(*),
        3
    ) AS sport_medal_rate

FROM results

GROUP BY sport
;



-- ------------------------------------------------------------
-- View 3: athlete_experience
--
-- Purpose:
--   Estimate athlete experience by counting how many Olympic
--   result records each athlete has.
--
-- Why it matters:
--   Athletes with more Olympic appearances may perform better
--   due to experience.
-- ------------------------------------------------------------

CREATE VIEW athlete_experience AS
SELECT
    athlete_id,

    COUNT(*) AS num_events

FROM results

GROUP BY athlete_id
;



-- ------------------------------------------------------------
-- View 4: athlete_history
--
-- Purpose:
--   Calculate historical athlete performance metrics.
--
-- Why it matters:
--   Athletes with prior medals or Olympic participation may
--   be more likely to medal again.
-- ------------------------------------------------------------

CREATE VIEW athlete_history AS
SELECT
    athlete_id,

    COUNT(*) FILTER (
        WHERE medal != 'No Medal'
    ) AS prior_medals,

    COUNT(*) AS prior_appearances

FROM results

GROUP BY athlete_id
;



-- ------------------------------------------------------------
-- View 5: country_sport_strength
--
-- Purpose:
--   Measure how successful each country is within each sport.
--
-- Why it matters:
--   Some countries dominate specific sports historically
--   (e.g., USA basketball, China diving).
-- ------------------------------------------------------------

CREATE VIEW country_sport_strength AS
SELECT
    a.nationality AS country_code,

    r.sport,

    COUNT(*) AS total_entries,

    COUNT(*) FILTER (
        WHERE r.medal != 'No Medal'
    ) AS medals,

    ROUND(
        COUNT(*) FILTER (
            WHERE r.medal != 'No Medal'
        )::decimal / COUNT(*),
        3
    ) AS country_sport_medal_rate

FROM results r

JOIN athletes a
ON r.athlete_id = a.athlete_id

GROUP BY a.nationality, r.sport
;



-- ------------------------------------------------------------
-- View 6: athlete_age_features
--
-- Purpose:
--   Create athlete age-based features and buckets.
--
-- Why it matters:
--   Olympic performance often varies by age range and sport.
--
-- Notes:
--   Age is calculated from date_of_birth because the athletes
--   table does not contain a direct age column.
-- ------------------------------------------------------------

CREATE VIEW athlete_age_features AS
SELECT
    athlete_id,

    DATE_PART(
        'year',
        AGE(date_of_birth)
    )::INT AS age,

    CASE
        WHEN DATE_PART('year', AGE(date_of_birth)) < 20
            THEN 'Under 20'

        WHEN DATE_PART('year', AGE(date_of_birth))
            BETWEEN 20 AND 24
            THEN '20-24'

        WHEN DATE_PART('year', AGE(date_of_birth))
            BETWEEN 25 AND 29
            THEN '25-29'

        WHEN DATE_PART('year', AGE(date_of_birth))
            BETWEEN 30 AND 34
            THEN '30-34'

        ELSE '35+'
    END AS age_bucket

FROM athletes
;



-- ------------------------------------------------------------
-- View 7: model_dataset
--
-- Purpose:
--   Create the final model-ready dataset by combining result
--   records with all engineered features.
--
-- Why it matters:
--   This final view acts as the single source used for
--   machine learning model training in Python.
-- ------------------------------------------------------------

CREATE VIEW model_dataset AS
SELECT
    r.athlete_id,

    r.sport,

    r.event,

    r.team_or_individual,

    r.medal,

    -- Country-level feature
    c.medal_rate AS country_strength,

    -- Sport-level feature
    s.sport_medal_rate,

    -- Athlete experience feature
    e.num_events AS athlete_experience,

    -- Athlete history features
    ah.prior_medals,
    ah.prior_appearances,

    -- Country-by-sport feature
    css.country_sport_medal_rate,

    -- Age features
    af.age,
    af.age_bucket,

    -- Binary team-event feature
    CASE
        WHEN r.team_or_individual = 'Team'
            THEN 1
        ELSE 0
    END AS is_team_event

FROM results r

JOIN athletes a
ON r.athlete_id = a.athlete_id

JOIN country_medal_rate c
ON a.nationality = c.country_code

JOIN sport_medal_rate s
ON r.sport = s.sport

JOIN athlete_experience e
ON r.athlete_id = e.athlete_id

JOIN athlete_history ah
ON r.athlete_id = ah.athlete_id

JOIN country_sport_strength css
ON a.nationality = css.country_code
AND r.sport = css.sport

JOIN athlete_age_features af
ON r.athlete_id = af.athlete_id
;