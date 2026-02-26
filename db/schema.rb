# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_25_202033) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "has_person", default: true, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "nominees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "movie_name", null: false
    t.string "person_name"
    t.bigint "season_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["season_category_id"], name: "index_nominees_on_season_category_id"
  end

  create_table "picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "player_id", null: false
    t.bigint "season_category_id", null: false
    t.bigint "think_will_win_id"
    t.datetime "updated_at", null: false
    t.bigint "want_to_win_id"
    t.index ["player_id", "season_category_id"], name: "index_picks_on_player_id_and_season_category_id", unique: true
    t.index ["player_id"], name: "index_picks_on_player_id"
    t.index ["season_category_id"], name: "index_picks_on_season_category_id"
    t.index ["think_will_win_id"], name: "index_picks_on_think_will_win_id"
    t.index ["want_to_win_id"], name: "index_picks_on_want_to_win_id"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["season_id"], name: "index_players_on_season_id"
    t.index ["user_id", "season_id"], name: "index_players_on_user_id_and_season_id", unique: true
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "season_categories", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_season_categories_on_category_id"
    t.index ["season_id", "category_id"], name: "index_season_categories_on_season_id_and_category_id", unique: true
    t.index ["season_id"], name: "index_season_categories_on_season_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "locked", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["name"], name: "index_seasons_on_name", unique: true
    t.index ["year"], name: "index_seasons_on_year", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "winners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "nominee_id", null: false
    t.bigint "season_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["nominee_id"], name: "index_winners_on_nominee_id"
    t.index ["season_category_id"], name: "index_winners_on_season_category_id", unique: true
  end

  add_foreign_key "nominees", "season_categories"
  add_foreign_key "picks", "nominees", column: "think_will_win_id"
  add_foreign_key "picks", "nominees", column: "want_to_win_id"
  add_foreign_key "picks", "players"
  add_foreign_key "picks", "season_categories"
  add_foreign_key "players", "seasons"
  add_foreign_key "players", "users"
  add_foreign_key "season_categories", "categories"
  add_foreign_key "season_categories", "seasons"
  add_foreign_key "sessions", "users"
  add_foreign_key "winners", "nominees"
  add_foreign_key "winners", "season_categories"
end
