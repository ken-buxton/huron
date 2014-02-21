class LoadFactsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin?
  
  def doit
    Fact.delete_all
    
    facts = [
      # Table name      Display name      Display order
      ["fct_sales",       "Sales",          1.0],
      ["fct_payments",    "Payments",       2.0],
      ["fct_sales_sum",   "Sales Summary",  3.0]
    ]
    Fact.transaction do
      facts.each do |r|
        Fact.new do |f|
          f.table_name = r[0]
          f.table_display_name = r[1]
          f.display_order = ("00" + r[2].to_s)[-5,5]
          f.save
        end
      end
    end
    
    FactField.delete_all
    
    fields = [
      # Table           Field Name              Field Display         Display   Field         Dimension             Fact            Data Type   Max     Default
      # Name                                    Name                  Order     Type          Table Name            Type                        Length  Format
      # --------        ----------------------  --------------------  --------  ------------  --------------------  --------------  ----------  ------  ------------
      ["fct_sales",     "sales_fact_key",       "Sales Fact Key",         1.0,  "",           "",                   "",             "",           0,    ""],
      
      ["fct_sales",     "date_key",             "Date Key",               2.0,  "Dimension",  "dim_date",           "",             "smallint",   0,    ""],
      ["fct_sales",     "product_key",          "Product Key",            3.0,  "Dimension",  "dim_product",        "",             "integer",    0,    ""],
      ["fct_sales",     "store_key",            "Store Key",              4.0,  "Dimension",  "dim_store",          "",             "smallint",   0,    ""],
      ["fct_sales",     "promotion_key",        "Promotion Key",          5.0,  "Dimension",  "dim_promotion",      "",             "integer",    0,    ""],
      ["fct_sales",     "cashier_key",          "Cashier Key",            5.5,  "Dimension",  "dim_cashier",        "",             "smallint",   0,    ""],
      ["fct_sales",     "payment_method_key",   "Payment Method Key",     6.0,  "Dimension",  "dim_payment_method", "",             "smallint",   0,    ""],
      ["fct_sales",     "transaction_key",      "Transaction Key",        6.4,  "Dimension",  "dim_transaction",    "",             "integer",    0,    ""],
      
      ["fct_sales",     "transaction_no",       "Transaction #",          6.5,  "Fact",        "",                  "Non-additive", "text",       0,    "0#"   ],
      ["fct_sales",     "sales_qty",            "Sales Qty",              7.0,  "Fact",        "",                  "Additive",     "smallint",   0,    "0#,###"   ],
      ["fct_sales",     "reg_unit_price",       "Reg Unit Price",         8.0,  "Fact",        "",                  "Non-additive", "smallint",   0,    "$0#,###.##"],
      ["fct_sales",     "disc_unit_price",      "Disc Unit Price",        9.0,  "Fact",        "",                  "Non-additive", "smallint",   0,    "$0#,###.##"],
      ["fct_sales",     "net_unit_price",       "Net Unit Price",        10.0,  "Fact",        "",                  "Non-additive", "smallint",   0,    "$0#,###.##"],
      ["fct_sales",     "ext_disc_amnt",        "Ext Disc Amnt",         11.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      ["fct_sales",     "ext_sales_amnt",       "Ext Sales Amnt",        12.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      ["fct_sales",     "ext_cost_amnt",        "Ext Cost Amnt",         13.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      ["fct_sales",     "ext_gross_profit_amnt","Ext Gross Prft Amnt",   14.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      #                                                                                                              Note: fact types include:
      #                                                                                                              Additive, Semi-additive, and Non-additive
      # Table           Field Name              Field Display         Display   Field         Dimension             Fact            Data Type   Max     Default
      # Name                                    Name                  Order     Type          Table Name            Type                        Length  Format
      # --------        ----------------------  --------------------  --------  ------------  --------------------  --------------  ----------  ------  ------------
      ["fct_payments",  "payment_fact_key",     "Payment Fact Key",      21.0,  "",           "",                   "",             "",           0,    ""],

      ["fct_payments",  "date_key",             "Date Key",              22.0,  "Dimension",  "dim_date",           "",             "smallint",   0,    ""],
      ["fct_payments",  "store_key",            "Store Key",             23.0,  "Dimension",  "dim_store",          "",             "smallint",   0,    ""],
      ["fct_payments",  "payment_method_key",   "Payment Method Key",    24.0,  "Dimension",  "dim_payment_method", "",             "smallint",   0,    ""],
      ["fct_payments",  "transaction_key",      "Transaction Key",       25.0,  "Dimension",  "dim_transaction",    "",             "integer",    0,    ""],
      
      ["fct_payments",  "payment_anount",       "Payment Amount",        26.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      
      #                                                                                                              Note: fact types include:
      #                                                                                                              Additive, Semi-additive, and Non-additive
      # Table           Field Name              Field Display         Display   Field         Dimension             Fact            Data Type   Max     Default
      # Name                                    Name                  Order     Type          Table Name            Type                        Length  Format
      # --------        ----------------------  --------------------  --------  ------------  --------------------  --------------  ----------  ------  ------------
      ["fct_sales_sum", "sales_sum_fact_key",   "Sales Sum Fact Key",    31.0,  "",           "",                   "",             "",           0,    ""],
      
      ["fct_sales_sum", "date_key",             "Date Key",              32.0,  "Dimension",  "dim_date",           "",             "smallint",   0,    ""],
      ["fct_sales_sum", "product_key",          "Product Key",           33.0,  "Dimension",  "dim_product",        "",             "integer",    0,    ""],
      ["fct_sales_sum", "store_key",            "Store Key",             34.0,  "Dimension",  "dim_store",          "",             "smallint",   0,    ""],
      ["fct_sales_sum", "promotion_key",        "Promotion Key",         35.0,  "Dimension",  "dim_promotion",      "",             "integer",    0,    ""],
      
      ["fct_sales_sum", "dollar_sales",         "Dollar Sales",          36.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      ["fct_sales_sum", "unit_sales",           "Unit Sales",            37.0,  "Fact",        "",                  "Additive",     "smallint",   0,    "0#,###"   ],
      ["fct_sales_sum", "dollar_cost",          "Dollar Cost",           38.0,  "Fact",        "",                  "Additive",     "integer",    0,    "$0#,###.##"],
      ["fct_sales_sum", "customer_count",       "Customer Count",        39.0,  "Fact",        "",                  "Non-additive", "integer",    0,    "0#,###"]
      #                                                                                                              Note: fact types include:
      #                                                                                                              Additive, Semi-additive, and Non-additive
    ]
    FactField.transaction do
      fields.each do |r|
        FactField.new do |f|
          f.table_name = r[0]
          f.field_name = r[1]
          f.field_display_name = r[2]
          f.display_order = ("00" + r[3].to_s)[-5,5]
          f.field_type = r[4]
          f.dimension = r[5]
          f.fact_type = r[6]
          f.data_type = r[7]
          f.max_length = r[8]
          f.default_format = r[9]
          f.save
        end
      end
    end
    
  end
end
