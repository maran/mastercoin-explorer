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

ActiveRecord::Schema.define(version: 20131112145420) do

  create_table "transaction_queues", force: true do |t|
    t.text     "json_payload"
    t.boolean  "sent",            default: false
    t.datetime "sent_at"
    t.string   "tx_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sent_blockchain", default: false
    t.boolean  "sent_eligius",    default: false
  end

  create_table "transactions", force: true do |t|
    t.string   "address"
    t.string   "receiving_address"
    t.integer  "transaction_type"
    t.integer  "currency_id"
    t.string   "tx_id"
    t.datetime "tx_date"
    t.integer  "block_height"
    t.decimal  "amount",                   precision: 18, scale: 8
    t.decimal  "bonus_amount_included",    precision: 18, scale: 8
    t.boolean  "is_exodus",                                         default: true
    t.string   "type"
    t.boolean  "invalid_tx",                                        default: false
    t.integer  "position"
    t.boolean  "multi_sig",                                         default: false
    t.decimal  "amount_desired",           precision: 18, scale: 8
    t.integer  "time_limit"
    t.decimal  "required_fee",             precision: 18, scale: 8
    t.decimal  "price_per_coin",           precision: 18, scale: 8
    t.boolean  "current"
    t.integer  "status"
    t.integer  "reference_transaction_id"
    t.decimal  "bitcoin_fee",              precision: 18, scale: 8
    t.decimal  "accepted_amount",          precision: 18, scale: 8
    t.integer  "app_position"
  end

end
