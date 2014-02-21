class LoadDimsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin?
  
  def doit
    Dimension.delete_all
    
    month_SQL = 
      "insert into dim_month (year_month, year_no, month_no) " +
      "select year_no || '/' || right('0' || month_no, 2) year_month, year_no, month_no " +
      "from dim_date " + 
      "where year_no <> '' " +
      "group by year_no, month_no " + 
      "order by year_no, right('0' || month_no, 2)"    

    sub_category_SQL = 
      "insert into dim_sub_category (department, category_sub, category, sub_category) " + 
      "select department, category || '/' || sub_category category_sub, category, sub_category " + 
      "from dim_product " +
      "group by department, category, sub_category " + 
      "order by department, category, sub_category "

    district_SQL = 
      "insert into dim_district (region, district) " + 
      "select region, district from dim_store " +
      "group by region, district order by region, district"
    
    dims = [
      # Table             Display           Summary     Display   Summary SQL
      # Name              Name              Dimension?  Order
      # --------------    ----------------  -------     -------   -----------
      ["dim_date",          "Date",           false,    1.0,      ""],
      ["dim_month",         "Month",          true,     1.5,      month_SQL],
      ["dim_product",       "Product",        false,    2.0,      ""],
      ["dim_sub_category",  "Sub Category",   true,     2.5,      sub_category_SQL],
      ["dim_store",         "Store",          false,    3.0,      ""],
      ["dim_district",      "District",       true,     3.5,      district_SQL],
      ["dim_promotion",     "Promotion",      false,    4.0,      ""],
      ["dim_cashier",       "Cashier",        false,    5.0,      ""],
      ["dim_payment_method","Payment Method", false,    6.0,      ""],
      ["dim_transaction",   "Transaction",    false,    7.0,      ""]
    ]
    Dimension.transaction do
      dims.each do |r|
        Dimension.new do |d|
          d.table_name = r[0]
          d.table_display_name = r[1]
          d.summary_dim = r[2]
          d.display_order = ("00" + r[3].to_s)[-5,5]
          d.summary_sql = r[4]
          d.save
        end
      end
    end
    
    DimensionField.delete_all
    
    fields = [
      # Table                 Field Name              Field Display           Display   Compare     Is Primary  Data Type   Max     Special
      # Name                                          Name                    Order     As          Key                     Length  Sort
      # ----------------      ----------------------  ----------------------  --------  ----------  ----------  ---------   ------  --------------
      [ 'dim_date',           'date_key',             'Date Key',              1.0,     'Numeric',  true,       'integer',  0,      ""],
      [ 'dim_date',           'yyyymmdd_date',        'YYYYMMDD Date',         2.0,     'Date',     false,      'varchar',  0,      ""],
      [ 'dim_date',           'full_date_desc',       'Full Date',             3.0,     'Text',     false,      'varchar',  0,      "dim_date.yyyymmdd_date~yyyymmdd_date"],
      [ 'dim_date',           'year_no',              'Year',                  4.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'year_no_short',        'Year YY',               5.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'fiscal_year_no',       'Fiscal Year',           6.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'fiscal_year_no_short', 'Fiscal Year YY',        7.0,     'Numeric',  false,      'varchar',  0,      "dim_date.fiscal_year_no~fiscal_year_no"],
      [ 'dim_date',           'quarter',              'Quarter',               8.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'quarter_code',         'Quarter Code',          9.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_date',           'trimester',            'Trimester',            10.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'trimester_code',       'Trimester Code',       11.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_date',           'month_no',             'Month #',              12.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_date.month_no,2)~month_no"],
      [ 'dim_date',           'month_no_overall',     'Month # Overall',      13.0,     'Numeric',  false,      'varchar',  0,      "right('0000' || dim_date.month_no_overall,5)~month_no_overall"],
      [ 'dim_date',           'month_name',           'Month Name',           14.0,     'Text',     false,      'varchar',  0,      "right('0' || dim_date.month_no,2)~month_no"],
      [ 'dim_date',           'month_name_short',     'Month Name xxx',       15.0,     'Text',     false,      'varchar',  0,      "right('0' || dim_date.month_no,2)~month_no"],
      [ 'dim_date',           'week_no',              'Week #',               16.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_date.week_no,2)~week_no"],
      [ 'dim_date',           'week_no_overall',      'Week # Overall',       17.0,     'Numeric',  false,      'varchar',  0,      "right('00000' || dim_date.week_no_overall,6)~week_no_overall"],
      [ 'dim_date',           'day_no',               'Day #',                18.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_date.day_no,2)~day_no"],
      [ 'dim_date',           'day_no_in_year',       'Day # Year',           19.0,     'Numeric',  false,      'varchar',  0,      "right('00' || dim_date.day_no_in_year,3)~day_no_in_year"],
      [ 'dim_date',           'day_no_overall',       'Day # Overall',        20.0,     'Numeric',  false,      'varchar',  0,      "right('00000' || dim_date.day_no_overall,6)~day_no_overall"],
      [ 'dim_date',           'reverse_day_no',       'Reverse Day #',        21.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_date.reverse_day_no,2)~reverse_day_no"],
      [ 'dim_date',           'day_of_week_no',       'Day of Week #',        22.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_date',           'day_of_week',          'Day of Week',          23.0,     'Text',     false,      'varchar',  0,      "dim_date.day_of_week_no~day_of_week_no"],
      [ 'dim_date',           'day_of_week_short',    'Day of Week xxx',      24.0,     'Text',     false,      'varchar',  0,      "dim_date.day_of_week_no~day_of_week_no"],
      [ 'dim_date',           'weekday_flag',         'Weekday?',             25.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_date',           'is_holiday',           'Holiday?',             26.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_date',           'holiday',              'Holiday Name',         27.0,     'Text',     false,      'varchar',  0,      ""],

      [ 'dim_month',          'month_key',            'Month Key',             1.0,     'Numeric',  true,       'integer',  0,      ""],
      [ 'dim_month',          'year_month',           'Year/Month',            2.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_month',          'year_no',              'Year',                  2.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_month',          'month_no',             'Month #',               3.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_month.month_no,2)~month_no"],

      [ 'dim_product',        'product_key',          'Product Key',           1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_product',        'sku',                  'SKU',                   2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'sku_and_version',      'SKU Version',           3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'base_sku',             'Base SKU',              4.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'upc',                  'UPC',                   5.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'department',           'Department',            6.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'category',             'Category',              7.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'sub_category',         'Sub-category',          8.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'description',          'Description',           9.0,     'Text',     false,      'varchar',  0,      ""],   
      [ 'dim_product',        'brand',                'Brand',                10.0,     'Text',     false,      'varchar',  0,      ""],   
      [ 'dim_product',        'price',                'Price',                11.0,     'Numeric',  false,      'varchar',  0,      "dim_product.price::float*1.0~price"],  # dim_product.price*1.0
      [ 'dim_product',        'cost',                 'Cost',                 12.0,     'Numeric',  false,      'varchar',  0,      "dim_product.cost::float*1.0~cost"],      
      [ 'dim_product',        'coupon',               'Coupon',               13.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'promotion_level',      'Promotion Level',      14.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'unit_of_measure',      'UofM',                 15.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'weight',               'Weight',               16.0,     'Numeric',  false,      'varchar',  0,      "dim_product.weight::float*1.0~weight"],      
      [ 'dim_product',        'upc_contains_price',   'UPC has Price',        17.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'unit_pack',            'Unit Pack',            18.0,     'Numeric',  false,      'varchar',  0,      "dim_product.unit_pack::float*1.0~unit_pack"],      
      [ 'dim_product',        'case_pack',            'Case Pack',            19.0,     'Numeric',  false,      'varchar',  0,      "dim_product.case_pack::float*1.0~case_pack"],      
      [ 'dim_product',        'layer_count',          'Layer Count',          20.0,     'Numeric',  false,      'varchar',  0,      "dim_product.layer_count::float*1.0~layer_count"],      
      [ 'dim_product',        'layers_per_pallet',    'Layers/pallet',        21.0,     'Numeric',  false,      'varchar',  0,      "dim_product.layers_per_pallet::float*1.0~layers_per_pallet"],      
      [ 'dim_product',        'pallet_height',        'Pallet Height',        22.0,     'Numeric',  false,      'varchar',  0,      "dim_product.pallet_height::float*1.0~pallet_height"],      
      [ 'dim_product',        'pallet_width',         'Pallet Width',         23.0,     'Numeric',  false,      'varchar',  0,      "dim_product.pallet_width::float*1.0~pallet_width"],      
      [ 'dim_product',        'pallet_depth',         'Pallet Depth',         24.0,     'Numeric',  false,      'varchar',  0,      "dim_product.pallet_depth::float*1.0~pallet_depth"],      
      [ 'dim_product',        'pallet_stack_count',   'Pallet Stack Count',   25.0,     'Numeric',  false,      'varchar',  0,      "dim_product.pallet_stack_count::float*1.0~pallet_stack_count"],      
      [ 'dim_product',        'pallet_package_type',  'Pallet Package Type',  26.0,     'Numeric',  false,      'varchar',  0,      "dim_product.pallet_package_type::float*1.0~pallet_package_type"],
      [ 'dim_product',        'gluten_free',          'Gluten Free',          27.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'fat_content',          'Fat Content',          28.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'organic',              'Organic',              29.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'sugar_content',        'Sugar Content',        30.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'cholesterol_content',  'Cholesterol Content',  31.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'natural',              'Natural',              32.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'kosher',               'Kosher',               33.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'halal',                'Halal',                34.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'country_origin',       'Country Origin',       35.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_product',        'region_origin',        'Region Origin',        36.0,     'Text',     false,      'varchar',  0,      ""],   

      # Note: each sub_category_key is based on the unique combinations of department/category/sub_category
      [ 'dim_sub_category',   'sub_category_key',     'Sub Category Key',      1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_sub_category',   'department',           'Department',            2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_sub_category',   'category_sub',         'Category/Sub Category', 3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_sub_category',   'category',             'Category',              3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_sub_category',   'sub_category',         'Sub-category',          4.0,     'Text',     false,      'varchar',  0,      ""],      
         
      [ 'dim_store',          'store_key',            'store Key',             1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_store',          'name',                 'Name',                  2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'name_code',            'Name Code',             3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'description',          'Description',           4.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'street_address1',      'Street Address 1',      5.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'street_address2',      'Street Address 2',      6.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'city',                 'City',                  7.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'county',               'County',                8.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'city_state',           'City State',            9.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'state',                'State',                10.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'state_code',           'State Code',           11.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'zip',                  'Zip',                  12.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'region',               'Region',               13.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'district',             'District',             14.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'square_footage',       'Square Footage',       15.0,     'Numeric',  false,      'varchar',  0,      "dim_store.square_footage::float*1.0~square_footage"],      
      [ 'dim_store',          'store_director',       'Store Director',       16.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'asst_store_mngr',      'Asst Store Mngr',      17.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'grocery_mngr',         'Grocery Mngr',         18.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'deli_mngr',            'Deli Mngr',            20.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'meat_mngr',            'Meat Mngr',            21.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'seafood_mngr',         'Seafood Mngr',         22.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'dairy_mngr',           'Dairy Mngr',           23.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'hbc_mngr',             'HBC Mngr',             24.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'produce_mngr',         'Produce Mngr',         25.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'receiver',             'Receiver',             26.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'financial_services',   'Financial Services',   27.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'photo_processing',     'Photo Processing',     28.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'dry_cleaning',         'Dry Cleaning',         29.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'first_opened_date',    'First Opened Date',    30.0,     'Date',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'last_remodel_date',    'Last Remodel Date',    31.0,     'Date',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'layout_type',          'Layout Type',          32.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'grocery_sf',           'Grocery SF',           33.0,     'Numeric',  false,      'varchar',  0,      "dim_store.grocery_sf::float*1.0~grocery_sf"],      
      [ 'dim_store',          'deli_sf',              'Deli SF',              34.0,     'Numeric',  false,      'varchar',  0,      "dim_store.deli_sf::float*1.0~deli_sf"],      
      [ 'dim_store',          'meat_sf',              'Meat SF',              35.0,     'Numeric',  false,      'varchar',  0,      "dim_store.meat_sf::float*1.0~meat_sf"],      
      [ 'dim_store',          'seafood_sf',           'Seafood SF',           36.0,     'Numeric',  false,      'varchar',  0,      "dim_store.seafood_sf::float*1.0~seafood_sf"],      
      [ 'dim_store',          'dairy_sf',             'Dairy SF',             37.0,     'Numeric',  false,      'varchar',  0,      "dim_store.dairy_sf::float*1.0~dairy_sf"],      
      [ 'dim_store',          'hbc_sf',               'HBC SF',               38.0,     'Numeric',  false,      'varchar',  0,      "dim_store.hbc_sf::float*1.0~hbc_sf"],      
      [ 'dim_store',          'produce_sf',           'Produce SF',           39.0,     'Numeric',  false,      'varchar',  0,      "dim_store.produce_sf::float*1.0~produce_sf"],      
      [ 'dim_store',          'tier',                 'Tier',                 40.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'demographics',         'Demographics',         41.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'level',                'Level',                42.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'population_count',     'Population Count',     43.0,     'Numeric',  false,      'varchar',  0,      "dim_store.population_count::float*1.0~population_count"],      
      [ 'dim_store',          'fax_number',           'Fax #',                44.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_store',          'gross_profit',         'Gross Profit',         45.0,     'Numeric',  false,      'varchar',  0,      "dim_store.gross_profit::float*1.0~gross_profit"],      
      [ 'dim_store',          'gross_profit_goal',    'Gross Profit Goal',    46.0,     'Numeric',  false,      'varchar',  0,      "dim_store.gross_profit_goal::float*1.0~gross_profit_goal"],      
      [ 'dim_store',          'revenue',              'Revenue',              47.0,     'Numeric',  false,      'varchar',  0,      "dim_store.revenue::float*1.0~revenue"],          

      [ 'dim_district',       'district_key',         'District Key',          1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_district',       'region',               'Region',                2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_district',       'district',             'District',              3.0,     'Text',     false,      'varchar',  0,      ""],      


      [ 'dim_promotion',      'promotion_key',        'Promotion Key',         1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_promotion',      'promotion_code',       'Promotion Code',        2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'promotion_name',       'Promotion Name',        3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'price_reduction_type', 'Price Reduction Type',  4.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'promotion_media_type', 'Promotion Media Type',  5.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'ad_type',              'Ad Type',               6.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'display_type',         'Display Type',          7.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'coupon_type',          'Coupon Type',           8.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'ad_media_name',        'Ad Media Name',         9.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'display_provider',     'Display Provider',     10.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'promotion_cost',       'Promotion Cost',       11.0,     'Numeric',  false,      'varchar',  0,      "dim_promotion.promotion_cost::float*1.0~promotion_cost"],      
      [ 'dim_promotion',      'promotion_begin_date', 'Promotion Begin Date', 12.0,     'Date',     false,      'varchar',  0,      ""],      
      [ 'dim_promotion',      'promotion_end_date',   'Promotion End Date',   13.0,     'Date',     false,      'varchar',  0,      ""],      

      [ 'dim_payment_method', 'payment_method_key',   'Payment Method Key',    1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_payment_method', 'payment_method_desc',  'Payment Method Desc',   2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_payment_method', 'payment_method_group', 'Payment Method Group',  3.0,     'Text',     false,      'varchar',  0,      ""],

      [ 'dim_cashier',        'cashier_key',          'Cashier Key',           1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_cashier',        'employee_no',          'Employee #',            2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_cashier',        'emp_first_name',       'Employee First Name',   3.0,     'Text',     false,      'varchar',  0,      ""],
      [ 'dim_cashier',        'emp_last_name',        'Employee Last Name',    4.0,     'Text',     false,      'varchar',  0,      ""],

      [ 'dim_transaction',    'transaction_key',      'Transaction Key',       1.0,     'Text',     true,       'integer',  0,      ""],      
      [ 'dim_transaction',    'transaction_no',       'Transaction #',         2.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_transaction',    'store_name',           'Store Name',            3.0,     'Text',     false,      'varchar',  0,      ""],      
      [ 'dim_transaction',    'year_no',              'Year',                  4.0,     'Numeric',  false,      'varchar',  0,      ""],
      [ 'dim_transaction',    'month_no',             'Month #',               5.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_transaction.month_no,2)~month_no"],
      [ 'dim_transaction',    'day_no',               'Day #',                 6.0,     'Numeric',  false,      'varchar',  0,      "right('0' || dim_transaction.day_no,2)~day_no"],
      [ 'dim_transaction',    'yyyymmdd_date',        'YYYYMMDD Date',         7.0,     'Date',     false,      'varchar',  0,      ""],      
      [ 'dim_transaction',    'item_count',           'Item Count',            8.0,     'Text',     false,      'varchar',  0,      "right('000000' || dim_transaction.item_count,7)~item_count"],

    ]
    DimensionField.transaction do
      fields.each do |r|
        DimensionField.new do |f|
          f.table_name = r[0]
          f.field_name = r[1]
          f.field_display_name = r[2]
          f.display_order = ("00" + r[3].to_s)[-5,5]
          f.compare_as = r[4]
          f.is_primary_key = r[5]
          f.data_type = r[6]
          f.max_length = r[7]
          f.special_sort = r[8]
          f.save
        end
      end
    end
    
  end
end
