# Oscars Pool

Completely done by AI. Repository owner acted as client and product owner.

A prediction game for Oscar ceremonies. Friends compete by guessing winners across all categories, with a live scoreboard that updates in real-time during the ceremony.

## Tech Stack

- Ruby 3.4.5
- Rails 8.1.2
- PostgreSQL 18
- Hotwire (Turbo + Stimulus) + ActionCable for real-time updates
- Tailwind CSS (dark theme with Oscar gold accents)
- RSpec for testing

## Setup

```bash
bin/setup                     # Install deps, create DB, run migrations
rails db:seed                 # Seed with sample data (2025 season + test users)
bin/dev                       # Start server + Tailwind watcher
```

**Default admin login:** `admin@oscars.com` / `password123`

## How It Works

1. **Admin** creates categories (global, reusable) and seasons (yearly)
2. **Admin** assigns categories to a season, adds nominees, and adds players
3. **Players** make picks for each category: "think will win" and "want to win"
4. **Admin** locks picks when the ceremony starts
5. On the **live scoreboard**, the admin selects winners as they're announced — all connected browsers update instantly via ActionCable

### Scoring

| Prediction | Points |
|-----------|--------|
| Correct "think will win" | 5 |
| Correct "want to win" | 2 |

## Rake Tasks

### Import a season from YAML

```bash
rails "oscars:import[2026]"
```

Reads `db/data/2026.yml` and creates the season, categories, and nominees. Idempotent — safe to run multiple times.

### Scrape oscars.org (for future years)

```bash
rails "oscars:scrape[2027]"
```

Fetches the nominations page from oscars.org, parses categories and nominees, and saves to `db/data/2027.yml`. Review the generated file, then import it.

Note: oscars.org may block automated requests (403). If so, create the YAML manually following the format in `db/data/2026.yml`.

### List available data files

```bash
rails oscars:list
```

Shows all YAML files in `db/data/` with category and nominee counts.

### YAML format

```yaml
season:
  name: "98th Academy Awards (2026)"
  year: 2026

categories:
  - name: Best Picture
    has_person: false
    nominees:
      - movie: Sinners
      - movie: Hamnet

  - name: Best Director
    has_person: true
    nominees:
      - person: Ryan Coogler
        movie: Sinners
```

`has_person` controls whether nominees have a person field (true for acting, directing, etc.; false for Best Picture, Best VFX, etc.).

## Tests

```bash
bundle exec rspec
```

63 specs covering models, request specs, and the scoreboard calculator service.

## Key Routes

| Path | Description |
|------|-------------|
| `/` | Season list (player home) |
| `/seasons/:id` | Season detail with your picks |
| `/seasons/:id/picks/edit` | Make/edit picks |
| `/seasons/:id/scoreboard` | Live scoreboard |
| `/admin/seasons` | Admin: manage seasons |
| `/admin/categories` | Admin: manage categories |
| `/admin/seasons/:id` | Admin: manage nominees & players |
