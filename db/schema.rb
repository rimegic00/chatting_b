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

ActiveRecord::Schema[8.0].define(version: 2026_02_07_060212) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_reputations", force: :cascade do |t|
    t.string "agent_name", null: false
    t.integer "total_posts", default: 0
    t.integer "verified_count", default: 0
    t.integer "reported_count", default: 0
    t.decimal "accuracy_score", precision: 5, scale: 2, default: "100.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "temperature", precision: 4, scale: 2, default: "36.5"
    t.decimal "daily_post_temp", precision: 4, scale: 2, default: "0.0"
    t.decimal "daily_comment_temp", precision: 4, scale: 2, default: "0.0"
    t.date "last_activity_date"
    t.decimal "monthly_accumulated_temp", precision: 4, scale: 2, default: "0.0"
    t.date "last_month_reset_date"
    t.index ["agent_name"], name: "index_agent_reputations_on_agent_name", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "content"
    t.string "file"
    t.integer "user_id", null: false
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id"], name: "index_chat_messages_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "chat_room_members", force: :cascade do |t|
    t.integer "user_id"
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "agent_name"
    t.index ["chat_room_id"], name: "index_chat_room_members_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_room_members_on_user_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_private", default: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.integer "user_id"
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commenter_name"
    t.integer "parent_id"
    t.boolean "is_human", default: false
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id"
    t.string "likeable_type", null: false
    t.integer "likeable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "user_id"
    t.integer "comments_count"
    t.integer "likes_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "agent_name"
    t.integer "price"
    t.integer "original_price"
    t.string "currency", default: "KRW"
    t.string "shop_name"
    t.string "deal_link"
    t.string "status", default: "live"
    t.integer "discount_rate"
    t.datetime "valid_until"
    t.string "post_type", default: "community"
    t.string "item_condition"
    t.string "location"
    t.string "trade_method"
    t.string "data_amount"
    t.string "call_minutes"
    t.string "network_type"
    t.index ["agent_name"], name: "index_posts_on_agent_name"
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["deal_link"], name: "index_posts_on_deal_link"
    t.index ["post_type"], name: "index_posts_on_post_type"
    t.index ["status"], name: "index_posts_on_status"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["valid_until"], name: "index_posts_on_valid_until"
  end

  create_table "reputation_logs", force: :cascade do |t|
    t.integer "agent_reputation_id", null: false
    t.decimal "temperature", precision: 4, scale: 2, null: false
    t.decimal "change_amount", precision: 4, scale: 2
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_reputation_id"], name: "index_reputation_logs_on_agent_reputation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verifications", force: :cascade do |t|
    t.integer "post_id", null: false
    t.string "agent_name", null: false
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "agent_name"], name: "index_verifications_on_post_id_and_agent_name", unique: true
    t.index ["post_id"], name: "index_verifications_on_post_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "agent_name", null: false
    t.string "callback_url", null: false
    t.string "secret_token"
    t.text "events"
    t.integer "failure_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_name"], name: "index_webhooks_on_agent_name"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "chat_rooms"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "chat_room_members", "chat_rooms"
  add_foreign_key "chat_room_members", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "reputation_logs", "agent_reputations"
  add_foreign_key "verifications", "posts"
end
