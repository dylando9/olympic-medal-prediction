# Olympic Medal Prediction

End-to-end data science project for analyzing historical Olympic athlete data and building models to predict medal outcomes.

## Overview

This repository is structured to support a complete workflow:

1. Ingest raw Olympic data
2. Store and query structured data in PostgreSQL
3. Build modeling features
4. Train machine learning models for medal prediction

## Tech Stack

- Python
- PostgreSQL
- SQL
- Pandas
- scikit-learn
- Jupyter Notebook
- Kaggle API

## Project Structure

```text
olympic-medal-prediction/
├── data/
│   ├── raw/          # Original dataset (gitignored)
│   └── processed/    # Cleaned and transformed datasets
├── notebooks/        # Exploration and experimentation
├── reports/
│   └── figures/      # Visualizations
├── sql/              # Database schema and SQL queries
├── src/
│   ├── etl/          # Data ingestion and preprocessing scripts
│   ├── models/       # Model training and evaluation code
│   └── pipeline/     # End-to-end orchestration
├── requirements.txt
└── README.md
```

## Dataset

Source: Kaggle, Olympic Athletes Dataset (1896-2024)

The dataset includes:

- Athlete-level information
- Event participation history
- Country representation
- Medal outcomes

Raw files should be placed in `data/raw/` and are intentionally excluded from version control.

## Project Goals

1. Build a structured Olympic database in PostgreSQL
2. Analyze medal trends across countries and events
3. Engineer predictive features
4. Train and evaluate medal prediction models

## Pipeline (Planned)

`Kaggle dataset -> raw CSV ingestion -> PostgreSQL -> feature engineering -> model training -> medal prediction`

## Future Improvements

- Add dashboard-based result exploration
- Compare additional models (for example, XGBoost and Random Forest)
- Add a reusable feature store layer
- Expose predictions through an API
