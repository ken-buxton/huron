class LoadAggsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin?
  
  def doit
    
    # ********************************************************************************
    # Load aggregate definitions
    # ********************************************************************************
    Aggregate.delete_all
    
    aggs = [
      # Agg Table name          Agg Display name                Fact table        Search    Creation SQL   Update SQL
      #                                                                           Order
      ["agg_sales_mn_sc_ds",    "Sales-Month-SubCat-District",  "fct_sales",      "01.0",   "",            ""  ],
      
      ["agg_sales_mn_sc_st",    "Sales-Month-SubCat-Store",     "fct_sales",      "02.1",   "",            ""  ],
      ["agg_sales_mn_pr_ds",    "Sales-Month-Prod-District",    "fct_sales",      "02.2",   "",            ""  ],
      ["agg_sales_dt_sc_ds",    "Sales-Date-SubCat-District",   "fct_sales",      "02.3",   "",            ""  ],
            
      ["agg_sales_mn_pr_st",    "Sales-Month-Prod-Store",       "fct_sales",      "03.1",   "",            ""  ],
      ["agg_sales_dt_sc_st",    "Sales-Date-SubCat-Store",      "fct_sales",      "03.2",   "",            ""  ],
      ["agg_sales_dt_pr_ds",    "Sales-Date-Prod-District",     "fct_sales",      "03.3",   "",            ""  ],
    ]
    
    Aggregate.transaction do
      aggs.each do |r|
        Aggregate.new do |f|
          f.aggregate_table_name = r[0]
          f.aggregate_display_name = r[1]
          f.fact_table_name = r[2]
          f.search_order = r[3]
          f.creation_sql = r[4]
          f.update_sql = r[5]
          f.save
        end
      end
    end
    
    
    # ********************************************************************************
    # Load aggregate dimension definitions
    # ********************************************************************************
    # rails generate scaffold AggregateDetail aggregate_table_name:string agg_dim_table:string order:string
    AggregateDetail.delete_all
    
    agg_detail = [
      # Aggregate table name        Dimension table       Order       Parent Definition
      # =>               
      #                                                               parent_dim_table,parent_dim_key,child_dim_key1,child_dim_key2
      # Single
      ["agg_sales_mn_pr_st",        "dim_month",          "01.0",     "dim_date,date_key,year_no,month_no"],
      ["agg_sales_mn_pr_st",        "dim_product",        "02.0",     ""],
      ["agg_sales_mn_pr_st",        "dim_store",          "03.0",     ""],
      
      ["agg_sales_dt_sc_st",        "dim_date",           "01.0",     ""],
      ["agg_sales_dt_sc_st",        "dim_sub_category",   "02.0",     "dim_product,product_key,category,sub_category"],
      ["agg_sales_dt_sc_st",        "dim_store",          "03.0",     ""],
      
      ["agg_sales_dt_pr_ds",        "dim_date",           "01.0",     ""],
      ["agg_sales_dt_pr_ds",        "dim_product",        "02.0",     ""],
      ["agg_sales_dt_pr_ds",        "dim_district",       "03.0",     "dim_store,store_key,region,district"],
      
      # Double
      ["agg_sales_mn_sc_st",        "dim_month",          "01.0",     "dim_date,date_key,year_no,month_no"],
      ["agg_sales_mn_sc_st",        "dim_sub_category",   "02.0",     "dim_product,product_key,category,sub_category"],
      ["agg_sales_mn_sc_st",        "dim_store",          "03.0",     ""],
      
      ["agg_sales_dt_sc_ds",        "dim_date",           "01.0",     ""],
      ["agg_sales_dt_sc_ds",        "dim_sub_category",   "02.0",     "dim_product,product_key,category,sub_category"],
      ["agg_sales_dt_sc_ds",        "dim_district",       "03.0",     "dim_store,store_key,region,district"],
      
      ["agg_sales_mn_pr_ds",        "dim_month",          "01.0",     "dim_date,date_key,year_no,month_no"],
      ["agg_sales_mn_pr_ds",        "dim_product",        "02.0",     ""],
      ["agg_sales_mn_pr_ds",        "dim_district",       "03.0",     "dim_store,store_key,region,district"],
      
      # Triple
      ["agg_sales_mn_sc_ds",        "dim_month",          "01.0",     "dim_date,date_key,year_no,month_no"],
      ["agg_sales_mn_sc_ds",        "dim_sub_category",   "02.0",     "dim_product,product_key,category,sub_category"],
      ["agg_sales_mn_sc_ds",        "dim_district",       "03.0",     "dim_store,store_key,region,district"]
      
    ]
    
    AggregateDetail.transaction do
      agg_detail.each do |r|
        AggregateDetail.new do |f|
          f.aggregate_table_name = r[0]
          f.agg_dim_table = r[1]
          f.order = r[2]
          f.parent_def = r[3]
          f.save
        end
      end
    end
    
    # rails generate migration AddParentDefToAggregateDetail parent_def:string
    
  end
end
