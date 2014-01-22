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

ActiveRecord::Schema.define(version: 20140106105415) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addr", force: true do |t|
    t.text "hash160", null: false
  end

  add_index "addr", ["hash160"], name: "addr_hash160_index", using: :btree

  create_table "addr_txout", id: false, force: true do |t|
    t.integer "addr_id",  null: false
    t.integer "txout_id", null: false
  end

  add_index "addr_txout", ["addr_id"], name: "addr_txout_addr_id_index", using: :btree
  add_index "addr_txout", ["txout_id"], name: "addr_txout_txout_id_index", using: :btree

  create_table "addresses", force: true do |t|
    t.string   "name"
    t.decimal  "balance",               precision: 18, scale: 8, default: 0.0
    t.decimal  "test_balance",          precision: 18, scale: 8, default: 0.0
    t.decimal  "reserved_balance",      precision: 18, scale: 8, default: 0.0
    t.decimal  "reserved_test_balance", precision: 18, scale: 8, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blk", force: true do |t|
    t.binary  "hash",                null: false
    t.integer "depth",               null: false
    t.integer "version",   limit: 8, null: false
    t.binary  "prev_hash",           null: false
    t.binary  "mrkl_root",           null: false
    t.integer "time",      limit: 8, null: false
    t.integer "bits",      limit: 8, null: false
    t.integer "nonce",     limit: 8, null: false
    t.integer "blk_size",            null: false
    t.integer "chain",               null: false
    t.binary  "work"
    t.binary  "aux_pow"
  end

  add_index "blk", ["depth"], name: "blk_depth_index", using: :btree
  add_index "blk", ["hash"], name: "blk_hash_index", using: :btree
  add_index "blk", ["hash"], name: "blk_hash_key", unique: true, using: :btree
  add_index "blk", ["prev_hash"], name: "blk_prev_hash_index", using: :btree
  add_index "blk", ["work"], name: "blk_work_index", using: :btree

  create_table "blk_tx", id: false, force: true do |t|
    t.integer "blk_id", null: false
    t.integer "tx_id",  null: false
    t.integer "idx",    null: false
  end

  add_index "blk_tx", ["blk_id"], name: "blk_tx_blk_id_index", using: :btree
  add_index "blk_tx", ["tx_id"], name: "blk_tx_tx_id_index", using: :btree

  create_table "names", id: false, force: true do |t|
    t.integer "txout_id", null: false
    t.binary  "hash"
    t.binary  "name"
    t.binary  "value"
  end

  add_index "names", ["hash"], name: "names_hash_index", using: :btree
  add_index "names", ["name"], name: "names_name_index", using: :btree
  add_index "names", ["txout_id"], name: "names_txout_id_index", using: :btree

  create_table "reference_transactions", force: true do |t|
    t.integer   "transaction_id"
    t.decimal   "amount",            precision: 18, scale: 8
    t.string    "address"
    t.string    "receiving_address"
    t.integer   "block_height"
    t.timestamp "tx_date",           precision: 6
    t.integer   "currency_id"
    t.integer   "position"
    t.timestamp "created_at",        precision: 6
    t.timestamp "updated_at",        precision: 6
    t.string    "tx_id"
  end

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
    t.string    "address"
    t.string    "receiving_address"
    t.integer   "transaction_type"
    t.integer   "currency_id"
    t.string    "tx_id"
    t.timestamp "tx_date",                  precision: 6
    t.integer   "block_height"
    t.decimal   "amount",                   precision: 18, scale: 8
    t.decimal   "bonus_amount_included",    precision: 18, scale: 8
    t.boolean   "is_exodus",                                         default: true
    t.string    "type"
    t.boolean   "invalid_tx",                                        default: false
    t.integer   "position"
    t.boolean   "multi_sig",                                         default: false
    t.decimal   "amount_desired",           precision: 18, scale: 8
    t.integer   "time_limit"
    t.decimal   "required_fee",             precision: 18, scale: 8
    t.decimal   "price_per_coin",           precision: 18, scale: 8
    t.boolean   "current"
    t.integer   "status"
    t.integer   "reference_transaction_id"
    t.decimal   "bitcoin_fee",              precision: 18, scale: 8
    t.decimal   "accepted_amount",          precision: 18, scale: 8
    t.integer   "app_position"
    t.string    "payment_tx_id"
    t.decimal   "requested_amount",         precision: 18, scale: 8
    t.integer   "selling_offer_id"
    t.boolean   "revalidate",                                        default: false
  end

  create_table "tx", force: true do |t|
    t.binary  "hash",                null: false
    t.integer "version",   limit: 8, null: false
    t.integer "lock_time", limit: 8, null: false
    t.boolean "coinbase",            null: false
    t.integer "tx_size",             null: false
  end

  add_index "tx", ["hash"], name: "tx_hash_index", using: :btree
  add_index "tx", ["hash"], name: "tx_hash_key", unique: true, using: :btree

  create_table "txin", force: true do |t|
    t.integer "tx_id",                    null: false
    t.integer "tx_idx",                   null: false
    t.binary  "script_sig",               null: false
    t.binary  "prev_out",                 null: false
    t.integer "prev_out_index", limit: 8, null: false
    t.integer "sequence",       limit: 8, null: false
  end

  add_index "txin", ["prev_out"], name: "txin_prev_out_index", using: :btree
  add_index "txin", ["tx_id"], name: "txin_tx_id_index", using: :btree

  create_table "txout", force: true do |t|
    t.integer "tx_id",               null: false
    t.integer "tx_idx",              null: false
    t.binary  "pk_script",           null: false
    t.integer "value",     limit: 8
    t.integer "type",                null: false
  end

  add_index "txout", ["tx_id"], name: "txout_tx_id_index", using: :btree
  add_index "txout", ["type"], name: "txout_type_index", using: :btree

end
