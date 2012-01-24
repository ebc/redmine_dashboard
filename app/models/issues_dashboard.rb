class IssuesDashboard
  # Calculate total count of all completed issues
  def self.issues_completed_count(from, to)
    sql = "
      SELECT 
        COUNT(id) completed 
      FROM #{Issue.table_name} 
      WHERE done_ratio = 100 start_date BETWEEN \'#{from}\' AND \'#{to}\'"
    result = ActiveRecord::Base.connection.select_one(sql)
    result['completed'].to_f
  end

  # Calculate done ratio from all issues
  def self.issues_done_ratio(from, to)
    if from && to
      sql = "
        SELECT 
          SUM(done_ratio) done, COUNT(id) total 
        FROM #{Issue.table_name} 
        WHERE start_date BETWEEN \'#{from}\' AND \'#{to}\'"
    else
      sql = "
        SELECT 
          SUM(done_ratio) done, COUNT(id) total 
        FROM #{Issue.table_name}"        
    end

    issues_average = ActiveRecord::Base.connection.select_one(sql)
    total = issues_average["total"].to_f
    done_ratio = issues_average["done"].to_f / total 
    remaining_ratio = 100.0 - done_ratio

    { :done_ratio => done_ratio, :remaining_ratio => remaining_ratio, :total => total}
  end

  def self.issues_by_project_done_ratio(project_id, from, to)
    if from && to
      sql = "
        SELECT 
          SUM(done_ratio) done, COUNT(id) total 
        FROM #{Issue.table_name} 
        WHERE 
          project_id = #{project_id} 
          AND start_date BETWEEN \'#{from}\' AND \'#{to}\'"
    else
      sql = "
        SELECT 
          SUM(done_ratio) done, COUNT(id) total         
        FROM #{Issue.table_name}
        WHERE
          project_id = #{project_id}"        
    end

    issues_average = ActiveRecord::Base.connection.select_one(sql)
    total = issues_average["total"].to_f
    done_ratio = issues_average["done"].to_f / total 
    remaining_ratio = 100.0 - done_ratio

    { :done_ratio => done_ratio, :remaining_ratio => remaining_ratio, :total => total}
  end

  def self.issues_by_date_count(from = nil, to = nil)
    if from && to 
      sql = "
        SELECT 
          start_date, 
          SUM(CASE WHEN done_ratio < 100 THEN 1 ELSE 0 END) pending, 
          SUM(CASE WHEN done_ratio = 100 THEN 1 ELSE 0 END) completed
        FROM #{Issue.table_name} 
        WHERE
          start_date IS NOT NULL
          AND start_date BETWEEN \'#{from}\' AND \'#{to}\'
        GROUP BY 
          start_date 
        ORDER BY 
          start_date asc"   
    else
      sql = "
        SELECT 
          start_date, 
          SUM(CASE WHEN done_ratio < 100 THEN 1 ELSE 0 END) pending, 
          SUM(CASE WHEN done_ratio = 100 THEN 1 ELSE 0 END) completed
        FROM #{Issue.table_name}     
        WHERE
          start_date IS NOT NULL    
        GROUP BY 
          start_date 
        ORDER BY 
          start_date asc"   
    end

    dates = []
    pending = []    
    completed = []    
    ActiveRecord::Base.connection.select_all(sql).each do |item|
      dates << item['start_date']
      pending << item['pending'].to_i
      completed << item['completed'].to_i
    end
    
    # Acumulate issues count
    sum = 0     
    open_issues_count = dates.zip(pending.collect { |n| sum = sum+n } )  
    
    sum = 0
    closed_issues_count = dates.zip(completed.collect { |n| sum = sum+n } )  

    { :open_issues_count =>  open_issues_count, :closed_issues_count => closed_issues_count }
  end

  def self.issues_by_project_and_date_count(project_id, from = nil, to = nil)
    if from && to 
      sql = "
        SELECT 
          start_date, 
          SUM(CASE WHEN done_ratio < 100 THEN 1 ELSE 0 END) pending, 
          SUM(CASE WHEN done_ratio = 100 THEN 1 ELSE 0 END) completed
        FROM #{Issue.table_name} 
        WHERE
          project_id = #{project_id}
          AND start_date IS NOT NULL
          AND start_date BETWEEN \'#{from}\' AND \'#{to}\'
        GROUP BY 
          start_date 
        ORDER BY 
          start_date asc"   
    else
      sql = "
        SELECT 
          start_date, 
          SUM(CASE WHEN done_ratio < 100 THEN 1 ELSE 0 END) pending, 
          SUM(CASE WHEN done_ratio = 100 THEN 1 ELSE 0 END) completed
        FROM #{Issue.table_name}     
        WHERE
          project_id = #{project_id}
          AND start_date IS NOT NULL    
        GROUP BY 
          start_date 
        ORDER BY 
          start_date asc"   
    end

    dates = []
    pending = []    
    completed = []    
    ActiveRecord::Base.connection.select_all(sql).each do |item|
      dates << item['start_date']
      pending << item['pending'].to_i
      completed << item['completed'].to_i
    end
    
    # Acumulate issues count
    sum = 0     
    open_issues_count = dates.zip(pending.collect { |n| sum = sum+n } )  
    
    sum = 0
    closed_issues_count = dates.zip(completed.collect { |n| sum = sum+n } )  

    { :open_issues_count =>  open_issues_count, :closed_issues_count => closed_issues_count }
  end

  def self.created_issues_by_date(from, to)
    if from && to  
      sql = "
        SELECT SUM(subtotal) total, dates.created 
        FROM ( 
          SELECT COUNT(id) subtotal, date(created_on) as created 
          FROM #{Issue.table_name} 
          WHERE created_on BETWEEN \'#{from}\' AND \'#{to}\' 
          GROUP BY created_on ) as dates
        GROUP BY dates.created
        ORDER BY dates.created ASC"
    else
      sql = "
        SELECT SUM(subtotal) total, dates.created 
        FROM ( SELECT COUNT(id) subtotal, date(created_on) as created FROM #{Issue.table_name} GROUP BY created_on ) as dates
        GROUP BY dates.created
        ORDER BY dates.created asc"      
    end

    ActiveRecord::Base.connection.select_all(sql)
  end

  def self.updated_issues_by_date(from, to)
    if from && to  
      sql = "
        SELECT SUM(subtotal) total, dates.updated 
        FROM ( 
          SELECT COUNT(id) subtotal, date(updated_on) as updated 
          FROM #{Issue.table_name} 
          WHERE updated_on BETWEEN \'#{from}\' AND \'#{to}\' 
          GROUP BY updated_on ) as dates
        GROUP BY dates.updated
        ORDER BY dates.updated ASC"
    else
      sql = "
        SELECT SUM(subtotal) total, dates.updated 
        FROM ( 
          SELECT COUNT(id) subtotal, date(updated_on) as updated 
          FROM #{Issue.table_name}           
          GROUP BY updated_on ) as dates
        GROUP BY dates.updated
        ORDER BY dates.updated ASC"
    end

    ActiveRecord::Base.connection.select_all(sql)
  end

end 