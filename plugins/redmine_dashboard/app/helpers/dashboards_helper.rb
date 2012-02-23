module DashboardsHelper
  include ApplicationHelper

  ## TODO - Refactoring
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

  def breadcrumb_links
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
    
    links
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
    @from, @to = nil, nil unless @from && @to

    # TODO - Define filter for all dates
    # @from ||= (TimeEntry.earilest_date_for_project(@project) || Date.civil(Date.today.year, 1, 1) )
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

  def sort_url(column)
    "/dashboards?from=#{@from}&to=#{@to}&project_id=#{params[:project_id]}&sort=#{column}%2Cid%3Adesc"    
  end

  # Retrieve query from session or build a new query
  def retrieve_dashboards_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = DashboardsQuery.find(params[:query_id], :conditions => cond)
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:dashboards_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    else
      if api_request? || params[:set_filter] || session[:dashboards_query].nil? || session[:dashboards_query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = DashboardsQuery.new(:name => "_")
        @query.project = @project if @project        
        if params[:fields] || params[:f]
          @query.filters = {}
          @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
        else
          @query.available_filters.keys.each do |field|
            @query.add_short_filter(field, params[field]) if params[field] && params[field] != ""
          end
        end
        @query.group_by = params[:group_by]
        @query.column_names = params[:c] || (params[:query] && params[:query][:column_names])
        session[:dashboards_query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
      else
        @query = DashboardsQuery.find_by_id(session[:dashboards_query][:id]) if session[:dashboards_query][:id]
        @query ||= DashboardsQuery.new(:name => "_", :project => @project, :filters => session[:dashboards_query][:filters], :group_by => session[:dashboards_query][:group_by], :column_names => session[:dashboards_query][:column_names])
        @query.project = @project
      end
    end
  end

end
