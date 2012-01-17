module DashboardsHelper
  include ApplicationHelper

  def all_issues_count
    Issue.find(:all).count
  end

  def all_issues(offset = 0, limit = 25)        
    Issue.find(:all,
                  :limit => limit,
                  :offset => offset,
                  :joins => [:tracker],
                  :order => "#{Tracker.table_name}.name, #{Issue.table_name}.subject")

  end 
end
