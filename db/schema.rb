# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161215143201) do

  create_table "explore_queries", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,                        null: false
    t.string   "patt",           limit: 255
    t.string   "filter",         limit: 255
    t.string   "within",         limit: 255, default: "document"
    t.integer  "view",           limit: 4,   default: 1
    t.string   "listtype",       limit: 255, default: "word"
    t.integer  "ngram_size",     limit: 4,   default: 1
    t.string   "group",          limit: 255
    t.string   "sort",           limit: 255
    t.string   "order",          limit: 255
    t.integer  "status",         limit: 4,   default: 0
    t.integer  "export_status",  limit: 4,   default: 0
    t.integer  "offset",         limit: 4,   default: 0
    t.integer  "number",         limit: 4,   default: 50
    t.string   "input_page",     limit: 255
    t.integer  "hit_count",      limit: 4
    t.integer  "document_count", limit: 4
    t.integer  "group_count",    limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "explore_queries", ["created_at"], name: "index_explore_queries_on_created_at", using: :btree
  add_index "explore_queries", ["filter"], name: "index_explore_queries_on_filter", using: :btree
  add_index "explore_queries", ["input_page"], name: "index_explore_queries_on_input_page", using: :btree
  add_index "explore_queries", ["updated_at"], name: "index_explore_queries_on_updated_at", using: :btree
  add_index "explore_queries", ["user_id"], name: "index_explore_queries_on_user_id", using: :btree

  create_table "search_queries", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,                        null: false
    t.string   "patt",           limit: 255,                      null: false
    t.string   "filter",         limit: 255
    t.string   "within",         limit: 255, default: "document"
    t.integer  "view",           limit: 4,   default: 1
    t.string   "group",          limit: 255
    t.string   "sort",           limit: 255
    t.string   "order",          limit: 255
    t.integer  "status",         limit: 4,   default: 0
    t.integer  "export_status",  limit: 4,   default: 0
    t.integer  "offset",         limit: 4,   default: 0
    t.integer  "number",         limit: 4,   default: 50
    t.string   "input_page",     limit: 255, default: "expert"
    t.integer  "hit_count",      limit: 4
    t.integer  "document_count", limit: 4
    t.integer  "group_count",    limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "viewgroup",      limit: 255
  end

  add_index "search_queries", ["created_at"], name: "index_search_queries_on_created_at", using: :btree
  add_index "search_queries", ["filter"], name: "index_search_queries_on_filter", using: :btree
  add_index "search_queries", ["patt"], name: "index_search_queries_on_patt", using: :btree
  add_index "search_queries", ["updated_at"], name: "index_search_queries_on_updated_at", using: :btree
  add_index "search_queries", ["user_id"], name: "index_search_queries_on_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",           limit: 255,                null: false
    t.string   "session_id",     limit: 255
    t.string   "default_locale", limit: 255, default: "nl"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "users", ["name"], name: "index_users_on_name", using: :btree

end
