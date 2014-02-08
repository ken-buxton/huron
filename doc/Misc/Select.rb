  def format_select_group_order_by_list(agg_fact_table, rows, facts, as_eq_field)
    select_list = "select "
    if facts.length == 0 then
      select_list += "distinct "
    end
    order_by_list = " "
    group_by_list = " "
    format_list = []
    ctrl_brk_list = []
    
    ob_sep = ""
    gb_sep = ""
    sl_sep = ""
    rows.each do |rk, rv|
      rv_table = rv[0]
      rv_field = rv[1]
      rv_asc_desc = rv[2]
      rv_ctrl_brk = rv[3]
      rv_header = rv[4]
      if as_eq_field then
        rv_header = rv_field
      end
      
      select_list += sl_sep + rv_table + "." + rv_field + %Q~ "#{rv_header}"~
      if @dims[[rv_table, rv_field]] [:special_sort].length > 0 then
        order_by_list += ob_sep + @dims[[rv_table, rv_field]] [:special_sort]
        ob_sep = ", "
      else
        if rv_asc_desc != "None" then
          order_by_list += ob_sep + rv_table + "." + rv_field
          if rv_asc_desc == "Descending" then
            order_by_list += " desc"
          end
          ob_sep = ", "
        end
      end
      group_by_list += gb_sep + rv_table + "." + rv_field
      format_list << ""
      if rv_ctrl_brk == "Yes" then
        ctrl_brk_list << [rv_table, rv_field]
      else
        ctrl_brk_list << []
      end
      
      gb_sep = ", "
      sl_sep = ", "
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
        select_list += "#{sl_sep}#{fv_sum_type}(#{fv_table}.#{fv_field}) " + %Q~ "#{fv_header}"~
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
    
    logger.debug     [select_list, group_by_list, order_by_list, format_list, ctrl_brk_list].to_s
    [select_list, group_by_list, order_by_list, format_list, ctrl_brk_list]
  end
