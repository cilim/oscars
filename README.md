# Oscars Pool

Completely done by AI. Repository owner acted as client and product owner.

A prediction game for Oscar ceremonies. Friends compete by guessing winners across all categories, with a live scoreboard that updates in real-time during the ceremony.

## Service status

https://stats.uptimerobot.com/5JV0ZfkBxW

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

## How It Works

1. **Admin** creates categories (global, reusable) and seasons (yearly)
2. **Admin** assigns categories to a season, adds nominees, and adds players
3. **Players** make picks using the season's scoring scheme (pick types, points, single/multi-select rules)
4. **Admin** locks picks when the ceremony starts
5. On the **live scoreboard**, the admin selects winners as they're announced — all connected browsers update instantly via ActionCable

### Scoring schemes

Admins define reusable **scoring schemes** with one or more **pick types** (name, emoji, points if correct/incorrect, color, single vs multi-select). Each season uses one scheme.

The default **Classic** scheme matches the original rules:

| Pick type | Correct | Incorrect |
|-----------|---------|-----------|
| Think will win 🧠 | +5 | 0 |
| Want to win ❤️ | +2 | 0 |

Custom schemes can add penalty picks, multi-select types, and negative scores. Scoring is always a straight sum — no points cap. Schemes lock once player picks reference them.

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
  scoring_scheme: Classic   # optional; defaults to Classic

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
| `/admin/scoring_schemes` | Admin: manage scoring schemes |
| `/admin/categories` | Admin: manage categories |
| `/admin/seasons/:id` | Admin: manage nominees & players |
