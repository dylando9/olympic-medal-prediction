DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS athletes;
DROP TABLE IF EXISTS countries;
DROP TABLE IF EXISTS olympic_games;

CREATE TABLE countries (
    country_code TEXT PRIMARY KEY,
    country_name TEXT,
    first_participation INT,
    best_rank INT,
    total_gold INT,
    total_medals INT
);

CREATE TABLE athletes (
    athlete_id TEXT PRIMARY KEY,
    athlete_name TEXT,
    gender TEXT,
    date_of_birth DATE,
    height_cm FLOAT,
    weight_kg FLOAT,
    coach_name TEXT,
    nationality TEXT REFERENCES countries(country_code)
);

CREATE TABLE olympic_games (
    game_id SERIAL PRIMARY KEY,
    year INT,
    games_type TEXT,
    host_city TEXT
);

CREATE TABLE results (
    result_id SERIAL PRIMARY KEY,
    athlete_id TEXT REFERENCES athletes(athlete_id),
    sport TEXT,
    event TEXT,
    team_or_individual TEXT,
    medal TEXT,
    result_value TEXT,
    result_unit TEXT,
    is_record_holder BOOLEAN
);