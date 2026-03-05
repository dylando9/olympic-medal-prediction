import pandas as pd
from sqlalchemy import create_engine, text

DB_URL = "postgresql://localhost:5432/olympics_db"
CSV_PATH = "data/raw/olympics_athletes_dataset.csv"

def main():
    df = pd.read_csv(CSV_PATH)

    # basic cleanup
    df.columns = [c.strip() for c in df.columns]
    df["date_of_birth"] = pd.to_datetime(df["date_of_birth"], errors="coerce").dt.date

    engine = create_engine(DB_URL)

    with engine.begin() as conn:
        # Clear tables so script is re-runnable
        conn.execute(text("TRUNCATE TABLE results RESTART IDENTITY;"))
        conn.execute(text("TRUNCATE TABLE olympic_games RESTART IDENTITY CASCADE;"))
        conn.execute(text("TRUNCATE TABLE athletes CASCADE;"))
        conn.execute(text("TRUNCATE TABLE countries CASCADE;"))

    # ---- countries ----
    countries = (
        df[["nationality", "country_name", "country_first_participation", "country_best_rank",
            "country_total_gold", "country_total_medals"]]
        .drop_duplicates(subset=["nationality"])
        .rename(columns={
            "nationality": "country_code",
            "country_first_participation": "first_participation",
            "country_best_rank": "best_rank",
            "country_total_gold": "total_gold",
            "country_total_medals": "total_medals",
        })
    )
    countries.to_sql("countries", engine, if_exists="append", index=False)

    # ---- athletes ----
    athletes = (
        df[["athlete_id", "athlete_name", "gender", "date_of_birth", "height_cm", "weight_kg",
            "coach_name", "nationality"]]
        .drop_duplicates(subset=["athlete_id"])
        .rename(columns={"nationality": "nationality"})
    )
    athletes.to_sql("athletes", engine, if_exists="append", index=False)

    # ---- olympic_games ----
    games = (
        df[["year", "games_type", "host_city"]]
        .drop_duplicates()
        .reset_index(drop=True)
    )
    games.to_sql("olympic_games", engine, if_exists="append", index=False)

    # create a mapping from (year, games_type, host_city) -> game_id
    games_db = pd.read_sql("SELECT game_id, year, games_type, host_city FROM olympic_games", engine)
    df = df.merge(games_db, on=["year", "games_type", "host_city"], how="left")

    # ---- results ----
    results = df[[
        "athlete_id", "sport", "event", "team_or_individual", "medal",
        "result_value", "result_unit", "is_record_holder"
    ]].copy()

    # normalize boolean
    results["is_record_holder"] = results["is_record_holder"].astype(str).str.lower().isin(["true", "1", "yes", "y"])

    results.to_sql("results", engine, if_exists="append", index=False)

    print("Loaded tables:")
    with engine.connect() as conn:
        for t in ["countries", "athletes", "olympic_games", "results"]:
            n = conn.execute(text(f"SELECT COUNT(*) FROM {t}")).scalar()
            print(f"  {t}: {n:,}")

if __name__ == "__main__":
    main()