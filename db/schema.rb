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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140209214017) do

  create_table "agg_sales_dt_pr_ds", :primary_key => "agg_sales_dt_pr_ds_key", :force => true do |t|
    t.integer "date_key",              :limit => 2, :null => false
    t.integer "product_key",                        :null => false
    t.integer "district_key",          :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_dt_pr_ds", ["date_key", "product_key"], :name => "idx_agg_sales_dt_pr_ds"

  create_table "agg_sales_dt_sc_ds", :primary_key => "agg_sales_dt_sc_ds_key", :force => true do |t|
    t.integer "date_key",              :limit => 2, :null => false
    t.integer "sub_category_key",      :limit => 2, :null => false
    t.integer "district_key",          :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_dt_sc_ds", ["date_key", "sub_category_key"], :name => "idx_agg_sales_dt_sc_ds"

  create_table "agg_sales_dt_sc_st", :primary_key => "agg_sales_dt_sc_st_key", :force => true do |t|
    t.integer "date_key",              :limit => 2, :null => false
    t.integer "sub_category_key",      :limit => 2, :null => false
    t.integer "store_key",             :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_dt_sc_st", ["date_key", "sub_category_key"], :name => "idx_agg_sales_dt_sc_st"

  create_table "agg_sales_mn_pr_ds", :primary_key => "agg_sales_mn_pr_ds_key", :force => true do |t|
    t.integer "month_key",             :limit => 2, :null => false
    t.integer "product_key",                        :null => false
    t.integer "district_key",          :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_mn_pr_ds", ["month_key", "product_key"], :name => "idx_agg_sales_mn_pr_ds"

  create_table "agg_sales_mn_pr_st", :primary_key => "agg_sales_mn_pr_st_key", :force => true do |t|
    t.integer "month_key",             :limit => 2, :null => false
    t.integer "product_key",                        :null => false
    t.integer "store_key",             :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_mn_pr_st", ["month_key", "product_key"], :name => "idx_agg_sales_mn_pr_st"

  create_table "agg_sales_mn_sc_ds", :primary_key => "agg_sales_mn_sc_ds_key", :force => true do |t|
    t.integer "month_key",             :limit => 2, :null => false
    t.integer "sub_category_key",      :limit => 2, :null => false
    t.integer "district_key",          :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_mn_sc_ds", ["month_key", "sub_category_key"], :name => "idx_agg_sales_mn_sc_ds"

  create_table "agg_sales_mn_sc_st", :primary_key => "agg_sales_mn_sc_st_key", :force => true do |t|
    t.integer "month_key",             :limit => 2, :null => false
    t.integer "sub_category_key",      :limit => 2, :null => false
    t.integer "store_key",             :limit => 2, :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",                          :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "agg_sales_mn_sc_st", ["month_key", "sub_category_key"], :name => "idx_agg_sales_mn_sc_st"

  create_table "aggregate_details", :force => true do |t|
    t.text     "aggregate_table_name"
    t.text     "agg_dim_table"
    t.text     "order"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.text     "parent_def"
    t.text     "base_table"
  end

  create_table "aggregates", :force => true do |t|
    t.text     "aggregate_table_name"
    t.text     "aggregate_display_name"
    t.text     "fact_table_name"
    t.text     "search_order"
    t.text     "creation_sql"
    t.text     "update_sql"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "dim_cashier", :primary_key => "cashier_key", :force => true do |t|
    t.text "employee_no"
    t.text "emp_first_name"
    t.text "emp_last_name"
  end

  create_table "dim_date", :primary_key => "date_key", :force => true do |t|
    t.text "yyyymmdd_date"
    t.text "full_date_desc"
    t.text "year_no"
    t.text "year_no_short"
    t.text "fiscal_year_no"
    t.text "fiscal_year_no_short"
    t.text "quarter"
    t.text "quarter_code"
    t.text "trimester"
    t.text "trimester_code"
    t.text "month_no"
    t.text "month_no_overall"
    t.text "month_name"
    t.text "month_name_short"
    t.text "week_no"
    t.text "week_no_overall"
    t.text "day_no"
    t.text "day_no_in_year"
    t.text "day_no_overall"
    t.text "reverse_day_no"
    t.text "day_of_week_no"
    t.text "day_of_week"
    t.text "day_of_week_short"
    t.text "weekday_flag"
    t.text "is_holiday"
    t.text "holiday"
  end

  create_table "dim_district", :primary_key => "district_key", :force => true do |t|
    t.text "region"
    t.text "district"
  end

  create_table "dim_month", :primary_key => "month_key", :force => true do |t|
    t.text "year_month"
    t.text "year_no"
    t.text "month_no"
  end

  create_table "dim_payment_method", :primary_key => "payment_method_key", :force => true do |t|
    t.text "payment_method_desc"
    t.text "payment_method_group"
  end

  create_table "dim_product", :primary_key => "product_key", :force => true do |t|
    t.text "sku"
    t.text "sku_and_version"
    t.text "base_sku"
    t.text "upc"
    t.text "department"
    t.text "category"
    t.text "sub_category"
    t.text "description"
    t.text "brand"
    t.text "price"
    t.text "cost"
    t.text "coupon"
    t.text "promotion_level"
    t.text "unit_of_measure"
    t.text "weight"
    t.text "upc_contains_price"
    t.text "unit_pack"
    t.text "case_pack"
    t.text "layer_count"
    t.text "layers_per_pallet"
    t.text "pallet_height"
    t.text "pallet_width"
    t.text "pallet_depth"
    t.text "pallet_stack_count"
    t.text "pallet_package_type"
    t.text "gluten_free"
    t.text "fat_content"
    t.text "organic"
    t.text "sugar_content"
    t.text "cholesterol_content"
    t.text "natural"
    t.text "kosher"
    t.text "halal"
    t.text "country_origin"
    t.text "region_origin"
  end

  create_table "dim_promotion", :primary_key => "promotion_key", :force => true do |t|
    t.text "promotion_code"
    t.text "promotion_name"
    t.text "price_reduction_type"
    t.text "promotion_media_type"
    t.text "ad_type"
    t.text "display_type"
    t.text "coupon_type"
    t.text "ad_media_name"
    t.text "display_provider"
    t.text "promotion_cost"
    t.text "promotion_begin_date"
    t.text "promotion_end_date"
  end

  create_table "dim_store", :primary_key => "store_key", :force => true do |t|
    t.text "name"
    t.text "name_code"
    t.text "description"
    t.text "street_address1"
    t.text "street_address2"
    t.text "city"
    t.text "county"
    t.text "city_state"
    t.text "state"
    t.text "state_code"
    t.text "zip"
    t.text "region"
    t.text "district"
    t.text "square_footage"
    t.text "store_director"
    t.text "asst_store_mngr"
    t.text "grocery_mngr"
    t.text "deli_mngr"
    t.text "meat_mngr"
    t.text "seafood_mngr"
    t.text "dairy_mngr"
    t.text "hbc_mngr"
    t.text "produce_mngr"
    t.text "receiver"
    t.text "financial_services"
    t.text "photo_processing"
    t.text "dry_cleaning"
    t.text "first_opened_date"
    t.text "last_remodel_date"
    t.text "layout_type"
    t.text "grocery_sf"
    t.text "deli_sf"
    t.text "meat_sf"
    t.text "seafood_sf"
    t.text "dairy_sf"
    t.text "hbc_sf"
    t.text "produce_sf"
    t.text "tier"
    t.text "demographics"
    t.text "level"
    t.text "population_count"
    t.text "fax_number"
    t.text "gross_profit"
    t.text "gross_profit_goal"
    t.text "revenue"
  end

  create_table "dim_sub_category", :primary_key => "sub_category_key", :force => true do |t|
    t.text "department"
    t.text "category_sub"
    t.text "category"
    t.text "sub_category"
  end

  create_table "dim_transaction", :primary_key => "transaction_key", :force => true do |t|
    t.text "transaction_no"
    t.text "store_name"
    t.text "year_no"
    t.text "month_no"
    t.text "day_no"
    t.text "yyyymmdd_date"
    t.text "item_count"
  end

  add_index "dim_transaction", ["store_name"], :name => "idx_dim_transaction_st"
  add_index "dim_transaction", ["transaction_no"], :name => "idx_dim_transaction_tran_no"
  add_index "dim_transaction", ["year_no", "month_no", "day_no"], :name => "idx_dim_transaction_ymd"
  add_index "dim_transaction", ["yyyymmdd_date"], :name => "idx_dim_transaction_yyyymmdd"

  create_table "dimension_fields", :force => true do |t|
    t.text     "table_name"
    t.text     "field_name"
    t.text     "field_display_name"
    t.text     "display_order"
    t.text     "compare_as"
    t.boolean  "is_primary_key"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.text     "data_type"
    t.integer  "max_length"
    t.text     "special_sort"
  end

  create_table "dimensions", :force => true do |t|
    t.text     "table_name"
    t.text     "table_display_name"
    t.string   "display_order"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.boolean  "summary_dim"
    t.text     "summary_sql"
  end

  create_table "fact_fields", :force => true do |t|
    t.text     "table_name"
    t.text     "field_name"
    t.text     "field_display_name"
    t.text     "display_order"
    t.text     "field_type"
    t.text     "dimension"
    t.text     "fact_type"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.text     "data_type"
    t.integer  "max_length"
    t.text     "default_format"
  end

  create_table "facts", :force => true do |t|
    t.text     "table_name"
    t.text     "table_display_name"
    t.string   "display_order"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "fct_payments", :primary_key => "payment_fact_key", :force => true do |t|
    t.integer "date_key",           :limit => 2, :null => false
    t.integer "store_key",          :limit => 2, :null => false
    t.integer "payment_method_key", :limit => 2, :null => false
    t.integer "transaction_key",                 :null => false
    t.integer "payment_anount",                  :null => false
  end

  add_index "fct_payments", ["date_key", "store_key", "payment_method_key"], :name => "idx_fct_payments_dt_st_pm"

  create_table "fct_sales", :primary_key => "sales_fact_key", :force => true do |t|
    t.integer "date_key",              :limit => 2, :null => false
    t.integer "product_key",                        :null => false
    t.integer "store_key",             :limit => 2, :null => false
    t.integer "promotion_key",                      :null => false
    t.integer "cashier_key",           :limit => 2, :null => false
    t.integer "payment_method_key",    :limit => 2, :null => false
    t.integer "transaction_key",                    :null => false
    t.text    "transaction_no",                     :null => false
    t.integer "sales_qty",             :limit => 2, :null => false
    t.integer "reg_unit_price",        :limit => 2, :null => false
    t.integer "disc_unit_price",       :limit => 2, :null => false
    t.integer "net_unit_price",        :limit => 2, :null => false
    t.integer "ext_disc_amnt",                      :null => false
    t.integer "ext_sales_amnt",                     :null => false
    t.integer "ext_cost_amnt",                      :null => false
    t.integer "ext_gross_profit_amnt",              :null => false
  end

  add_index "fct_sales", ["date_key", "product_key"], :name => "idx_fct_sales_dt_pr"
  add_index "fct_sales", ["date_key", "store_key"], :name => "idx_fct_sales_dt_st"

  create_table "fct_sales_sum", :primary_key => "sales_sum_fact_key", :force => true do |t|
    t.integer "date_key",       :limit => 2, :null => false
    t.integer "product_key",                 :null => false
    t.integer "store_key",      :limit => 2, :null => false
    t.integer "promotion_key",               :null => false
    t.integer "dollar_sales",                :null => false
    t.integer "unit_sales",     :limit => 2, :null => false
    t.integer "dollar_cost",                 :null => false
    t.integer "customer_count",              :null => false
  end

  add_index "fct_sales_sum", ["date_key", "product_key"], :name => "idx_fct_sales_sum_dt_pr"
  add_index "fct_sales_sum", ["date_key", "store_key"], :name => "idx_fct_sales_sum_dt_st"

  create_table "indices", :force => true do |t|
    t.text     "group_name"
    t.text     "create_order"
    t.text     "creation_sql"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "logs", :force => true do |t|
    t.datetime "log_when"
    t.text     "log_what"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "reports", :force => true do |t|
    t.text     "report_name"
    t.text     "user_id"
    t.text     "private"
    t.text     "report_group"
    t.text     "dims"
    t.text     "rows"
    t.text     "columns"
    t.text     "facts"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "system_configurations", :force => true do |t|
    t.text     "page_title"
    t.text     "previous_load_status_msg"
    t.text     "welcome_msg"
    t.text     "daily_messages"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

end
