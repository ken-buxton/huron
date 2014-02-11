class LoadIndicesController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin
  
  def doit
    # ********************************************************************************
    # Load indices
    # ********************************************************************************
    Index.delete_all
    
    indices = [
      # Group           Create    Creation  SQL
      # Name            Order
      ["dim_tran",      "01.0",   "create index idx_dim_transaction_ymd on dim_transaction (year_no, month_no, day_no)"],
      ["dim_tran",      "02.0",   "create index idx_dim_transaction_tran_no on dim_transaction (transaction_no)"],
      ["dim_tran",      "03.0",   "create index idx_dim_transaction_st on dim_transaction (store_name)"],
      ["dim_tran",      "04.0",   "create index idx_dim_transaction_yyyymmdd on dim_transaction (yyyymmdd_date)"],
      
      ["fct_sales",     "01.0",   "create index idx_fct_sales_dt_pr on fct_sales (date_key, product_key)"],
      ["fct_sales",     "02.0",   "create index idx_fct_sales_dt_st on fct_sales (date_key, store_key)"],
      ["fct_payments",  "01.0",   "create index idx_fct_payments_dt_st_pm on fct_payments (date_key, store_key, payment_method_key)"],
      ["fct_sales_sum", "01.0",   "create index idx_fct_sales_sum_dt_pr on fct_sales_sum (date_key, product_key)"],
      ["fct_sales_sum", "02.0",   "create index idx_fct_sales_sum_dt_st on fct_sales_sum (date_key, store_key)"],
      
      ["agg",           "01.0",   "create index idx_agg_sales_mn_pr_st on agg_sales_mn_pr_st (month_key, product_key)"],
      ["agg",           "02.0",   "create index idx_agg_sales_dt_sc_st on agg_sales_dt_sc_st (date_key, sub_category_key)"],
      ["agg",           "03.0",   "create index idx_agg_sales_dt_pr_ds on agg_sales_dt_pr_ds (date_key, product_key)"],
      ["agg",           "04.0",   "create index idx_agg_sales_mn_sc_st on agg_sales_mn_sc_st (month_key, sub_category_key)"],
      ["agg",           "05.0",   "create index idx_agg_sales_dt_sc_ds on agg_sales_dt_sc_ds (date_key, sub_category_key)"],
      ["agg",           "06.0",   "create index idx_agg_sales_mn_pr_ds on agg_sales_mn_pr_ds (month_key, product_key)"],
      ["agg",           "07.0",   "create index idx_agg_sales_mn_sc_ds on agg_sales_mn_sc_ds (month_key, sub_category_key)"]
    ]

    Index.transaction do
      indices.each do |r|
        Index.new do |f|
          f.group_name = r[0]
          f.create_order = r[1]
          f.creation_sql = r[2]
          f.save
        end
      end
    end
    
  end
end
