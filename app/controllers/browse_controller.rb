class BrowseController < ApplicationController
  before_filter :authenticate
  
  # Assume all methods private. Specifically declare public methods with public method
  private
  
  # ********************************************************************************
  # ********************************************************************************
  # Display initial browse screen
  # ********************************************************************************
  # ********************************************************************************
  def index
    # Make the page title availalbe
    @page_title = SystemConfiguration.select('page_title').first
    @user = '"' + current_user.login + '"'
    
    # Make the list of dimensions available
    @dimensions = Dimension.select('*').order('display_order')    
    @dimension_fields = DimensionField.select('*').order('table_name, display_order')    
    
    # Make the list of facts available
    @facts = Fact.select('*').order('display_order')
    @fact_fields = FactField.select('*').order('table_name, display_order')
    

    # Create dimension and fact lists to be passed to Javascript    
    @dim_tables_list = create_list(@dimensions, ["table_name"], 
      ["table_name", "table_display_name", "display_order"])
    @dim_fields_list = create_list(@dimension_fields, 
      ["table_name", "field_name"], 
      ["table_name", "field_name", "field_display_name", "display_order", "compare_as", "is_primary_key", 
        "data_type", "max_length", "special_sort"])
        
    @fact_tables_list = create_list(@facts, ["table_name"], 
      ["table_name", "table_display_name", "display_order"])
    @fact_fields_list = create_list(@fact_fields, 
      ["table_name", "field_name"], 
      ["table_name", "field_name", "field_display_name", "display_order", "field_type", "dimension", 
        "fact_type", "data_type", "max_length", "default_format"])

  end
  public :index
  
  # ********************************************************************************
  def create_list(iter, key_fields, value_fields)
    list = "{\n        "
    list_sep = ""
    iter.each do |item|
      # format the key
      key = '"'
      key_sep = ""
      key_fields.each do |fld|
        key += key_sep + item[fld].to_s
        key_sep = "."
      end
      key += '"'
      
      # format the value
      value = "{"
      value_sep = ""
      value_fields.each do |fld|
        value += value_sep + fld + ": " + '"' + item[fld].to_s + '"'
        value_sep = ", "
      end
      value += "}"
      
      list += "#{list_sep}#{key}: #{value} \n"
      list_sep = "      , "
    end
    list += "    };"
  end
   
  # ********************************************************************************
  # ********************************************************************************
  # browse/get ajax request - splits into following request types:
  #   dimension, fact, report
  # ********************************************************************************
  # ********************************************************************************
  def get
    @no_show_nav = "yes"
    # Get the request type: Dimension, Fact, Report
    req_type = params["req_type"]
    who = params["who"]
    req = params["req"]
    begin
      @dont_execute_sql = req[:dont_execute_sql]
    rescue
      @dont_execute_sql = "false"
    end
    begin
      @no_timeout = req[:no_timeout]
    rescue
      @no_timeout = "false"
    end
    
    seq_scan = "SET ENABLE_SEQSCAN TO OFF;"
    # seq_scan = ""
    if @no_timeout == "true" then
      @set_statement_timeout = "set statement_timeout to 0; #{seq_scan}"
    else
      @set_statement_timeout = "set statement_timeout to 10000; #{seq_scan}"
    end
    @reset_statement_timeout = "set statement_timeout to 0;"
    
    
    # Build @dims hash
    @dims = {}
    Dimension.select('table_name, table_display_name').each do |f|
      @dims[f.table_name] = {table_name: f.table_name, table_display_name: f.table_display_name}
    end

    # Build @dims hash
    @dim_fields = {}
    DimensionField.select('table_name, field_name, field_display_name, special_sort').each do |f|
      @dim_fields[[f.table_name, f.field_name]] = {field_display_name: f.field_display_name, special_sort: f.special_sort}
    end

    # ********************************************************************************
    # Check for the all_dimensions list    
    if req_type == "dimension" and who == "all_dimensions" then
      @get = ''


    # ********************************************************************************
    # Request to display the fields for dimension table            
    elsif req_type == "dimension" and who == "dim_fact_matrix" then
      get_dim_fact_matrix(who, req)      

    # ********************************************************************************
    # Request to display the fields for dimension table            
    elsif req_type == "dimension" then
      get_dim(who, req)      

    # ********************************************************************************
    # Request to display the fields for a Fact table        
    elsif req_type == "fact" then
      get_fact(who, req)
        
    # ********************************************************************************
    # Request to "open/save/save as" a report
    # elsif req_type == "open_save" then
      # get_open_save(who, req)
        
    # ********************************************************************************
    # Request to display one of the request reports
    elsif req_type == "report" then
      start_time = Time.now
      get_report(who, req)
      end_time = Time.now
      #seconds = ((end_time - start_time)*1000).to_i/1000.0
      seconds = (end_time - start_time).round(3).to_s
      @get = "<b>Elapsed time: #{seconds} seconds</b> (" + "Request time: " + Time.now.to_s + ")<br>" +
        "<b># of rows: #{@num_rows}</b> " + " (Fact table: #{@agg_fact_table} )<br><p style='font-size: 5pt'></p>" + 
        #'<hr style="width:97%; height:3px;">' + 
        @get
      
    # ********************************************************************************
    # Invalid request detected
    else
      @get = "<h2>?</h2>"
    end
  end
  public :get
  
  
  def get_json
    # Get the request type: Dimension, Fact, Report
    req_type = params["req_type"]
    who = params["who"]
    req = params["req"]
    
    @get = ""
    if req_type == "open_save" then
      get_open_save(who, req)
    end
    render :json => @get
        
  end
  public :get_json

  
  # ********************************************************************************
  # ********************************************************************************
  # Report Open/Save/Save AS Routines
  # ********************************************************************************
  # ********************************************************************************
  def get_open_save(who, req)
    if who == "open1" or who == "open2" then
      open_save_open(who, req)
    elsif who == "save" then
      open_save_save_as(req)
    elsif who == "save_as" then
      open_save_save_as(req)
    elsif who == "delete_report" then
      open_save_delete_report(req)
    elsif who == "report_group" then
      open_save_report_group(req)
    end
  end
  
  
  # ********************************************************************************
  # Open
  #  1) Client: if a report is currently open or the user has entered some report definition information - 
  #             confirm that they are OK to discard that information (if not - exit process)
  #  2) Client: send request to server for list of reports to open (user)
  #  3) Server: put together list of reports available to user and send to client
  #  4) Client: receive and display returned list
  #  5) User:   user selects report to open
  #  6) Client: send request for desired report to server (user, group, report name)
  #  7) Server: pulls the information for that report and returns to client 
  #             (user, group, report name, [dimensions, row, columns, facts])
  #  8) Client: a) clear out old report information
  #             b) load opened report information into dimensions, rows, columns, and facts
  #             c) Call routine that is called when the "All Report Fields" button is clicked.
  def open_save_open(who, req)
    user = ""; if req["user"] then user = req["user"]; end    
    group = ""; if req["group"] then group = req["group"]; end 
    if who == "open1" then
      s = "{"
      idx = 1
      Report.select('distinct report_name').where("report_group = '#{group}'").order("report_name").each do |f|
          
        sidx = ("000" + idx.to_s)[-3..-1]
        entry = %Q~"#{sidx}": "#{f.report_name}",~
        s += entry;      
        idx += 1
      end
      s[-1,1] = "}"
      @get += s
      
    elsif who == "open2" then
      s = "{"
      idx = 1
      report = ""; if req["report"] then report = req["report"]; end    
      Report.select('dims, rows, columns, facts').
          where("user_id = '#{user}' and report_group = '#{group}' and report_name = '#{report}'").each do |f|
        if idx < 2 then
          s += %Q~"dims": #{f.dims.to_json},~    
          s += %Q~"rows": #{f.rows.to_json},~    
          s += %Q~"columns": #{f.columns.to_json},~    
          s += %Q~"facts": #{f.facts.to_json}~    
          s += "}"
        end
        idx += 1
      end
      @get += s.to_json
    end
  end

  # ********************************************************************************
  # Save
  #  Case A - there is currently a report open
  #    1) Client: a) format information about the current report 
  #                  (user, group, report name, [dimensions, row, columns, facts])
  #               b) Send the formatted request to the server.
  #    2) Server: a) save the formatted information about the current report in the Reports table
  #               b) send confirmation to the client
  #    3) Client: display confirmation message on screen.
  #     
  #  Case B - there is NOT currently a report open
  #    1) Revert to "Save As" functionality

  # ********************************************************************************
  # Save As
  #  Case A - there is currently a report open
  #  Case B - there is NOT currently a report open
  #  In any case - it doesn't matter - we are saving a new report
  #   
  #  1) Client: prompt user for group name and report name (showing current group and report name if available)
  #  2) Client: a) format information about the current report 
  #                (user, group, report name, [dimensions, row, columns, facts])
  #             b) Send the formatted request to the server.
  #  3) Server: a) save the formatted information about the current report in the Reports table
  #             b) send confirmation to the client
  #  4) Client: display confirmation message on screen.
  def open_save_save_as(req)
    user = ""; if req["user"] then user = req["user"]; end    
    group = ""; if req["group"] then group = req["group"]; end    
    report = ""; if req["report"] then report = req["report"]; end    
        
    dims = {}; if req["dims"] then dims = req["dims"]; end        
    rows = {}; if req["rows"] then rows = req["rows"]; end        
    columns = {}; if req["columns"] then columns = req["columns"]; end        
    facts = {}; if req["facts"] then facts = req["facts"]; end
    
    save_new_report user, group, report, dims, rows, columns, facts
    
    @get = '{"1": "Success"}'
    
  end

  def save_new_report(user, group, report, dims, rows, columns, facts)
    updated = false
    Report.select("id").where("user_id = '#{user}' and report_group = '#{group}' and report_name = '#{report}'").each do |rep|
      rep.dims = dims.to_s
      rep.rows = rows.to_s
      rep.columns = columns.to_s
      rep.facts = facts.to_s
      rep.save
      updated = true
    end
    if not updated then
      r = Report.create(:report_name => report, :user_id => user, :private => "no", :report_group => group, 
                        :dims => dims.to_s, :rows => rows.to_s, :columns => columns.to_s, :facts => facts.to_s)
    end
  end

  # ********************************************************************************
  # Delete Report
  def open_save_delete_report(req)
    user = ""; if req["user"] then user = req["user"]; end    
    group = ""; if req["group"] then group = req["group"]; end    
    report = ""; if req["report"] then report = req["report"]; end    

    r = Report.select("id").where("user_id = '#{user}' and report_group = '#{group}' and report_name = '#{report}'")
    r.destroy r[0][:id].to_i
    
    @get = '{"1": "Success"}'
  end
  

  # ********************************************************************************
  # Set Report Group
  #   1) Client: send request to server for a list of valid groups
  #   2) Format list of returned groups into an array of string items
  #   3) Call a function to format the groups into an HTML table
  #   4) Format the HTML into a pre-allocated DIV made for this function
  def open_save_report_group(req)
    s = "{"
    idx = 1
    Report.select('distinct report_group, upper(report_group)').order("upper(report_group)").each do |f|
      sidx = ("000" + idx.to_s)[-3..-1]
      entry = %Q~"#{sidx}": "#{f.report_group}",~
      s += entry;      
      idx += 1
    end
    s[-1,1] = "}"
    @get += s
  end

  

  # ********************************************************************************
  # ********************************************************************************
  # Report Results Generation Routines
  # ********************************************************************************
  # ********************************************************************************
  
  # ********************************************************************************
  # get_report
  #   who = main
  #   req = {
  #     dims: dim_data,               # all dimensions that have constraints
  #     rows: row_header_data,        # all existing row headers: [ [table, field, sort, ctrl-break, header-name], ...]
  #     columns: column_header_data,  # all existing column headers: [ [table, field, sort, ctrl-break, header-name], ...]
  #     facts: fact_fields            # all fact fields: [ [row, table, field, sort, sum-type, header-name, calculation, format, display?], ...]
  #     show_request:                 # "true" or "false"
  #     show_sql:                     # "true" or "false"
  #   }
  # ********************************************************************************
  def get_report(who, req)
    # @get = "<p>Report: who = #{who}, req = #{req.to_s}, time = #{Time.now}</p>"
    show_request = req[:show_request]
    show_sql = req[:show_sql]
    
    @get = ""
    
    begin
      dims = {}; if req["dims"] then dims = req["dims"]; end        
      rows = {}; if req["rows"] then rows = req["rows"]; end        
      columns = {}; if req["columns"] then columns = req["columns"]; end        
      facts = {}; if req["facts"] then facts = req["facts"]; end
      g = "dims: #{dims.to_s}<br>rows: #{rows.to_s}<br>" +
          "columns: #{columns.to_s}<br>" +
          "facts: #{facts.to_s}<br>" +
          "time: #{Time.now}<br><hr>"
    rescue Exception
      g = "Error displaying request data"
    end
    
    if show_request == "true" then
      @get += g
    end
          
    # ********************************************************************************
    # Build the SQL
    # ********************************************************************************
    # Determine the base table or aggregate table based on dims, rows, columns, and facts arrays
    
    # break out into different types of reports
    # if this report has only row headers (no column headers or fact entries)
    @agg_fact_table = ""
    if facts.size > 0 then
      @agg_fact_table = aggregate_navigator(dims, rows, columns, facts)
    end
    # logger.info "@agg_fact_table=#{@agg_fact_table}"

    if facts.size == 0 then    
      if rows.size > 0 and columns.size == 0 and facts.size == 0 then
        format_rows_only_report req, dims, rows, show_sql
      
      elsif rows.size == 0 and columns.size > 0 and facts.size == 0 then
        format_columns_only_report req, dims, columns, show_sql
      else
        @get = "You have not selected anything to display<br>(no row headers, column headers, or facts.)"
      end
      
    else
      
      if @agg_fact_table.length > 0 then
        if rows.size > 0 and columns.size == 0 and facts.size > 0 then
          format_rows_and_facts_only_report req, @agg_fact_table, dims, rows, facts, show_sql
          
        elsif rows.size == 0 and columns.size > 0 and facts.size > 0 then
          format_columns_and_facts_only_report req, @agg_fact_table, dims, columns, facts, show_sql
          
        elsif rows.size > 0 and columns.size > 0 and facts.size > 0 then
          format_rows_and_columns_and_facts_report req, @agg_fact_table, dims, rows, columns, facts, show_sql
          
        else
          @get = "You have not selected anything to display<br>(no row headers, column headers, or facts.)"
        end
      else
        @get = "No fact or aggregate table was found to satisfy your request."
      end
    end

  end
  
  # ********************************************************************************
  def aggregate_navigator(dims, rows, columns, facts)
    # Determine our base fact table
    fact_table_list = []
    facts.each do |fct_key, fct_val|
      fact_table_list << fct_val[1] # fact table name
    end
    fact_table_list.uniq!  # make list unique
    fact_table = fact_table_list[0]
    
    # If more than one fact table, return with error
    if fact_table_list.size > 1 then
      return ""
    end
    
    # Determine the dimensions used in this requet (for a constraint, row, or column)
    used_dims = get_used_dimensions(dims, rows, columns)
    
    # See if an aggregate table matches our request
    Aggregate.select("aggregate_table_name").where("fact_table_name = '#{fact_table}'").order("search_order").each do |agg|
      agg_dims = []
      AggregateDetail.select("agg_dim_table").where("aggregate_table_name = '#{agg.aggregate_table_name}'").each do |agg_dtl|
        agg_dims << agg_dtl.agg_dim_table
      end
      agg_dims.sort!
      
      if agg_match_found(used_dims, agg_dims) then
        return agg.aggregate_table_name
      end
    end
    
    
    # No aggregate matches - see if base table matches
    fact_dims = []
    FactField.select("dimension").where("table_name = '#{fact_table}' and field_type = 'Dimension'").each do |fct_dim|
      fact_dims << fct_dim.dimension
    end
    fact_dims.sort!
    if agg_match_found(used_dims, fact_dims) then
      return fact_table
    end
  
    return ""
  end
  
  # ********************************************************************************
  def get_used_dimensions(dims, rows, columns)
    used_dims = []
    dims.each { |k, v| used_dims << k }
    rows.each { |k, v| used_dims << v[0] }
    columns.each { |k, v| used_dims << v[0] }
    used_dims.uniq.sort
  end
  
  # ********************************************************************************
  def agg_match_found(used_dims, agg_dims)
    agg_match_pos = 0
    used_dims.each do |udim|
      while udim != agg_dims[agg_match_pos] and agg_match_pos < agg_dims.length
        agg_match_pos += 1
      end
      if agg_match_pos >= agg_dims.length then
        return false
      end
    end
    return true
  end
  
  # ********************************************************************************
  # Top level report format routines:
  #  1) format_rows_only_report                 (dims, rows,                 show_sql)
  #  2) format_columns_only_report              (dims,       columns,        show_sql)
  #  3) format_rows_and_facts_only_report       (dims, rows,          facts, show_sql)
  #  4) format_columns_and_facts_only_report    (dims,       columns, facts, show_sql)
  #  5) format_rows_and_columns_and_facts_report(dims, rows, columns, facts, show_sql)
  # ********************************************************************************
  
  # ********************************************************************************
  # format_rows_only_report (a report with only row headers - no column headers or fact entries)
  def format_rows_only_report(req, dims, rows, show_sql)
    # Format the select by and order by list
    facts = []
    outer_select_list, inner_select_list, group_by_list, order_by_list, format_list, ctrl_brk_list = 
      format_select_group_order_by_list("", rows, facts, false)
    
    # Format the from list (each table only once)
    from_list = format_from_list("", dims, rows, [], facts)

    # Format the where clause
    where_list = format_where_clause("", dims, facts)

    # Format the display and executable SQL
    display_sql, execute_sql = 
      format_the_SQL_for_display_and_execute(
        outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)

    # Display the SQL if it's wanted
    if show_sql == "true"
      @get += display_sql + "<br><hr>"
    end
    # Execute the SQL and display the returned result set
    if @dont_execute_sql == "false" then
      begin
        @get += report_title(req, dims)
        @get += execute_and_display_results("Row", execute_sql, format_list, ctrl_brk_list, rows, facts)
      rescue => ex
        @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      end
    end
    # @get += "<br>Control breaks: #{ctrl_brk_list.to_s}"
  end
  
  def build_query_error_message(ex)
    #msg = "Class=#{ex.class}, "
    #logger.debug ex.message.split(" : ").to_s
    msg = "<b>Message: </b>" + ex.message.split("\n: ")[0]
  end
  
  def report_title(req, dims)
    dim_html = ""
    dim_sep = ""
    # For each dimension table the user has populated (e.g. Date, Month, Product, Store, etc.)
    dims.each do |key, val|
      dim_html += dim_sep + "<b>" + @dims[key][:table_display_name] + "</b>: "
      
      idx = 0
      count = 0
      atr_sep = ""
      # For each dimension attribute (e.g. Year, Month #, Day #)
      # Note: dimension arrays come from the browser as hashes indexed by numeric strings. So
      # we must convert the index to a numeric string.
      while val[idx.to_s]
        atr_list = val[idx.to_s]
        # atr_list is ["attribute name", "expression", "value1", "value2", ...]
        atr_name = atr_list[0]
        atr_expr = atr_list[1]
        dim_html += atr_sep + "<u>" + @dim_fields[[key, atr_name]][:field_display_name] + "</u>: "
        if atr_expr != "" then
          dim_html += " [#{atr_expr}] "
        end
        atr_list_idx = 2
        dim_html += " ("
        val_sep = ""
        while atr_list[atr_list_idx]
          dim_html += val_sep + atr_list[atr_list_idx].to_s
          val_sep = ", "
          atr_list_idx += 1
        end
        dim_html += ")"
        idx += 1
        atr_sep = ", "
      end
      dim_sep = ";<br>"
    end
    %Q~<div style="text-align:left; font-size:125%; color: blue; font-weight: bold">#{req[:report_name]} (#{req[:report_group]})</div>~ +
    %Q~<div style="text-align:left; font-size:100%;">#{dim_html}</div>~
  end
    
  # ********************************************************************************
  # format_columns_only_report (a report with only column headers - no row headers or fact entries)
  def format_columns_only_report(req, dims, columns, show_sql)
    # Format the select by and order by list
    facts = []
    outer_select_list, inner_select_list, group_by_list, order_by_list, format_list, ctrl_brk_list = 
      format_select_group_order_by_list("", columns, facts, false)
    
    # Format the from list (each table only once)
    from_list = format_from_list("", dims, [], columns, facts)

    # Format the where clause
    where_list = format_where_clause("", dims, facts)

    # Format the display and executable SQL
    display_sql, execute_sql = 
      format_the_SQL_for_display_and_execute(
        outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)

    # Display the SQL if it's wanted
    if show_sql == "true"
      @get += display_sql + "<br><hr>"
    end

    # Execute the SQL and display the returned result set
    if @dont_execute_sql == "false" then
      begin
        @get += report_title(req, dims)
        @get += execute_and_display_results("Column", execute_sql, format_list, ctrl_brk_list, columns, facts)
      rescue => ex
        @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      end
    end
    # @get += "<br>Control breaks: #{ctrl_brk_list.to_s}"
  end

  # ********************************************************************************
  # format_rows_and_facts_only_report (a report with only row headers and facts - no column headers)
  def format_rows_and_facts_only_report(req, agg_fact_table, dims, rows, facts, show_sql)
    # Format the select by and order by list
    outer_select_list, inner_select_list, group_by_list, order_by_list, format_list, ctrl_brk_list = 
      format_select_group_order_by_list(agg_fact_table, rows, facts, false)
    
    # Format the from list (each table only once)
    from_list = format_from_list(agg_fact_table, dims, rows, [], facts)

    # Format the where clause
    where_list = format_where_clause(agg_fact_table, dims, facts)

    # Format the display and executable SQL
    display_sql, execute_sql = 
      format_the_SQL_for_display_and_execute(
        outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)

    # Display the SQL if it's wanted
    if show_sql == "true"
      @get += display_sql + "<br><hr>"
    end

    # Execute the SQL and display the returned result set
    if @dont_execute_sql == "false" then
      begin
        @get += report_title(req, dims)
        @get += execute_and_display_results("Row", execute_sql, format_list, ctrl_brk_list, rows, facts)
      rescue => ex
        @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      end
    end
    # @get += "<br>Control breaks: #{ctrl_brk_list.to_s}"
  end
    
  # ********************************************************************************
  # format_columns_and_facts_only_report (a report with only column headers and facts - no row headers)
  def format_columns_and_facts_only_report(req, agg_fact_table, dims, columns, facts, show_sql)
    # Format the select by and order by list
    outer_select_list, inner_select_list, group_by_list, order_by_list, format_list, ctrl_brk_list = 
      format_select_group_order_by_list(agg_fact_table, columns, facts, false)
    
    # Format the from list (each table only once)
    from_list = format_from_list(agg_fact_table, dims, [], columns, facts)

    # Format the where clause
    where_list = format_where_clause(agg_fact_table, dims, facts)

    # Format the display and executable SQL
    display_sql, execute_sql = 
      format_the_SQL_for_display_and_execute(
        outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)

    # Display the SQL if it's wanted
    if show_sql == "true"
      @get += display_sql + "<br><hr>"
    end

    # Execute the SQL and display the returned result set
    if @dont_execute_sql == "false" then
      begin
        @get += report_title(req, dims)
        @get += execute_and_display_results("Column", execute_sql, format_list, ctrl_brk_list, columns, facts)
      rescue => ex
        @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      end
    end
    # @get += "<br>Control breaks: #{ctrl_brk_list.to_s}"
  end

  # ********************************************************************************
  # format_rows_and_columns_and_facts_report (a report with all possible)
  def format_rows_and_columns_and_facts_report(req, agg_fact_table, dims, rows, columns, facts, show_sql)
    # Make sure at least one fact field is flagged to be displayed
    fact_display_cnt = 0
    facts.each do |fact_key, fact|
      if fact[8] == "Yes" then
        fact_display_cnt += 1
      end
    end
    if fact_display_cnt <= 0 then
      @get += "You must include at least one fact field that is flagged to be displayed."
      return
    end
    
    # ***** Build the select to pick the column headers
    column_header_data_select = 
      build_column_header_data_select(agg_fact_table, dims, columns, facts)


    begin
      outer_column_header_select, inner_column_header_select, column_headers, format_list = 
        build_column_header_select(agg_fact_table, column_header_data_select, facts, columns, rows)
    rescue => ex
      @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      return
    end
      
    

    # Format the select by and order by list
    outer_select_list, inner_select_list, group_by_list, order_by_list, format_list_dummy, ctrl_brk_list = 
      format_select_group_order_by_list(agg_fact_table, rows, [], false)
    if inner_column_header_select.length > 0 then
      inner_select_list += inner_column_header_select
    end
    if outer_column_header_select.length > 0 then
      outer_select_list += outer_column_header_select
    end
    
    # Format the from list (each table only once)
    from_list = format_from_list(agg_fact_table, dims, rows, columns, facts)

    # Format the where clause
    where_list = format_where_clause(agg_fact_table, dims, facts)

    # Format the display and executable SQL
    display_sql, execute_sql = format_the_SQL_for_display_and_execute(
      outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)

    # Display the SQL if it's wanted
    if show_sql == "true"
      @get += display_sql + "<br><hr>"
    end

    # Execute the SQL and display the returned result set
    # @get += column_headers.to_s + "<br>"
    # @get += format_list.to_s + "<br>"
    if @dont_execute_sql == "false" then
      begin
        @get += report_title(req, dims)
        @get += execute_and_display_row_column_results(execute_sql, format_list, ctrl_brk_list, rows, facts, column_headers)
      rescue => ex
        @get += "Unable to retrieve requested data.<br>" + build_query_error_message(ex)
      end
    end
    
    # @get += column_header_select
  end
  
  def build_column_header_select(agg_fact_table, column_header_data_select, facts, columns, rows)
    conn = ActiveRecord::Base.connection
    rs_dummy = conn.select_all(@set_statement_timeout)
    rs = conn.select_all(column_header_data_select)
    rs_dummy = conn.select_all(@reset_statement_timeout)

    # Format the final select list 
    # @get += "<br>"
    column_headers = []
    build_format_list = true
    format_list = []
    (0..(columns.size)).each do |col_no|
      cur_row = []
      rows.each do |row_key, row|
        if col_no < columns.size then
          cur_row << ""
        else
          cur_row << "<b>#{row[4]}</b>"
        end
        if build_format_list then
          format_list << ""
        end
      end
      if col_no < columns.size then
        cur_row << "<b>#{columns[col_no.to_s][4]}</b>"
      else
        cur_row << ""
      end
      if build_format_list then
        format_list << ""
      end
      build_format_list = false
      column_headers << cur_row
    end
      
    outer_col_select = %Q~, '' "10000"~
    inner_col_select = %Q~, '' "10000"~
    field_no = 10001
    # for each column header
    rs.each do |row_data|         # hash of field=>value for current row
      # for each fact
      facts.each do |fact_key, fact_item|   # [row_letter, fact_table, fact_field, sort, sum_type, header_name, calculation, format, display?]
        format_list << fact_item[7]
        # if this fact is displayable
        if fact_item[8] == "Yes" then
          # Coalesce with an eventual "0" turns a null result into a zero
          inner_col_select += ", Coalesce(#{if fact_item[4] == 'Cnt' then 'Count' else fact_item[4] end}(case when "
          and_sep = ""
          col_no = 0
          columns.each do |item_key, col|   # table, field, sort, ctrl_brk, header_name
            tbl_fld = "#{col[0]}.#{col[1]}"
            inner_col_select += %Q~ #{and_sep} #{tbl_fld} = '#{row_data[col[1]]}'~
            and_sep = "and"
            
            column_headers[col_no] << row_data[col[1]]
            col_no += 1
          end
          column_headers[col_no] << fact_item[5]
          fct_table = fact_item[1]
          if agg_fact_table.length > 0 then
            fct_table = agg_fact_table
          end
          # inner_col_select += %Q~ then #{fact_item[1]}.#{fact_item[2]} else null end~
          inner_col_select += %Q~ then #{fct_table}.#{fact_item[2]} else null end~
          # The ",0)" matches the Coalesce above
          outer_col_select += %Q~, "#{field_no}"~
          inner_col_select += %Q~),0) "#{field_no}"~
          field_no += 1
        end
      end
      # inner_col_select += "<br>"
      build_format_list = false
    end
    [outer_col_select, inner_col_select, column_headers, format_list]
  end
  
  def build_column_header_data_select(agg_fact_table, dims, columns, facts)
    # ***** Build the select to pick the column headers
    # Format the select by and order by list
    outer_col_select_list, inner_col_select_list, col_group_by_list, col_order_by_list, format_list, ctrl_brk_list = 
      format_select_group_order_by_list(agg_fact_table, columns, [], as_eq_field=true)
    # Format the from list (each table only once)
    col_from_list = format_from_list(agg_fact_table, dims, [], columns, facts)
    # Format the where clause
    col_where_list = format_where_clause(agg_fact_table, dims, facts)

    # @get += col_select_list + "<br>" + col_from_list + "<br>" + col_where_list + "<br>" + col_group_by_list + "<br>" + col_order_by_list + "<br>"
    
    full_select = outer_col_select_list + ' from ( ' + inner_col_select_list + col_from_list + col_where_list + col_group_by_list + ' ) T ' + col_order_by_list
  end


  # ********************************************************************************
  # Lower level SQL formatting routines for reports
  #  1) format_select_group_order_by_list(rows, facts, as_eq_field)
  #  2) format_from_list(dims, rows, facts)
  #  3) format_where_clause(dims, facts)
  #  4) format_the_SQL_for_display_and_execute(select_list, from_list, where_list, group_by_list, order_by_list)
  #  5) execute_and_display_results(display_type, execute_sql, format_list)
  #  6) format_number(int_num, currency_sign, thousand_sep, precision) 
  # ********************************************************************************
  
  # ********************************************************************************
  # Routines to provide helpers for creating reports
  def format_select_group_order_by_list(agg_fact_table, rows, facts, as_eq_field)
    # Date      Author          Description
    # 20131223  Ken Buxton      Problem: If two fields from the same table use the same special sorting field, 
    #                              that sorting field will show up twice in the select list. SQL parsers 
    #                              don't like duplicate select field names.
    #                           Solution: For each select field a select list # is available (1, 2, 3, ...).
    #                              For any special sort fields add this number to the end of the name. There
    #                              won't be any duplicates at that point.
    outer_select_list = "select "
    inner_select_list = "select "
    if facts.length == 0 then
      inner_select_list += "distinct "
    end
    order_by_list = " "
    group_by_list = " "
    format_list = []
    ctrl_brk_list = []
    
    ob_sep = ""
    gb_sep = ""
    sl_sep = ""
    osl_sep = ""
    
    select_list_no = 1
    rows.each do |rk, rv|
      rv_table = rv[0]
      rv_field = rv[1]
      rv_asc_desc = rv[2]
      rv_ctrl_brk = rv[3]
      rv_header = rv[4]
      if as_eq_field then
        rv_header = rv_field
      end

      # Format the outer and inner selects based on special sorting
      outer_select_list += osl_sep + %Q~ "#{rv_header}"~
      osl_sep = ', '
      inner_select_list += sl_sep + rv_table + "." + rv_field + %Q~ "#{rv_header}"~
      sl_sep = ", "
      special_sort, special_sort_field = '', ''
      if @dim_fields[[rv_table, rv_field]] [:special_sort].length > 0 then
        special_sort, special_sort_field = @dim_fields[[rv_table, rv_field]] [:special_sort].split('~')
        special_sort_field = %Q~"#{special_sort_field}_#{select_list_no}"~ 
      end      
      if special_sort.length > 0 then
        inner_select_list += sl_sep + special_sort + ' ' + special_sort_field
      end
      
      # Format the order by list based on special sorting
      if special_sort.length > 0 then
        if rv_asc_desc != "None" then
          order_by_list += ob_sep + special_sort_field
          if rv_asc_desc == "Descending" then
            order_by_list += " desc"
          end
          ob_sep = ", "
        end
      else
        if rv_asc_desc != "None" then
          order_by_list += ob_sep + %Q~ "#{rv_header}"~
          if rv_asc_desc == "Descending" then
            order_by_list += " desc"
          end
          ob_sep = ", "
        end
      end
      
      # Format the group by list based on special sorting
      group_by_list += gb_sep + rv_table + "." + rv_field
      gb_sep = ", "
      if special_sort.length > 0 then
        group_by_list += gb_sep + special_sort
      end
      
      format_list << ""
      if rv_ctrl_brk == "Yes" then
        ctrl_brk_list << [rv_table, rv_field]
      else
        ctrl_brk_list << []
      end
      
      gb_sep = ", "
      sl_sep = ", "
      
      select_list_no += 1
    end
    
    facts.each do |fk, fv|
      fv_row_letter = fv[0]
      fv_table = fv[1]
      fv_field = fv[2]
      fv_sort = fv[3]
      fv_sum_type = fv[4]
      fv_sum_type = "Count" if fv_sum_type == "Cnt"
      fv_header = fv[5]
      fv_calc = fv[6]
      fv_format = fv[7]
      fv_display = fv[8]
      if agg_fact_table.length > 0 then fv_table = agg_fact_table end
      
      if fv_display == 'Yes' then
        format_list << fv_format
        #select_list += "#{sl_sep}#{fv_sum_type}(#{fv_table}.#{fv_field}) " + %Q~ "#{fv_sum_type} of<br>#{fv_header}"~
        outer_select_list += sl_sep + %Q~ "#{fv_header}"~
        inner_select_list += "#{sl_sep}#{fv_sum_type}(#{fv_table}.#{fv_field}) " + %Q~ "#{fv_header}"~
        # group_by_list += "#{sep}#{fv_table}.#{fv_field} "
        sl_sep = ", "
      end
    end
    if order_by_list.length > 1 then
      order_by_list = " order by " + order_by_list
    end
    if group_by_list.length > 1 then
      group_by_list = " group by " + group_by_list
    end
    
    [outer_select_list, inner_select_list, group_by_list, order_by_list, format_list, ctrl_brk_list]
  end
  
  # ********************************************************************************
  def format_from_list(agg_fact_table, dims, rows, columns, facts)
    from_list = " from "
    from_list_dim = ""
    from_list_fact = ""
    from_dim_hash = {}
    from_fact_hash = {}
    sep = ""
    
    # Look for tables in row headers
    rows.each do |rk, rv|
      rv_table = rv[0]
      if from_dim_hash[rv_table] then
        # do nothing
      else
        from_dim_hash[rv_table] = 0
        if facts.size == 0 then
          from_list_dim += sep + rv_table
        end
      end
      sep = ", "
    end
    
    # Look for tables in column headers
    columns.each do |ck, cv|
      cv_table = cv[0]
      if from_dim_hash[cv_table] then
        # do nothing
      else
        from_dim_hash[cv_table] = 0
        if facts.size == 0 then
          from_list_dim += sep + cv_table
        end
      end
      sep = ", "
    end
    
    # Look for tables in dimensions
    dims.each do |dk, dv|
      if from_dim_hash[dk] then
        # do nothing
      else
        from_dim_hash[dk] = 0
        if facts.size == 0 then
          from_list_dim += sep + dk
        end
      end
      sep = ", "
    end
    
    # Look for fact tables
    tbl_sep = " "
    facts.each do |fk, fv|
      fv_table = fv[1]
      fv_field = fv[2]
      fv_display = fv[8]
      
      if fv_display == 'Yes' then
        if from_fact_hash[fv_table] then
          # do nothing
        else
          af_table = fv_table
          if agg_fact_table.length > 0 then af_table = agg_fact_table end
          # from_list_fact += " #{fv_table} " 
          from_list_fact += " #{af_table} " 
          from_dim_hash.each do |fhk, fhv|
            fhk_table = fhk
            fhk_field = fhk_table.sub("dim_", "") + "_key"
            # fhv_field = fhv[1]
            # from_list_fact += " inner join #{fhk_table} on #{fhk_table}.#{fhk_field} = #{fv_table}.#{fhk_field} "
            from_list_fact += " inner join #{fhk_table} on #{fhk_table}.#{fhk_field} = #{af_table}.#{fhk_field} "
          end
          from_fact_hash[fv_table] = 0
        end
      end
    end
    
    from_list + from_list_fact + from_list_dim
  end

  # ********************************************************************************
  def format_where_clause(agg_fact_table, dims, facts)
    where_list = ""
    fact_table = ""
    if facts.size > 0 then
      facts.each do |fk, fv|
        if fact_table.length == 0 then
          fact_table = fv[1]
        end
      end
    end
    
    # Formatting is different depending on the presence of a fact table
    # If there is a fact table
    # logger.debug "In format_where_clause"
    relative_date_set = false
    dim_tbl_sep = ""
    if fact_table.length > 0 then
      agg_or_fact_table = fact_table
      if agg_fact_table.length > 0 then agg_or_fact_table = agg_fact_table end
      dims.each do |k, v|
        dim_tbl = k
        dim_key = k[4..-1] + "_key"
        where_list += " #{dim_tbl_sep} #{agg_or_fact_table}.#{dim_key} in ( select #{dim_key} from #{dim_tbl} where "
        # Look through all attributes for the current dimension
        dim_attrb_sep = ""
        found_where_clause = false
        v.each do |k1, v1|
          if v1.length >= 3 or v1[1].length > 0 then
            found_where_clause = true
            if v1[1].length <= 0  then
              where_list += dim_attrb_sep + dim_tbl + "." + v1[0] + " in ("
              dim_item_sep = ""
              (2..(v1.length-1)).each do |x|
                where_list += %Q~#{dim_item_sep} '#{v1[x]}'~
                dim_item_sep = ","
              end
              where_list += ") "
            else
              if not relative_date_set then
                where_list += format_current_previous_clauses(dim_tbl, v1[0], v1[1])
                # logger.debug where_list
                relative_date_set = true
              end
            end
            dim_attrb_sep = " and "
          end
        end
        if not found_where_clause then
          where_list += " 1 = 0 "
        end
        where_list += ") "
        dim_tbl_sep = " and "
      end
    # else, no fact table
    else
      sep = ""
      dims.each do |k, v|
        dim_tbl = k
        # Look through all attributes for the current dimension
        v.each do |k1, v1|
          if v1.length >= 3 or v1[1].length > 0 then
            if v1[1].length <= 0 then
              where_list += sep + dim_tbl + "." + v1[0] + " in ("
              sep2 = ""
              (2..(v1.length-1)).each do |x|
                where_list += %Q~#{sep2} '#{v1[x]}'~
                sep2 = ","
              end
              where_list += ") "
            else
              if not relative_date_set then
                where_list += format_current_previous_clauses(dim_tbl, v1[0], v1[1])
                relative_date_set = true
              end
            end
            sep = " and "
          end
        end
      end
    end
    
    if where_list.length > 0
      where_list = " where " + where_list
    end
    where_list
  end
  
  def format_current_previous_clauses(dim_tbl, attribute, clause)
    #                     0     1      2    3                 4                5               6        7
    # Array of integers: [year, month, day, month_no_overall, week_no_overall, day_no_overall, quarter, trimester]
    date_info = get_date_info
    #logger.debug date_info.to_s
    
    like_current_pat     = /^\s*cur(rent)?(\s+\d+)?\s+(year|month|week|day|quarter|trimester)s?\s*$/i
    like_previous_pat    = /^\s*prev(ious)?(\s+\d+)?\s+(year|month|week|day|quarter|trimester)s?\s*$/i
    
    like_current_pat =~ clause
    mdata = Regexp.last_match
    #logger.debug "mdata=#{mdata}, clause=#{clause}, mdata[0]=#{mdata[0]}, mdata[1]=#{mdata[1]}, mdata[2]=#{mdata[2]}, mdata[3]=#{mdata[3]}"
    if mdata then
      if mdata[0] == clause then
        count = 1
        if mdata[2] then
          if mdata[2].length > 0 then
            count = mdata[2].to_i
          end
        end
        
        case mdata[3]
        when /^years?$/
          return "year_no::integer between #{date_info[0]-count+1} and #{date_info[0]}"
        when /^months?$/
          return "month_no_overall::integer between #{date_info[3]-count+1} and #{date_info[3]}"
        when /^weeks?$/
          return "week_no_overall::integer between #{date_info[4]-count+1} and #{date_info[4]}"
        when /^days?$/
          return "day_no_overall::integer between #{date_info[5]-count+1} and #{date_info[5]}"
        when /^quarters?$/
          return "1 = 0"
        when /^trimesters?$/
          return "1 = 0"
        end
        
        return "1 = 0"
      end
    end
    
    like_previous_pat =~ clause
    mdata = Regexp.last_match
    if mdata[0] == clause then
      count = 1
      if mdata[2] then
        if mdata[2].length > 0 then
          count = mdata[2].to_i
        end
      end
      
      case mdata[3]
      when /^years?$/
        return "year_no::integer between #{date_info[0]-count} and #{date_info[0]-1}"
      when /^months?$/
        return "month_no_overall::integer between #{date_info[3]-count} and #{date_info[3]-1}"
      when /^weeks?$/
        return "week_no_overall::integer between #{date_info[4]-count} and #{date_info[4]-1}"
      when /^days?$/
        return "day_no_overall::integer between #{date_info[5]-count} and #{date_info[5]-1}"
      when /^quarters?$/
        return "1 = 0"
      when /^trimesters?$/
        return "1 = 0"
      end
      
      return "1 = 0"
    end
    
    return "1 = 0"
  end
  
  def get_date_info()
    test = false; date = Time.new(2013,12,31,15,30,25)
    # Returns: array of text of: [year, month, day, month_no_overall, week_no_overall, day_no_overall, quarter, trimester]
    if not test then
      date = Time.now
    end
    
    conn = ActiveRecord::Base.connection
    yyyymmdd = date.year*10_000 + date.month*100 + date.day
    sql = "select year_no, month_no, day_no, month_no_overall, week_no_overall, day_no_overall, quarter, trimester " +
      "from dim_date where yyyymmdd_date = '#{yyyymmdd}';"
    rs = conn.select_all(sql)
    date_info = Array.new(8)
    rs.each do |dt|
      date_info[0] = dt["year_no"].to_i
      date_info[1] = dt["month_no"].to_i
      date_info[2] = dt["day_no"].to_i
      date_info[3] = dt["month_no_overall"].to_i
      date_info[4] = dt["week_no_overall"].to_i
      date_info[5] = dt["day_no_overall"].to_i
      date_info[6] = dt["quarter"].to_i
      date_info[7] = dt["trimester"].to_i
    end
    date_info
    
  end
  
  # ********************************************************************************
  def format_the_SQL_for_display_and_execute(outer_select_list, inner_select_list, from_list, where_list, group_by_list, order_by_list)
    display_sql = "#{outer_select_list} <br>from (<br> #{inner_select_list}<br>#{from_list}"
    if where_list.length > 0
      display_sql += "<br>#{where_list}"
    end
    if group_by_list.length > 1 then
      display_sql += "<br>#{group_by_list}"
    end
    display_sql += "<br> ) T <br>#{order_by_list};"
      
    execute_sql = %Q~#{outer_select_list} from ( #{inner_select_list} #{from_list} #{where_list} #{group_by_list} ) T #{order_by_list};~
    # sql = %Q~#{select_list};
    
    [display_sql, execute_sql]
  end
  
  # ********************************************************************************
  def execute_and_display_row_column_results(execute_sql, format_list, control_breaks, rows, facts, column_headers)
    results = ""
    conn = ActiveRecord::Base.connection
    rs_dummy = conn.select_all(@set_statement_timeout)
    rs = conn.select_all(execute_sql)
    rs_dummy = conn.select_all(@reset_statement_timeout)
    @num_rows = rs.size
    if @num_rows <= 0 then
      return "No records were retrieved.<br>One of your dimension constraints with no selections may be causing this condition."
    end
    # Start with the table the holds the results
    # Initialize variables
    row_no = 0; col_no = 0
    rep_array = Array.new()
    hdr_array = Array.new()
    
    # Set up initial control break values (a grid with control breaks as rows and fact summaries as columns)
    # The first column of each row contains the latest control break values (all start with blank) which is 
    # used to check for changes in control break values.
    # cb_grid row = [(database table/field), display_name, current_cb_value, fact value lists...]
    #   fact value list = header_name, summary_type, sum_value, count_value
    num_data_columns = rs.first.size
    num_summary_columns = num_data_columns - rows.size - 1
    num_summary_col_groups = num_summary_columns / facts.size
    cb_grid = []
    rows.each do |rkey, row|  # row = [table, field, sort, control_break, header_name]
      cb_name = "#{row[0]}.#{row[1]}"
      if row[3] == "No" then
        cb_name = ""
      end
      cb_row = [cb_name, row[4], ""]   # the name and starting value of this control break - blank for all
      cur_col_name = 10001
      (0..(num_summary_col_groups-1)).each do |sc|
        facts.each do |fkey, fact|
          # rows with control breaks get header_name, control break type (sum, avg, min, etc.), and starting values
          # rows without control breaks just get an empty array
          cb_row << (if cb_name == "" then [] else [cur_col_name.to_s, fact[4], 0, 0] end)
          cur_col_name += 1
        end
      end
      cb_grid << cb_row
    end
    
    
    # For each row in the result set
    rs.each do |row_data|
      rep_array[row_no] = []

      # Initial fill ov cb values: first time through (row_no == 0) we fill in the initial control break values
      if row_no == 0 then   # Initial fill of cb values
        cb_grid.each do |cb_row|
          if cb_row[0] > "" then
            cb_row[2] = row_data[cb_row[1]]
          end
        end
      end

      row_no = process_control_breaks_rc(false, cb_grid, rep_array, row_data, row_no, facts, format_list)
      
      # For each column in the result set
      col_no = 0
      row_data.each do |k, v|
        # If this is the first row, also format the header
        # if row_no == 0
          # hdr_array[col_no] = "<th>#{k}</th>"
        # end
        
        # And format the actual row
        format_str = format_list[col_no]
        rep_array[row_no][col_no] = format_value(v, format_str)
        col_no += 1
      end
      row_no += 1
      #results += "End row_no=#{row_no}<br>"
      
    end
    
    rep_array[row_no] = []
    row_no = process_control_breaks_rc(true, cb_grid, rep_array, [], row_no, facts, format_list)
    
    # rep_array.each do |jj|
      # results += jj.to_s + "<br>"
    # end

    # Format results in either row mode or column mode    
    results += "<table>"
    (0..row_no-1).each do |row|
      if row == 0
        column_headers.each do |col_hdr_row|
          results += "<tr>"
          col_hdr_row.each do |col_header_data|
            results += "<th>#{col_header_data}</th>"
          end
          results += "</tr>"
        end
      end
      cb = is_control_break(rep_array[row], rows.size)
      if cb then
        results += '<tr class="cb">'
      else
        results += "<tr>"
      end
      (0..col_no-1).each do |col|
        this_col = "#{rep_array[row][col]}"
        results += this_col
      end
      results += "</tr>"
    end

    
    # And finally, the end of the table
    results += "</table>"

    return results
  end
  
  def is_control_break(rep_line, num_row_headers)
    (1..num_row_headers).each do |col|
      if rep_line[col-1] == '<td>&nbsp;</td>' then
        return true
      end
    end
    return false
  end
  
  def process_control_breaks_rc(
    final,      # if true, this is the final call to show any remaining CB rows. row_data is empty
    cb_grid,    # the control break grid - 1 row for each control break
    rep_array,  # 
    row_data, 
    row_no, 
    facts, 
    format_list)
    # Check for control breaks and format them (incrementing row_no for each control break found)
    # Note: a) control break values are processed from right to left (most frequently changing first)
    #       b) once a control break value is formatted, the initial value should be reset
    #       c) when checking for lower level control breaks, need to look for changes in all higher level CB's
    #
    # Summarize break changes (if an upper level CB found, all lower level CBs are true)
    cb_change_found = false
    cur_cb_change_list = []
    (0).upto(cb_grid.size-1) do |cb_i|
      cur_cb = "No"
      cb_row = cb_grid[cb_i]    # Get the current row
      if cb_row[0] > "" then    # If this is a control break
        if not final then
          if cb_row[2] != row_data[cb_row[1]] or cb_change_found then
            cb_change_found = true
            cur_cb = "Yes"
          end
        else 
          cb_change_found = true
          cur_cb = "Yes"
        end
      end
      cur_cb_change_list << cur_cb
    end
          
    (cb_grid.size-1).downto(0) do |cb_i|
      cb_row = cb_grid[cb_i]    # Get the current row
      if cur_cb_change_list[cb_i] == "Yes" then    # If this is a control break as calculated above
        # Format blanks for any fields before or after this value
        (0..cb_grid.size-1).each do |cb_col_no1|
          if cb_col_no1 == cb_i then
            # Show the control break value
            rep_array[row_no][cb_i] = format_value(cb_row[2], "", true)
          else
            rep_array[row_no][cb_col_no1] = format_value("", "")
          end
        end
        rep_array[row_no][cb_grid.size] = format_value("", "")
        
        # Fill in the fact values
        #((cb_grid.size+1)..(cb_grid.size+facts.size-1)).each do |cb_col_no2|
        cb_row_entry = 3
        ((cb_grid.size+1)..(format_list.size-1)).each do |cb_col_no2|
          fval = 0
          fact_list = cb_row[cb_row_entry]
          if fact_list[1] == "Sum" then
            fval = fact_list[2]
          elsif fact_list[1] == "Avg" then
            if fact_list[3] > 0 then
              fval = fact_list[2] / fact_list[3]
            end
          elsif fact_list[1] == "Cnt" then
            fval = fact_list[2]
          elsif fact_list[1] == "Min" then
            fval = fact_list[2]
          elsif fact_list[1] == "Max" then
            fval = fact_list[2]
          else
            logger.debug "Invalid summary type: #{fact_list.to_s}"
          end
          rep_array[row_no][cb_col_no2] = format_value(fval, format_list[cb_col_no2])
          
          # Clear out this breaks values
          fact_list[2] = 0
          fact_list[3] = 0
          cb_row_entry += 1
        end
        
        row_no += 1
        #results += "row_no=#{row_no}, "
        rep_array[row_no] = []
        
        if not final then
          cb_row[2] = row_data[cb_row[1]]    # Update to the new control break value
        end
      end
    end
    #results += "CB2 row_no=#{row_no}, "

    # Update control break summary fields (sum, avg, cnt, etc.)
    # cb_grid row = [(database table/field), display_name, current_cb_value, fact value lists...]
    #   fact value list = header_name, summary_type, sum_value, count_value
    # For each possible control break
    # results += row_data.to_s + "<br>"
    if not final then
      (0..cb_grid.size-1).each do |cb_i|
        # Get the curent control break row
        cb_row = cb_grid[cb_i]
        # If this is a control break
        if cb_row[0] > "" then
          # For each fact entry
          (3..cb_row.size-1).each do |cb_fi|
            cb_fact = cb_row[cb_fi]
            # Process the fact entry based on the summary_type
            if cb_fact[1] == "Sum" then
              cb_fact[2] += row_data[cb_fact[0]].to_i
            elsif cb_fact[1] == "Avg" then
              cb_fact[2] += row_data[cb_fact[0]].to_i
              cb_fact[3] += 1
            elsif cb_fact[1] == "Cnt" then
              cb_fact[2] += 1
            elsif cb_fact[1] == "Min" then
              cur_val = row_data[cb_fact[0]].to_i
              if cur_val < cb_fact[2] then cb_fact[2] = cur_val end
            elsif cb_fact[1] == "Max" then
              cur_val = row_data[cb_fact[0]].to_i
              if cur_val > cb_fact[2] then cb_fact[2] = cur_val end
            end
          end
        end
      end
    end
    
    row_no
  end
  

  # ********************************************************************************
  def execute_and_display_results(display_type, execute_sql, format_list, control_breaks, rows, facts)
    results = ""
    conn = ActiveRecord::Base.connection
    rs_dummy = conn.select_all(@set_statement_timeout)
    rs = conn.select_all(execute_sql)
    rs_dummy = conn.select_all(@reset_statement_timeout)
    @num_rows = rs.size
    if @num_rows <= 0 then
      return "No records were retrieved. One of your dimension constraints with no selections may be causing this condition."
    end
    # Start with the table that holds the results
    # Initialize variables
    row_no = 0; col_no = 0
    rep_array = Array.new()
    hdr_array = Array.new()
    
    # Set up initial control break values (a grid with control breaks as rows and fact summaries as columns)
    # The first column of each row contains the latest control break values (all start with blank) which is 
    # used to check for changes in control break values.
    # cb_grid row = [(database table/field), display_name, current_cb_value, fact value lists...]
    #   fact value list = header_name, summary_type, sum_value, count_value
    cb_grid = []
    rows.each do |rkey, row|  # row = [table, field, sort, control_break, header_name]
      cb_name = "#{row[0]}.#{row[1]}"
      if row[3] == "No" then
        cb_name = ""
      end
      cb_row = [cb_name, row[4], ""]   # the name and starting value of this control break - blank for all
      facts.each do |fkey, fact|
        # rows with control breaks get header_name, control break type (sum, avg, min, etc.), and starting values
        # rows without control breaks just get an empty array
        cb_row << (if cb_name == "" then [] else [fact[5], fact[4], 0, 0] end)
      end
      cb_grid << cb_row
    end
   
    
    # For each row in the result set
    rs.each do |row_data|
      rep_array[row_no] = []

      # Initial fill ov cb values: first time through (row_no == 0) we fill in the initial control break values
      if row_no == 0 then   # Initial fill of cb values
        cb_grid.each do |cb_row|
          if cb_row[0] > "" then
            cb_row[2] = row_data[cb_row[1]]
          end
        end
      end

      row_no = process_control_breaks(false, cb_grid, rep_array, row_data, row_no, facts, format_list)
      
      # For each column in the result set
      col_no = 0
      row_data.each do |k, v|
        # If this is the first row, also format the header
        if row_no == 0
          hdr_array[col_no] = %Q~<th>#{k}</th>~
        end
        
        # And format the actual row
        format_str = format_list[col_no]
        rep_array[row_no][col_no] = format_value(v, format_str)
        col_no += 1
      end
      row_no += 1
      #results += "End row_no=#{row_no}<br>"
      
    end
    
    rep_array[row_no] = []
    row_no = process_control_breaks(true, cb_grid, rep_array, [], row_no, facts, format_list)

    # Format results in either row mode or column mode    
    results += %Q~<table>~
    if display_type == "Row" then
      (0..row_no-1).each do |row|
        if row == 0
          results += "<tr>"
          (0..col_no-1).each do |col|
            cell = hdr_array[col].gsub("~", "<br>")
            results += "#{cell}"
          end
          results += "</tr>"
        end
        cb = is_control_break(rep_array[row], rows.size)
        if cb then
          results += '<tr class="cb">'
        else
          results += "<tr>"
        end
        (0..col_no-1).each do |col|
          this_col = "#{rep_array[row][col]}"
          results += this_col
        end
        results += "</tr>"
      end
      
    elsif display_type == "Column" then
      (0..col_no-1).each do |col|
        results += "<tr>"
        (0..row_no-1).each do |row|
          if row == 0
            results += "#{hdr_array[col]}"
          end
          results += "#{rep_array[row][col]}"
        end
        results += "</tr>"
      end
      
    end
    
    # And finally, the end of the table
    results += "</table>"

    return results
  end

  def process_control_breaks(
    final,      # if true, this is the final call to show any remaining CB rows. row_data is empty
    cb_grid,    # the control break grid - 1 row for each control break
    rep_array,  # 
    row_data, 
    row_no, 
    facts, 
    format_list)
    # Check for control breaks and format them (incrementing row_no for each control break found)
    # Note: a) control break values are processed from right to left (most frequently changing first)
    #       b) once a control break value is formatted, the initial value should be reset
    #       c) when checking for lower level control breaks, need to look for changes in all higher level CB's
    #
    # Summarize break changes (if an upper level CB found, all lower level CBs are true)
    cb_change_found = false
    cur_cb_change_list = []
    (0).upto(cb_grid.size-1) do |cb_i|
      cur_cb = "No"
      cb_row = cb_grid[cb_i]    # Get the current row
      if cb_row[0] > "" then    # If this is a control break
        if not final then
          if cb_row[2] != row_data[cb_row[1]] or cb_change_found then
            cb_change_found = true
            cur_cb = "Yes"
          end
        else 
          cb_change_found = true
          cur_cb = "Yes"
        end
      end
      cur_cb_change_list << cur_cb
    end
    #results += cur_cb_change_list.to_s + "<br>"
          
    #results += "CB1 row_no=#{row_no}, "
    (cb_grid.size-1).downto(0) do |cb_i|
      cb_row = cb_grid[cb_i]    # Get the current row
      if cur_cb_change_list[cb_i] == "Yes" then    # If this is a control break as calculated above
        # Format blanks for any fields before or after this value
        (0..cb_grid.size-1).each do |cb_col_no1|
          if cb_col_no1 == cb_i then
            # Show the control break value
            rep_array[row_no][cb_i] = format_value(cb_row[2], "", true)
          else
            rep_array[row_no][cb_col_no1] = format_value("", "")
          end
        end
        
        # Fill in the fact values
        ((cb_grid.size)..(cb_grid.size+facts.size-1)).each do |cb_col_no2|
        #((cb_grid.size+1)..(format_list.size-1)).each do |cb_col_no2|
          fval = 0
          fact_list = cb_row[3 + cb_col_no2-cb_grid.size]
          if fact_list[1] == "Sum" then
            fval = fact_list[2]
          elsif fact_list[1] == "Avg" then
            if fact_list[3] > 0 then
              fval = fact_list[2] / fact_list[3]
            end
          elsif fact_list[1] == "Cnt" then
            fval = fact_list[2]
          elsif fact_list[1] == "Min" then
            fval = fact_list[2]
          elsif fact_list[1] == "Max" then
            fval = fact_list[2]
          end
          rep_array[row_no][cb_col_no2] = format_value(fval, format_list[cb_col_no2])
          
          # Clear out this breaks values
          fact_list[2] = 0
          fact_list[3] = 0
        end
        
        row_no += 1
        #results += "row_no=#{row_no}, "
        rep_array[row_no] = []
        
        if not final then
          cb_row[2] = row_data[cb_row[1]]    # Update to the new control break value
        end
      end
    end
    #results += "CB2 row_no=#{row_no}, "

    # Update control break summary fields (sum, avg, cnt, etc.)
    # cb_grid row = [(database table/field), display_name, current_cb_value, fact value lists...]
    #   fact value list = header_name, summary_type, sum_value, count_value
    # For each possible control break
    # results += row_data.to_s + "<br>"
    if not final then
      (0..cb_grid.size-1).each do |cb_i|
        # Get the curent control break row
        cb_row = cb_grid[cb_i]
        # If this is a control break
        if cb_row[0] > "" then
          # For each fact entry
          (3..cb_row.size-1).each do |cb_fi|
            cb_fact = cb_row[cb_fi]
            # Process the fact entry based on the summary_type
            if cb_fact[1] == "Sum" then
              cb_fact[2] += row_data[cb_fact[0]].to_i
            elsif cb_fact[1] == "Avg" then
              cb_fact[2] += row_data[cb_fact[0]].to_i
              cb_fact[3] += 1
            elsif cb_fact[1] == "Cnt" then
              cb_fact[2] += 1
            elsif cb_fact[1] == "Min" then
              cur_val = row_data[cb_fact[0]].to_i
              if cur_val < cb_fact[2] then cb_fact[2] = cur_val end
            elsif cb_fact[1] == "Max" then
              cur_val = row_data[cb_fact[0]].to_i
              if cur_val > cb_fact[2] then cb_fact[2] = cur_val end
            end
          end
        end
      end
    end
    
    row_no
  end
  
  # ********************************************************************************
  def format_value(value, format_str, bold = false)
    formatted_value = ""
    if format_str == "" then
      if value == "" then
        value = "&nbsp;"
      end
      if bold then
        formatted_value = "<td><b>#{value.to_s}</b></td>"
      else
        formatted_value = "<td>#{value.to_s}</td>"
      end
      
    elsif format_str == "0#,###.##" then
      f = format_number(value.to_i, "", ",", 2)
      formatted_value = "<td align='right'>#{f}</td>"
      
    elsif format_str == "$0#,###.##" then
      f = format_number(value.to_i, "$", ",", 2)
      formatted_value = "<td align='right'>#{f}</td>"
      
    elsif format_str == "0#,###" then
      f = format_number(value.to_i, "", ",", 0)
      formatted_value = "<td align='right'>#{f}</td>"
      
    elsif format_str == "0#" then
      f = format_number(value.to_i, "", "", 0)
      formatted_value = "<td align='right'>#{f}</td>"
      
    else
      formatted_value = "<td>#{value.to_s}</td>"
    end
    formatted_value
  end
  
  # ********************************************************************************
  def format_number(int_num, currency_sign, thousand_sep, precision) 
    # the digits to the right of the fraction point
    r = (int_num % 10**precision)
    # the digits to the left of the fraction point
    l = (int_num / 10**precision).to_s
    # if any
    if precision > 0
      f = "." + ("0"*precision + r.to_s)[-precision..-1]
    else
      f = ""
    end
    
    # if there is a thousands separator to use
    if thousand_sep.length == 1 then
      # while there are digits yet to format
      while l.length > 0
        # if there are more than 3 digits to format - time for a ","
        if l.length > 3
          # Add the comma and next 3 digits to the number
          f = thousand_sep + l[-3..-1] + f
          # Remove the 3 digits we just used from the number
          l = l[0..-4]
        # else, there are 3 or fewer digits left. Another comma is not needed.
        else 
          # Add the remaining digits to the number
          f = l + f
          # Indicate that we are all done.
          l = ""
        end
      end
    # no thousands separator
    else
      f = l + f
    end
    if currency_sign.length == 1 then
      f = currency_sign + f
    end
    # Return the number we formatted
    f
  end
  
  
  # ********************************************************************************
  # ********************************************************************************
  # Report Definition Routines: Dimensions, Facts, Report Fields
  # ********************************************************************************
  # ********************************************************************************
  
  # ********************************************************************************
  # who: the dimension table edit being returned
  # req: any parameters from attribute fields for this request
  def get_dim(who, req)
    @get = "<table><tr>"
    
    @get += "<td>"
    get_dim_attributes who
    @get += "</td>"
    
    get_dim_selections who, req
    
    @get += "</tr></table>"
    
  end
  
  def get_dim_fact_matrix(who, req)
    # Format the table header
    @get = "<b style='font-size: 10pt; color: blue'>Dimension / Fact Matrix</b>"
    @get += %Q~<table class="all" style="border-collapse:collapse;"> ~ +
             %Q~<tr>  <th>Dimension</th> ~

    conn = ActiveRecord::Base.connection
    
    sql = %Q~select table_name, table_display_name from facts order by display_order ~
    
    rs = conn.select_all(sql)
    select_fields = ""
    pivot_fields = ""
    field_list = []
    rs.each do |row|
      field_name = row["table_display_name"]
      select_fields += %Q~, "#{field_name}"~
      pivot_fields += %Q~, Max(case when F.table_display_name = '#{field_name}' then '#{field_name}' else case when T.fact_table = '#{field_name}' then 'Agg #{field_name}' else '' end end) "#{field_name}" ~
      field_list << field_name
      @get += "<th>Fact<br>" + field_name + "</th>"
    end
    @get += "</tr>"
    
    sql = %Q~select "Dimension" #{select_fields} ~ +
          %Q~from ( ~ +
          %Q~   select D.table_display_name "Dimension", D.display_order ~ +
          %Q~      #{pivot_fields} ~ +
          
          %Q~   from dimensions D  ~ +
          %Q~      left join fact_fields FF on D.table_name = FF.dimension  ~ +
          %Q~      left join facts F on FF.table_name = F.table_name  ~ +
          %Q~      left join ( ~ +
          %Q~         select distinct D.table_display_name dim_table, F.table_display_name fact_table ~ +
          %Q~         from dimensions D  ~ +
          %Q~            left join fact_fields FF on D.table_name = FF.dimension  ~ +
          %Q~            left join aggregate_details AD on D.table_name = AD.agg_dim_table and D.summary_dim = 'T' ~ +
          %Q~            left join aggregates A on AD.aggregate_table_name = A.aggregate_table_name ~ +
          %Q~            left join facts F on A.fact_table_name = F.table_name ~ +
          %Q~         where A.fact_table_name <> '' ~ +
          %Q~      ) T on D.table_display_name = T.dim_table ~ +
          %Q~   group by D.table_display_name, D.display_order ~ +      
          %Q~) T ~ +
          %Q~order by display_order~

    rs = conn.select_all(sql)
    
    rs.each do |row|
      @get += "<tr>"
      @get += "<td>" + row["Dimension"]     + "</td>"
      field_list.each do |field|
        @get += "<td>" + row[field]         + "</td>"
      end
      @get += "</tr>"
    end
    
    @get += "</table>"
    
    # logger.debug @get
  end
  
  # ********************************************************************************
  def dim_display_height
    # 322
    503
  end
  
  # ********************************************************************************
  def get_dim_attributes(who)
    Dimension.select("table_name, table_display_name").where("table_name = '#{who}'").each do |table|
      @table_name = table.table_name
      @table_display_name = table.table_display_name
      @get += %Q~<b style="text-align: left; font-size: 12pt; height: 10px; color: blue;" >~ +
      "#{table.table_display_name} Fields</b>"
    end
    @get += %Q~<div style="border:1px solid black; height: #{dim_display_height+23}px; overflow-y: scroll;">~
    @get += %Q~<table>~ 
   
    where_clause = "is_primary_key = 'f' and table_name = '#{who}'"    
    small_button_style = %Q~ class="btn4" style="font-size: 6pt; padding-left: 1mm; padding-right: 1mm; width: 15px; height: 20px;"~
    regular_button_style = %Q~ class="btn4" style="font-size: 8pt; height: 20px;"~
    DimensionField.select("field_name, field_display_name").
    where(where_clause).order("display_order").each do |field|
      rcn_onclick = %Q~ onclick="dim_rcn_handler('=rep=', '#{@table_name}', '#{field.field_name}')"~
      field_onclick = %Q~ onclick="dim_field_handler('#{@table_name}', '#{field.field_name}')"~
      @get += "<tr><td>" + 
      "<button" + small_button_style + rcn_onclick.sub("=rep=", "Row") + ">R</button>" + 
      "<button" + small_button_style + rcn_onclick.sub("=rep=", "Column") + ">C</button>" + 
      "<button" + small_button_style + rcn_onclick.sub("=rep=", "None") + ">N</button>" + 
      "<button" + regular_button_style + field_onclick + ">" + field.field_display_name + "</button>" + 
      "</td></tr>"
    end
    @get += "</table>"    
    @get += "</div>"    
  end
  
  # ********************************************************************************
  def get_dim_selections(who, req)
    #logger.debug req.to_s
    if req then
      small_button_style = %Q~ style="font-size: 8pt; padding-left: 1mm; padding-right: 1mm; width: 20px; height 15px;"~
      small_button_style2 = %Q~ style="font-weight:bold;font-size: 8pt; padding-left: 1mm; padding-right: 1mm; width: 20px; height 15px;"~

      combined_where = "1=1 "
      combined_sep = " and "
      conn = User.connection  # any connection would do
      max_req_idx = req.size
      cur_req_idx = 0
      req.each do |key, val_list|
        field = val_list[0]
        expression = val_list[1]
        exp_title = "Build Expression"
        if expression.size > 0 then
          exp_title = "Expression: " + expression
        end
        exp_display_letter = if expression.size > 0 then "E" else "e" end
        field_selections = val_list[2..-1]
        display_field = ""
        special_sort = ""
        special_sort_field = ""
        compare_as = ""
        
        attrib_onclick = %Q~ onclick="dim_attrib_handler('=rep=', '#{who}', '#{field}')"~
      
        DimensionField.select("field_display_name, special_sort, compare_as").
        where("table_name = '#{who}' and field_name = '#{field}'").order("display_order").each do |fld|
          display_field = fld.field_display_name
          special_sort = fld.special_sort
          if special_sort.length > 0 then
            special_sort, special_sort_field = special_sort.split('~')
          end
          compare_as = fld.compare_as
        end
        
        # ----------------------------------------
        @get += "<td>"
        # ----------------------------------------
        @get += %Q~<div style="border:1px solid black;" >~
        @get += %Q~<b style="text-align: left; font-size: 10pt; color: blue;" >~ +
          "#{display_field}</b><br>"
        btn4 = '"btn4"'
        if cur_req_idx > 0 then
          @get += 
            "<button class=#{btn4} title='Move column left'" + small_button_style2 + attrib_onclick.sub("=rep=", "LT") + "><b style='color: red'>&lt;</b></button>"
        end
        exp_button_id = "Exp.#{who}.#{field}"
        @get += 
          "<button class=#{btn4} title='Select All'" + small_button_style + attrib_onclick.sub("=rep=", "Sel") + ">S</button>" +
          "<button class=#{btn4} title='Clear All'" + small_button_style + attrib_onclick.sub("=rep=", "Clr") + ">C</button>" +
          "<button class=#{btn4} id='#{exp_button_id}' title='#{exp_title}'" + small_button_style + attrib_onclick.sub("=rep=", "Exp") + ">#{exp_display_letter}</button>" +
          "<button class=#{btn4} title='Remove Column'" + small_button_style + attrib_onclick.sub("=rep=", "Del") + ">X</button>"
        if cur_req_idx < max_req_idx - 1 then
          @get += 
            "<button class=#{btn4} title='Move column right'" + small_button_style2 + attrib_onclick.sub("=rep=", "GT") + "><b style='color: red'>&gt;</b></button>"
        end
        @get += "</div>"
        @get += %Q~<div style="border:1px solid black; height: #{dim_display_height}px; overflow-y: scroll;">~
        # ----------------------------------------
        id = "SEL_#{who}.#{field}"
        @get += %Q~<table id="#{id}">~ 

        # The order by for selecting the current field is either the field name (if nothing is in 
        #   dimension_field.special_sort) or the value in dimension_field.special_sort
        ordering_field = field
        if special_sort.length > 0 then
          ordering_field = special_sort
        end
        
        # Don't attempt to use this as a field value selection expression if this is a
        # current or previous expression
        cur_prev_pat = /^\s*(cur|prev).*/i
        is_cur_prev = false
        if expression.size > 0 and not cur_prev_pat =~ expression then
          expr_field = field
          if compare_as == "Numeric" then
            expr_field = "(" + field + "::float)"
          end
          if expression[0..3] == 'like' then
            # Changed to allow case insensitive compares
            expr_field = field + ' ~* '
            expression = expression.gsub(/like */i, '').gsub(/%/, '.*')
          end
          combined_where += " #{combined_sep} #{expr_field} #{expression}"
        else
          is_cur_prev = true
        end

        # my_select = "select distinct #{field} from #{who} where #{combined_where} #{order_by};"
        #log_event(["Select field values", field, ordering_field, who, combined_where].to_s)
        my_select = "select #{field} from (select distinct #{field}, #{ordering_field} ordering_field from #{who} where #{combined_where}) T order by ordering_field;"
        #log_event(my_select)
        chk_box_on_click = %Q~onclick="chk_box_click('#{who}', '#{field}')"~
        selections = conn.select_values(my_select)
        if not is_cur_prev then
          combined_where = get_next_in_clause(combined_where, combined_sep, field, field_selections)
        end
        selections.each do |cur_selection|
          # checked = if field_selections.find_index(cur_selection) or selections.size == 1 then "checked='true'" else "checked='false'" end
          checked = if field_selections.find_index(cur_selection) or selections.size == 1 then "checked='true'" else "" end
          @get += "<tr><td><div><input type='CheckBox'; #{chk_box_on_click}; #{checked} value='#{cur_selection}'>#{cur_selection}</div></td></tr>"
        end

        @get += "</table>"    
        # ----------------------------------------
        @get += "</div>"    
        # ----------------------------------------
        @get += "</td>"
        # ----------------------------------------
        
        cur_req_idx += 1
      end
      conn.close
    end
  end
  
  # ********************************************************************************
  def get_next_in_clause(combined_where, combined_sep, field, field_selections)
    combined_where += " #{combined_sep} #{field} in ("
    list_sep = ""
    field_selections.each() do |field_selection|
      combined_where += "#{list_sep}'#{field_selection}'"
      list_sep = ","
    end
    combined_where += ")"
  end
  
  # ********************************************************************************
  # who: the fact table edit being returned
  # req: ?
  def get_fact(who, req)
    @get = ""
    Fact.select("table_display_name").where("table_name = '#{who}'").each do |table|
      @get += %Q~<b style="text-align: left; font-size: 12pt; color:blue;" >#{table.table_display_name} Fields</b>~
    end
    @get += %Q~<div style="border:1px solid black; height: 325px; overflow-y: scroll;">~
    @get += %Q~<table>~ 

    
    where_clause = "field_type = 'Fact' and table_name = '#{who}'"      
    regular_button_style = %Q~ style="font-size: 8pt"; ~
    FactField.select("field_display_name, field_name, fact_type").
    where(where_clause).order("display_order").each do |field|
      fact_onclick = %Q~ onclick="fact_attrib_handler('#{who}', '#{field.field_name}', '#{field.fact_type}')"~
      @get += '<tr><td><button class="btn3"' + regular_button_style + fact_onclick + ">" + field.field_display_name + "</button></td></tr>"
    end
    @get += "</table>"    
    @get += "</div>"    
  end

end
