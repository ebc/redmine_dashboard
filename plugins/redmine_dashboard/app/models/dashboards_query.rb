class DashboardsQuery < Query  
  @@operators = { "="   => :label_equals,
                      "!"   => :label_not_equals,
                      "o"   => :label_open_issues,
                      "c"   => :label_closed_issues,
                      "!*"  => :label_none,
                      "*"   => :label_all,
                      ">="  => :label_greater_or_equal,
                      "<="  => :label_less_or_equal,
                      "<t+" => :label_in_less_than,
                      ">t+" => :label_in_more_than,
                      "t+"  => :label_in,
                      "t"   => :label_today,
                      "w"   => :label_this_week,
                      ">t-" => :label_less_than_ago,
                      "<t-" => :label_more_than_ago,
                      "t-"  => :label_ago,
                      "b"   => :label_ago,
                      "~"   => :label_contains,
                      "!~"  => :label_not_contains }
  @@operators_by_filter_type[:date] << "b" 
  unloadable

  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    sql = ''
    case operator
    when "="
      if value.any?
        sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
      else
        # IN an empty set
        sql = "1=0"
      end
    when "!"
      if value.any?
        sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
      else
        # NOT IN an empty set
        sql = "1=1"
      end
    when "!*"
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when "*"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when ">="
      sql = "#{db_table}.#{db_field} >= #{value.first.to_i}"
    when "<="
      sql = "#{db_table}.#{db_field} <= #{value.first.to_i}"
    when "o"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
    when "c"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
    when ">t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, 0)
    when "<t-"
      sql = date_range_clause(db_table, db_field, nil, - value.first.to_i)
    when "t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when ">t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, nil)
    when "<t+"
      sql = date_range_clause(db_table, db_field, 0, value.first.to_i)
    when "t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when "t"
      sql = date_range_clause(db_table, db_field, 0, 0)
    when "b"      
      sql = ("#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((value.first).to_time.beginning_of_day), connection.quoted_date((value.last).to_time.end_of_day)])      
    when "w"
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = Date.today.cwday
      days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
      sql = date_range_clause(db_table, db_field, - days_ago, - days_ago + 6)
    when "~"
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when "!~"
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    end

    return sql
  end
end