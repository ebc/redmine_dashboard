module DashboardsHelper
  include ApplicationHelper

  ## TODO - Refactoring
  ## Please, fix this code with native Query/QueryColumns class and remove duplicated lines

  def all_issues_count(params = {:from => nil, :to => nil})
    if params[:from].present? && params[:to].present?
      Issue.find(:all, :conditions => ["start_date BETWEEN ? AND ?", params[:from], params[:to]]).count
    else
      Issue.find(:all).count    
    end 
  end

  def all_issues_by_project_count(project_id, params = {:from => nil, :to => nil})
    if params[:from].present? && params[:to].present?
      Issue.find(:all, :conditions => ["project_id = ? AND start_date BETWEEN ? AND ?", project_id, params[:from], params[:to]]).count
    else
      Issue.find(:all, :conditions => ["project_id = ?", project_id]).count    
    end 
  end

  def all_issues(params = {:from => nil, :to => nil, :limit => 25, :offset => 0})        
    if params[:from].present? && params[:to].present?
      Issue.find(:all,                  
                  :joins => [:tracker],
                  :conditions => ["start_date BETWEEN ? AND ?", params[:from], params[:to]],
                  :order => "#{Tracker.table_name}.name, #{Issue.table_name}.subject",
                  :limit => params[:limit],
                  :offset => params[:offset])
    else
      Issue.find(:all,
                  :limit => params[:limit],
                  :offset => params[:offset],
                  :joins => [:tracker],
                  :order => "#{Tracker.table_name}.name, #{Issue.table_name}.subject")
    end
  end 

  def all_issues_by_project(project_id, params = {:from => nil, :to => nil, :limit => 25, :offset => 0})        
    if params[:from].present? && params[:to].present?
      Issue.find(:all,                  
                  :joins => [:tracker],
                  :conditions => ["project_id = ? AND start_date BETWEEN ? AND ?", project_id, params[:from], params[:to]],
                  :order => "#{Tracker.table_name}.name, #{Issue.table_name}.subject",
                  :limit => params[:limit],
                  :offset => params[:offset])
    else
      Issue.find(:all,
                  :conditions => ["project_id = ?", project_id],
                  :limit => params[:limit],
                  :offset => params[:offset],
                  :joins => [:tracker],
                  :order => "#{Tracker.table_name}.name, #{Issue.table_name}.subject")
    end
  end 

  def render_breadcrumb
    links = []
    links << link_to(l(:label_project_all), {:project_id => nil, :issue_id => nil})
    links << link_to(h(@project), {:project_id => @project, :issue_id => nil}) if @project
    if @issue
      if @issue.visible?
        links << link_to_issue(@issue, :subject => false)
      else
        links << "##{@issue.id}"
      end
    end
    breadcrumb links
  end


  def retrieve_date_range
    @free_period = false
    @from, @to = nil, nil

    if params[:period_type] == '1' || (params[:period_type].nil? && !params[:period].nil?)
      case params[:period].to_s
      when 'today'
        @from = @to = Date.today
      when 'yesterday'
        @from = @to = Date.today - 1
      when 'current_week'
        @from = Date.today - (Date.today.cwday - 1)%7
        @to = @from + 6
      when 'last_week'
        @from = Date.today - 7 - (Date.today.cwday - 1)%7
        @to = @from + 6
      when '7_days'
        @from = Date.today - 7
        @to = Date.today
      when 'current_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1)
        @to = (@from >> 1) - 1
      when 'last_month'
        @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
        @to = (@from >> 1) - 1
      when '30_days'
        @from = Date.today - 30
        @to = Date.today
      when 'current_year'
        @from = Date.civil(Date.today.year, 1, 1)
        @to = Date.civil(Date.today.year, 12, 31)
      end
    elsif params[:period_type] == '2' || (params[:period_type].nil? && (!params[:from].nil? || !params[:to].nil?))
      begin; @from = params[:from].to_s.to_date unless params[:from].blank?; rescue; end
      begin; @to = params[:to].to_s.to_date unless params[:to].blank?; rescue; end
      @free_period = true
    else
      # default
    end
    
    @from, @to = @to, @from if @from && @to && @from > @to

    # TODO - Define filter for all dates
    # @from ||= (TimeEntry.earilest_date_for_project(@project) || Date.today)
    # @to   ||= (TimeEntry.latest_date_for_project(@project) || Date.today)
  end

  def total_issues_by_group(group)
    return 0 unless group

    total = 0
    group.users.each do |user|
      total += Issue.count(:conditions => ["author_id=?", user.id])
    end

    total
  end

  def select_project_values
    user_values = []
    user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?

    all_projects = Project.visible.all
    project_values = []
    if all_projects.any?
      # members of visible projects
      user_values += User.active.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", all_projects.collect(&:id)]).sort.collect{|s| [s.name, s.id.to_s] }

      # project filter
      project_values = []
      Project.project_tree(all_projects) do |p, level|
        prefix = (level > 0 ? ('--' * level + ' ') : '')
        project_values << ["#{prefix}#{p.name}", p.id.to_s]
      end
      project_values unless project_values.empty?
    end

    project_values
  end
end
