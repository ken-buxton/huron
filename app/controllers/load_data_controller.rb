class LoadDataController < ApplicationController
  before_filter :authenticate
  
  def tasks
  end
  
  def doit
    # This should be replaced with a call to: ApplicationHelper.get_pg_conn_hash
    local = false
    if local then
      @conn_hash = {:host => "localhost", :port => 5434, :dbname => "huron", 
        :user => "huron", :password => "huron"}
    else
      @conn_hash = {:host => "ec2-107-21-226-77.compute-1.amazonaws.com", :port => 5432, :dbname => "dcft9m221v2bl3", 
        :user => "pxbabeplazivmj", :password => "IwJkBN74dJm5mlm7Th-6CH6ErD"}
    end
      
    @load_file_dir = File.expand_path("", "db/load_files")
    @dim_file_dir = File.expand_path("", "db/dim_load_files")
    @start_date = '2010-01-01'
    @end_date = '2014-04-30'

    @result = "Loaded:<br>"
    st = Time.now
    
    processing_mode = "All"   # All, One_step
    if processing_mode == "All" then
      doit_all
    elsif processing_mode == "One_step" then
      which, year_index, step_no = get_next_load_step
      one_step_at_a_time which, year_index, step_no
    end
    
    # ********************************************************************************
    # Show elapsed time
    et = Time.now
    @result += "<br>Total elapsed time: #{number_with_delimiter((et-st).round(3))} seconds<br>"
  end
  
  # ********************************************************************************
  # Everything past here is private
  private  
  
  def doit_all
    file_name = File.expand_path("", "db") + "/next_step.txt"
    File.open(file_name, "w") do |file|
      file.puts(1)  # force to begin at first step
    end
    
    begin
      which, year_index, step_no = get_next_load_step
      one_step_at_a_time which, year_index, step_no
    end until step_no == 7
  end
  
  def one_step_at_a_time(which, year_index, step_no)
    @result += "<br>Processing: #{which}, year index: #{year_index}<br>"
    
    if which == "load_dimensions_create_fact_tables" then
      load_dimensions_create_fact_tables
      create_indexes('dim')
      
    elsif which == "load_before_facts" then
      s = @start_date.gsub('-', '').to_i
      e = @end_date.gsub('-', '').to_i
      load_before_facts s, e
    elsif which == "index_before_facts" then
      create_indexes('fct_sales')
      
    elsif which == "load_after_facts" then
      load_after_facts
    elsif which == "index_after_facts" then
      create_indexes('fct_payments')
      create_indexes('fct_sales_sum')
      
    elsif which == "load_aggregates" then
      load_aggregates
    elsif which == "index_aggregates" then
      create_indexes('agg')
      create_indexes('dim_tran')
    end
  end
  
  def get_next_load_step()
    step_no = 0
    file_name = File.expand_path("", "db") + "/next_step.txt"
    File.open(file_name, "r") do |file|
      step_no = file.gets().to_i
    end
    
    which = ""; year_index = 0
    if step_no == 1 then
      which = "load_dimensions_create_fact_tables"; year_index = 0
      
    elsif step_no == 2 then
      which = "load_before_facts"; year_index = 0
    elsif step_no == 3 then
      which = "index_before_facts"; year_index = 0
      
    elsif step_no == 4 then
      which = "load_after_facts"; year_index = 0
    elsif step_no == 5 then
      which = "index_after_facts"; year_index = 0
      
    elsif step_no == 6 then
      which = "load_aggregates"; year_index = 0
    elsif step_no == 7 then
      which = "index_aggregates"; year_index = 0
    end

    old_step_no = step_no
    step_no += 1
    if step_no > 7 then
      step_no = 1
    end
    File.open(file_name, "w") do |file|
      file.puts(step_no)
    end
    
    [which, year_index, old_step_no]
  end

  # ********************************************************************************
  # Load dimensions only
  # ********************************************************************************
  def load_dimensions_create_fact_tables()
    @sep = ""
    
    # ********************************************************************************
    # Load dimension tables
    Dimension.select("table_name").each do |tbl| # table_name = 'dim_store'
      create_and_load_dimension_table tbl.table_name
    end
    
    # ********************************************************************************
    # Create fact tables: sales, payments, sales summary
    Fact.select("table_name").each do |tbl|
      create_fact_table tbl.table_name
    end
  end

  # ********************************************************************************
  # Load before facts
  # ********************************************************************************
  def load_before_facts(start_date, end_date)    
    @sep = ""
    st = Time.now
    
    # ********************************************************************************
    # Load fact tables: sales
    pg_conn = PG::Connection.new(@conn_hash)
    pg_conn.exec("select load_fct_sales(#{start_date}, #{end_date});")    # 120100101, 20131231
    pg_conn.close()
    et = Time.now
    @result += "#{@sep}fct_sales processing time: #{number_with_delimiter((et-st).round(3))}<br>"
  end

  # ********************************************************************************
  # Load after facts
  # ********************************************************************************
  def load_after_facts()    
    @sep = ""
    st = Time.now
    
    # ********************************************************************************
    # Load fact tables: sales
    pg_conn = PG::Connection.new(@conn_hash)
    pg_conn.exec("select load_fct_payments();")
    
    conn = ActiveRecord::Base.connection
    load_fct_sales_sum pg_conn, conn, 'fct_payments'
    
    pg_conn.close()
    conn.close()
    
    et = Time.now
    @result += "#{@sep}fct_payments and fct_sales_sum processing time: #{number_with_delimiter((et-st).round(3))}<br>"
  end

  # ********************************************************************************
  # Load aggregates
  # ********************************************************************************
  def load_aggregates()
    @sep = ""
        
    # ********************************************************************************
    # Create indexes for dim_transaction after transactions have been created
    create_indexes('dim_tran')
        
    # ********************************************************************************
    # Load aggregates
    st = Time.now
    Aggregate.select("aggregate_table_name").order("search_order").each do |tbl|
      create_and_load_agg_table tbl.aggregate_table_name
    end
    et = Time.now
    @result += "#{@sep}aggregates processing time: #{number_with_delimiter((et-st).round(3))}<br>"
  end


  # ********************************************************************************
  # ********************************************************************************
  # Method Index
  # ********************************************************************************
  # ********************************************************************************
  # Load Dimensions
  #   create_and_load_dimension_table (dimension)
  #   generic_load_dimension(dimension, sep, min_length)
  #   load_summary_dim(sum_dimension)
  #   load_date(dimension)
  #   get_days_holiday(month_name, day_num_of_week, day_num_in_month, cur_date, easter)
  #   easter_date(year_no)
  #
  # ********************************************************************************
  # Load Facts
  #   create_and_load_fact_table(fact)
  #   load_fct_sales(conn)
  #   load_fct_sales_sum(conn)
  #   get_rand_sales_qty()
  #   get_rand_dist_num(first_num, num_inc, first_rand, rand_mult, num_iters)
  #
  # ********************************************************************************
  # Load Aggregates
  #   create_and_load_agg_table(aggregate_table_name)
  #
  # ********************************************************************************
  # Utility Routines
  #   create_indexes(index_group)
  #   get_field_lists(dim_table)
  #   parse_line(line, method, sep)
  #   is_int?(num_str)
  #
  # ********************************************************************************
  # ********************************************************************************

  
  # ********************************************************************************
  # ********************************************************************************
  # Load Dimensions
  #   create_and_load_dimension_table (dimension)
  #   generic_load_dimension(dimension, sep, min_length)
  #   load_summary_dim(sum_dimension)
  #   load_date(dimension)
  #   get_days_holiday(month_name, day_num_of_week, day_num_in_month, cur_date, easter)
  #   easter_date(year_no)
  # ********************************************************************************
  # ********************************************************************************
  
  # ********************************************************************************
  # Create and load a named dimension table
  # 1. Generate the SQL for a "drop table"
  # 2. Generate the SQL for a "create table" using the dimensions 
  #    and dimension_fields tables
  # 3. Load the tables with example data
  # ********************************************************************************
  def create_and_load_dimension_table (dimension)
    st = Time.now
    # If there is a dimension table with this name
    res = Dimension.select("Count(*) cnt").where("table_name = '#{dimension}'")
    if res.first.cnt.to_i == 1 then
      # logger.debug "Count 1 " + dimension
      # If there is at least one field for this dimension
      res = DimensionField.select("Count(*) cnt").where("table_name = '#{dimension}'")
      if res.first.cnt.to_i >= 1 then
        # The sql to drop this dimension table
        drop_sql = "drop table if exists #{dimension};"
        # Start the sql to create this table
        create_sql = "create table if not exists #{dimension} ("
        sep = ""
        
        # For each field in this table
        DimensionField.select("field_name, compare_as, is_primary_key, data_type, max_length").
        where("table_name = '#{dimension}'").each do |rec|
          #is_null = "not null"
          is_null = "null"
          if rec.is_primary_key.to_s == "true" then 
            #is_null = "not null primary key" 
            #is_null = "not null primary key autoincrement" SQLite
            is_null = "" 
            data_type = "serial not null primary key" 
          else
            data_type = rec.data_type
            max_length = rec.max_length
            if data_type == 'varchar' then
              if max_length == 0 then
                data_type = 'text'
              else
                data_type += "(#{max_length})"
              end
            end
          end
            
          create_sql += %Q~#{sep}"#{rec.field_name}" #{data_type} #{is_null}~
          sep = ","
        end
        create_sql += ");"
        
        # Drop and re-create the dimension table
        rs = ActiveRecord::Base.connection.execute(drop_sql) 
        rs = ActiveRecord::Base.connection.execute(create_sql)
        
        ret = ""
        if dimension == "dim_date" then
          ret += load_date dimension
        elsif dimension == "dim_month" then
          ret += load_summary_dim dimension
          
        elsif dimension == "dim_product" then
          ret += generic_load_dimension dimension, '~', 10
        elsif dimension == "dim_sub_category" then
          ret += load_summary_dim dimension
          
        elsif dimension == "dim_store" then
          ret += generic_load_dimension dimension, '|', 10
        elsif dimension == "dim_district" then
          ret += load_summary_dim dimension
          
        elsif dimension == "dim_promotion" then
          ret += generic_load_dimension dimension, '|', 10
        elsif dimension == "dim_cashier" then
          ret += generic_load_dimension dimension, '|', 10
        elsif dimension == "dim_payment_method" then
          ret += generic_load_dimension dimension, '|', 10
        elsif dimension == "dim_transaction" then
          # The data for this dimension is created after the fact_sales table is created
          # because the data does not exist at this time.
          @result += "#{@sep} #{dimension} (#{0} records)"
          ret += ""
        end
        et = Time.now
        @result += " - #{number_with_delimiter((et-st).round(3))} seconds<br>"
        ret 
      
      end
    end
  end

  # ********************************************************************************
  # Generic load a dimension table 
  def generic_load_dimension(dimension, sep, min_length)
    sql_field_names, field_sizes, sql_question_list = get_field_lists dimension

    conn = PG::Connection.new(@conn_hash)
    conn.prepare("insert", "insert into #{dimension} (#{sql_field_names}) values(#{sql_question_list});")
    
    # raw_connection required if using prepare
    # conn = ActiveRecord::Base.connection.raw_connection
    # conn = ActiveRecord::Base.connection
    # st = conn.prepare("insert into #{dimension} (#{sql_field_names}) values(#{sql_question_list});")
    
    User.transaction do
      File.open("#{@dim_file_dir}/#{dimension}.txt", "r") do |prd_f|
          
        # Set up variables to add to the product table
        lines = prd_f.readlines
        lines_loaded = 0
        lines.each do |line|
          # Remove the line termination characters (/r, /n, /r/n)
          line.chomp!
          
          # Process the the current line if it doesn't begin with a comment character
          # and is at least the minimum length
          if line[0, 1] != '#' and line.length >= min_length then
            # Parse out this line into fields using the passed in separator character
            fields = parse_line line, "separator", sep
            
            # If the correct # of fields were returned
            if fields.length == field_sizes.length then          
              # st.execute( fields )   
              conn.exec_prepared("insert", fields)

              lines_loaded += 1 
            else
              logger.debug "Invalid # fields: " + fields.to_s
            end
          end
        end
        @result += "#{@sep} #{dimension} (#{number_with_delimiter(lines_loaded)} records)"

      end
    end
    conn.close()        
    ""
  end

  # ********************************************************************************
  def load_summary_dim(sum_dimension)
    conn = ActiveRecord::Base.connection
    Dimension.select("summary_sql").where("table_name = '#{sum_dimension}'").each do |row|
      conn.execute(row.summary_sql)
    end
    lines_loaded = conn.select_value("select count(*) cnt from #{sum_dimension}")

    @result += "#{@sep} #{sum_dimension} (#{number_with_delimiter(lines_loaded)} records)"
    ""
  end

  # ********************************************************************************
  # Load the date dimension table 
  def load_date(dimension)
    sql_field_names, field_sizes, sql_question_list = get_field_lists dimension   

    pg_conn = PG::Connection.new(@conn_hash)
    pg_conn.prepare("insert", "insert into #{dimension} (#{sql_field_names}) values(#{sql_question_list});")

    added_zero_rec = false
    User.transaction do
      days_cnt = 0
      days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      days_short = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
      months_short = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      cur_date = Time.local(@start_date[0..3].to_i, @start_date[5..6].to_i, @start_date[8..9].to_i)
      logger.debug cur_date
      cur_year = cur_date.year-1
      cur_month = 0
      month_no_overall = 0
      week_no_overall = 0
      day_no_overall = 1
      easter = easter_date(cur_year)
      end_date = Time.local(@end_date[0..3].to_i, @end_date[5..6].to_i, @end_date[8..9].to_i)
      logger.debug end_date
      lines_loaded = 0
      while cur_date <= end_date
        if cur_date.year != cur_year then
          cur_year = cur_date.year
          easter = easter_date(cur_year)
        end
        if cur_date.month != cur_month then
          cur_month = cur_date.month
          month_no_overall += 1
        end
        if week_no_overall == 0 or cur_date.wday == 0 then
          week_no_overall += 1
        end
        first_wday = Time.local(cur_date.year, 1, 1).wday
        
        # Set up variables to add to the time table
        time_key = cur_date.year * 10000 + cur_date.month * 100 + cur_date.day
        sql_date = time_key.to_s
        full_date_desc = cur_date.strftime("%a, %b %d, %Y")
        year_no = cur_date.year
        year_no_short = year_no % 100
        fiscal_year_no = cur_date.year
        fiscal_year_no_short = fiscal_year_no % 100
        quarter = (cur_date.month + 2) / 3
        quarter_code = "Q" + quarter.to_s
        trimester = (cur_date.month + 3) / 4
        trimester_code = "T" + trimester.to_s
        month_no = cur_date.month
        month_name = months[month_no-1]
        month_name_short = months_short[month_no-1]
        reverse_day_no = Date.new(year_no, month_no, -cur_date.day).day
        week_no_in_year = ((cur_date.yday - cur_date.wday) + 6 + first_wday)/7
        weekday_flag = if cur_date.wday >= 1 and cur_date.wday <= 5 then 'Yes' else 'No' end
        holiday = get_days_holiday(month_name_short, cur_date.wday, cur_date.day, cur_date, easter)
        is_holiday = if holiday == '' then 'No' else 'Yes' end
        
        if not added_zero_rec then
          # pg_conn.exec_prepared("insert", ["", "", "", "", 
            # "", "", "", "", 
            # "", "", "", "",
            # "", "", "", "",
            # "", "", "", "",
            # "", "", "", "",
            # "", ""])
          # st.execute(0, "", "", "", "", 
            # "", "", "", "", 
            # "", "", "", "",
            # "", "", "", "",
            # "", "", "", "",
            # "", "", "", "",
            # "", "")
            added_zero_rec = true
        end
        # st.execute(time_key, sql_date, full_date_desc, year_no, year_no_short, 
          # fiscal_year_no, fiscal_year_no_short, quarter, quarter_code, 
          # trimester, trimester_code, month_no, month_no_overall,
          # month_name, month_name_short, week_no_in_year, week_no_overall,
          # cur_date.day, cur_date.yday, day_no_overall, reverse_day_no,
          # cur_date.wday, days[cur_date.wday], days_short[cur_date.wday], weekday_flag,
          # is_holiday, holiday)

        pg_conn.exec_prepared("insert", [sql_date, full_date_desc, year_no, year_no_short, 
          fiscal_year_no, fiscal_year_no_short, quarter, quarter_code, 
          trimester, trimester_code, month_no, month_no_overall,
          month_name, month_name_short, week_no_in_year, week_no_overall,
          cur_date.day, cur_date.yday, day_no_overall, reverse_day_no,
          cur_date.wday, days[cur_date.wday], days_short[cur_date.wday], weekday_flag,
          is_holiday, holiday])
        
        
        day_no_overall += 1
        cur_date += 1.day
        days_cnt += 1
        lines_loaded += 1
      end
      @result += "#{@sep} #{dimension} (#{number_with_delimiter(lines_loaded)} records)"
    end
    pg_conn.close()        
    ""
  end
  
  # ********************************************************************************
  def get_days_holiday(month_name, day_num_of_week, day_num_in_month, cur_date, easter)
    holiday = ''
    # Check for Easter day
    if cur_date == easter then
     holiday = 'Easter'
    # Check for Memorial day (last Monday in May)
    elsif month_name == 'May' and day_num_of_week == 1 and day_num_in_month >= 25 then
      holiday = 'Memorial Day'
    # Check for July 4th
    elsif month_name == 'Jul' and day_num_in_month == 4 then
      holiday = 'July 4th'
    # Check for Labor day
    elsif month_name == 'Sep' and day_num_of_week == 1 and day_num_in_month <= 7 then
      holiday = 'Labor Day'
    # Check for Halloween
    elsif month_name == 'Oct' and day_num_in_month == 31 then
      holiday = 'Halloween'
    # Check for Thanksgiving
    elsif month_name == 'Nov' and day_num_of_week == 4 and (22..28).member? day_num_in_month then
      holiday = 'Thanksgiving'
    # Check for Christmas
    elsif month_name == 'Dec' and day_num_in_month == 25 then
      holiday = 'Christmas'
    end
    holiday
  end

  # ********************************************************************************
  def easter_date(year_no) # returns the easter date for the given year
    v_g = year_no % 19
    v_i = (19*v_g + 15) % 30
    v_j = (year_no + (year_no / 4) + v_i) % 7
    v_c = year_no / 100
    v_h = (v_c - v_c/4 - ((8*v_c + 13) / 25) + 19 * v_g + 15) % 30
    v_i = v_h - (v_h/28) * (1 - (29 / (v_h + 1)) * ((21 - v_g) / 11))
    v_j = (year_no + (year_no / 4) + v_i + 2 - v_c + v_c/4) % 7
    v_l = v_i - v_j
    v_emonth = 3 + ((v_l + 40) / 44)
    v_eday = v_l + 28 - 31 * (v_emonth / 4)
    Time.new(year_no, v_emonth, v_eday)
  end

  
  # ********************************************************************************
  # ********************************************************************************
  # Load Facts
  #   create_and_load_fact_table(fact)
  #   load_fct_sales(conn)
  #   load_fct_sales_sum(conn)
  #   get_rand_sales_qty()
  #   get_rand_dist_num(first_num, num_inc, first_rand, rand_mult, num_iters)
  # ********************************************************************************
  # ********************************************************************************

  
  # ********************************************************************************
  # Create and load a named fact table
  # 1. Generate the SQL for a "drop table"
  # 2. Generate the SQL for a "create table" using the facts 
  #    and fact_fields tables
  # 3. Load the tables with example data
  # ********************************************************************************
  def create_fact_table(fact)
    st = Time.now
    create_sql = ""
    res = Fact.select("Count(*) cnt").where("table_name = '#{fact}'")
    if res.first.cnt.to_i == 1 then
      res = FactField.select("Count(*) cnt").where("table_name = '#{fact}'")
      if res.first.cnt.to_i >= 1 then
        
        drop_sql = "drop table if exists #{fact};"
        create_sql += "create table if not exists #{fact} ("
        sep = ""
        FactField.select("field_name, field_type, data_type, max_length").
        where("table_name = '#{fact}'").each do |rec|
          is_null = "not null"
          if rec.field_type == "" then 
            # is_null = "integer not null primary key autoincrement" 
            is_null = "serial not null primary key"
          end
          data_type = rec.data_type
          max_length = rec.max_length
          if data_type == 'varchar' then
            if max_length == 0 then
              data_type = 'text'
            else
              data_type += "(#{max_length})"
            end
          end
            
          create_sql += "#{sep}#{rec.field_name} #{data_type} #{is_null}"
          sep = ","
        end
        create_sql += ");"
      
        # Drop and re-create the fact table
        rs = ActiveRecord::Base.connection.execute(drop_sql) 
        rs = ActiveRecord::Base.connection.execute(create_sql) 
           
        et = Time.now
        @result += "#{@sep}Create: #{fact} #{number_with_delimiter((et-st).round(3))} seconds<br>"
      end
    end
  end



  # ********************************************************************************
  # ********************************************************************************
  def load_fct_sales_sum(pg_conn, conn, table_name)
    lines_loaded = 0

    User.transaction do
      pg_conn.exec(
        'insert into fct_sales_sum (date_key, product_key, store_key, promotion_key,' +
        '   dollar_sales, unit_sales, dollar_cost, customer_count) ' +
        'select FS.date_key, FS.product_key, FS.store_key, FS.promotion_key, ' +
        '   Sum(ext_sales_amnt) "dollar_sales", ' +
        '   Sum(sales_qty) "unit_sales", ' +
        '   Avg(ext_cost_amnt/sales_qty) "dollar_cost", ' +
        '   Count(transaction_no) "customer_count" ' +
        'from fct_sales FS ' +
        '   inner join dim_date DD on FS.date_key = DD.date_key ' +
        '   inner join dim_product DP on FS.product_key = DP.product_key ' +
        '   inner join dim_store DS on FS.store_key = DS.store_key ' +
        '   inner join dim_promotion DPR on FS.promotion_key = DPR.promotion_key ' +
        'group by FS.date_key, FS.product_key, FS.store_key, FS.promotion_key ' +
        'order by FS.date_key, FS.product_key, FS.store_key, FS.promotion_key '
      )
    end
    lines_loaded = conn.select_value("select Count(*) cnt from #{table_name}")
  end
   
  def get_rand_sales_qty()
    get_rand_dist_num(1, 1, 0.4, 0.3, 8)
  end
  
  def get_rand_dist_num(first_num, num_inc, first_rand, rand_mult, num_iters) # get random distributed number
    rnd = rand()
    ret_num = first_num
    cur_range = first_rand
    while cur_range < rnd and num_iters > 0
      ret_num += num_inc
      cur_range += (1.0-cur_range) * rand_mult
      num_iters += -1
    end
    ret_num
    # (1..30).each { |x| p get_rand_dist_num(1, 1, 0.4, 0.3, 8) }
  end
  

  # ********************************************************************************
  # ********************************************************************************
  # Load Aggregates
  #   create_and_load_agg_table(aggregate_table_name)
  #
  # ********************************************************************************
  # ********************************************************************************
  
  # ********************************************************************************
  # Create and load a named aggregate table
  # 1. Generate the SQL for a "drop table"
  # 2. Generate the SQL for a "create table" using the facts 
  #    and fact_fields tables
  # 3. Load the tables with example data
  # ********************************************************************************
  def create_and_load_agg_table(aggregate_table_name)
    st = Time.now
    # The Insert/Select statement to load this aggregate table is built while we build the
    # SQL to create the table
    load_insert_list = ""
    load_select_list = ""
    load_from_clause = ""
    load_group_order_by_clause = ""
    
    create_sql = ""
    res = Aggregate.select("aggregate_table_name, fact_table_name, creation_sql").where("aggregate_table_name = '#{aggregate_table_name}'")
    if res.size.to_i == 1 then
      fact_table_name = res.first.fact_table_name
      creation_sql = res.first.creation_sql
      load_from_clause += fact_table_name + " "
      load_insert_list += "insert into #{aggregate_table_name} ("
      res = AggregateDetail.select("Count(*) cnt").where("aggregate_table_name = '#{aggregate_table_name}'")
      if res.first.cnt.to_i >= 1 then
        
        # ********************************************************************************
        # Build the SQL to drop and re-create the aggregate table
        drop_sql = "drop table if exists #{aggregate_table_name};"
        
        # The creation SQL gets information about the dimension keys from AggregateDetail
        # and information about the fact fields based on the defined fact table and its Fact
        # fields
        create_sql += "create table if not exists #{aggregate_table_name} ("
        
        # First, get all of the dimension key fields
        create_sql += "#{aggregate_table_name}_key serial primary key, "
        sep = ""
        AggregateDetail.select("aggregate_details.agg_dim_table, aggregate_details.parent_def, FF.field_name, FF.data_type ").
          joins("left join fact_fields FF on " + 
            "FF.dimension = aggregate_details.agg_dim_table " + 
            "and FF.field_type = 'Dimension'").
          where("aggregate_details.aggregate_table_name = '#{aggregate_table_name}' " + 
            " and (FF.table_name = '#{fact_table_name}' or FF.table_name is null)").
          order('aggregate_details."order"').
        each do |rec|
          is_null = "not null"
          data_type = rec.data_type
          if data_type == nil then
            data_type = "smallint"
          end
          field_name = rec.field_name
          if field_name == nil then
            field_name = rec.agg_dim_table[4..-1] + "_key"
          end
            
          create_sql += "#{sep}#{field_name} #{data_type} #{is_null}"
          load_insert_list += "#{sep} #{field_name}"
          load_select_list += "#{sep}#{rec.agg_dim_table}.#{field_name}"
          if rec.field_name != nil then
            load_from_clause += " inner join #{rec.agg_dim_table} on #{fact_table_name}.#{field_name} = #{rec.agg_dim_table}.#{field_name} "
          else
            load_from_clause += load_agg_join_through_parent(rec.parent_def, fact_table_name, rec.agg_dim_table)
          end
          load_group_order_by_clause += "#{sep}#{rec.agg_dim_table}.#{field_name}"
          sep = ","
        end
        
        # Next, get the fact values (measures)
        FactField.select("field_name, field_type, data_type, max_length, fact_type").
        where("table_name = '#{fact_table_name}' and field_type = 'Fact'").each do |rec|
          is_null = "not null"
          data_type = rec.data_type
          if rec.data_type == "smallint" and rec.fact_type == "Additive" then
            data_type = "integer"
          end
          max_length = rec.max_length
          if data_type == 'varchar' then
            if max_length == 0 then
              data_type = 'text'
            else
              data_type += "(#{max_length})"
            end
          end
            
          create_sql += "#{sep}#{rec.field_name} #{data_type} #{is_null}"
          sum_type = "Sum"
          if rec.fact_type != "Additive" then
            sum_type = "Min"
          end
          
          load_insert_list += "#{sep} #{rec.field_name}"
          load_select_list += "#{sep} #{sum_type}(#{fact_table_name}.#{rec.field_name})"
          sep = ","
        end
        
        # Now finish up
        create_sql += ");"
        load_insert_list += ")"
        
        load_sql = "#{load_insert_list} select #{load_select_list} from #{load_from_clause} "+ 
          " group by #{load_group_order_by_clause} order by #{load_group_order_by_clause}"

        # Drop and re-create the fact table
        rs = ActiveRecord::Base.connection.execute(drop_sql) 
        rs = ActiveRecord::Base.connection.execute(create_sql) 
        rs = ActiveRecord::Base.connection.execute(load_sql) 
        logger.debug load_sql
           
        # Count # rows added
        conn = ActiveRecord::Base.connection
        lines_loaded = conn.select_value("select Count(*) cnt from #{aggregate_table_name}")
        
        et = Time.now
        @result += "#{@sep}#{aggregate_table_name} (#{number_with_delimiter(lines_loaded)} records) - #{number_with_delimiter((et-st).round(3))} seconds<br>"
      end
    end
  end
  
  def load_agg_join_through_parent(parent_definition, fact_table, agg_dim_table)   
    # parent_definition="parent_dim_table,parent_dim_key,child_dim_key1,child_dim_key2"
    parent_dim_table, parent_dim_key, child_dim_key1, child_dim_key2 = parent_definition.split(",")
    ret = " inner join #{parent_dim_table} on #{fact_table}.#{parent_dim_key} = #{parent_dim_table}.#{parent_dim_key} "
    ret += " inner join #{agg_dim_table} on #{parent_dim_table}.#{child_dim_key1} = #{agg_dim_table}.#{child_dim_key1} "
    if child_dim_key2.length > 0 then
      ret += " and #{parent_dim_table}.#{child_dim_key2} = #{agg_dim_table}.#{child_dim_key2} "
    end
    ret    
  end

  
  # ********************************************************************************
  # ********************************************************************************
  # Utility Routines
  #   create_indexes(index_group)
  #   get_field_lists(dim_table)
  #   parse_line(line, method, sep)
  #   is_int?(num_str)
  # ********************************************************************************
  # ********************************************************************************
  # Create indexes for a named group of tables
  def create_indexes(index_group)
    conn = ActiveRecord::Base.connection
    st = Time.now
    
    # Begin transaction processing
    User.transaction do
      Index.select("creation_sql").where("group_name = '#{index_group}'").order("create_order").each do |sql|
        if sql.creation_sql > "" then
          index_command = sql.creation_sql.split(" ")
          drop_index = "drop index if exists #{index_command[2]};"
          conn.execute(drop_index)
          conn.execute(sql.creation_sql)
        end
      end
    end
    et = Time.now
    @result += "#{@sep}#{index_group} indexing time: #{number_with_delimiter((et-st).round(3))}<br>"
    
  end  
 
  # Get the field names, lengths, and sql replacement strings for a dimension table
  def get_field_lists(dim_table) # return [field_names, field_lengths, question_list]
    sql_names = ""
    field_lengths = []
    sql_question_list = ""
    sep = ""
    i = 1
    DimensionField.select("field_name, max_length").
        where("table_name = '#{dim_table}' AND is_primary_key = 'FALSE'").each do |rec|
      sql_names += sep + '"' + rec.field_name + '"'
      field_lengths << rec.max_length.to_i
      sql_question_list += sep + "$#{i}"
      sep = ", "
      i += 1
    end
    
    [sql_names, field_lengths, sql_question_list]
  end
 
  # Parse a line of text into an array of strings according to the passed in method
  def parse_line(line, method, sep) # returns an array of strings representing field values
    pos = 0
    fields = []
    if method == "separator" then
      start_pos = 0
      while pos <= line.length
        start_pos = pos
        while line[pos] != sep and pos < line.length
          pos += 1
        end
        fields << line[start_pos...pos].strip
        pos += 1
      end
    #elsif method == "csv"
    end
    fields
  end
  
  # Determine if a string is numeric
  def is_int?(num_str)
    !!(num_str =~ /^[-+]?[0-9]+$/)
  end
  
  def number_with_delimiter(number, delimiter=",", separator=".")
    begin
      parts = number.to_s.split(separator)
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      parts.join separator
    rescue
      number
    end
  end  

end
