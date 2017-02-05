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

ActiveRecord::Schema.define(version: 20170205212818) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "page_images", force: :cascade do |t|
    t.integer  "transcription_xml_id"
    t.integer  "transcription_json_paragraph_id"
    t.json     "image"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "patrons", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "user_name"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.string   "invited_by_type"
    t.integer  "invited_by_id"
    t.integer  "invitations_count",      default: 0
    t.index ["confirmation_token"], name: "index_patrons_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_patrons_on_email", unique: true, using: :btree
    t.index ["invitation_token"], name: "index_patrons_on_invitation_token", unique: true, using: :btree
    t.index ["invitations_count"], name: "index_patrons_on_invitations_count", using: :btree
    t.index ["invited_by_id"], name: "index_patrons_on_invited_by_id", using: :btree
    t.index ["reset_password_token"], name: "index_patrons_on_reset_password_token", unique: true, using: :btree
  end

  create_table "searches", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transcription_json_paragraphs", force: :cascade do |t|
    t.jsonb    "content"
    t.string   "title"
    t.string   "language"
    t.string   "date"
    t.integer  "transcription_xml_id"
    t.integer  "search_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "transcription_xmls", force: :cascade do |t|
    t.json     "xml"
    t.integer  "page_image_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_foreign_key "page_images", "transcription_json_paragraphs", on_delete: :cascade
  add_foreign_key "page_images", "transcription_xmls", on_delete: :cascade
  add_foreign_key "transcription_json_paragraphs", "searches", on_delete: :cascade
  add_foreign_key "transcription_json_paragraphs", "transcription_xmls", on_delete: :cascade
  add_foreign_key "transcription_xmls", "page_images", on_delete: :cascade
end
