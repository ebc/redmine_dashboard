# Dashboard - Administrative Dashboard
# EBC - Empresa Brasil de Comunicacao
# Author: Daniel Negri
# Date: 07/12/2011

class DashboardsController < ApplicationController
  helper :custom_fields
  helper :projects    
  helper :queries
  helper :timelog
  helper :sort  
  include DashboardsHelper
  include QueriesHelper  
  include IssuesHelper
  include SortHelper
  include TimelogHelper
  unloadable

  before_filter :find_project, :only => [:index]  
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  # TODO - Refactoring
  def index
    # Retrieve date range
    retrieve_date_range 

    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    if @query.valid?
      @limit = per_page_option

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
      @offset ||= @issue_pages.current.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)           
           
      @done_ratio = 0.0
      @remaining_ratio = 0.0
      all_issues = @query.issues            
      unless all_issues.empty?
        @done_ratio = all_issues.inject(0) { |sum, item| sum + item.done_ratio } / all_issues.count.to_f
        @remaining_ratio = 100.0 - @done_ratio
      end                    
    end   

    # Load project tree for select
    @project_values = select_project_values    
    
    respond_to do |format|
      format.html { render :layout => "dashboards"}
    end          

  rescue ActiveRecord::RecordNotFound
    render_404    
  end    
    

private
  # Find project of id params[:project_id]
  def find_project
    return nil unless params[:project_id]
    @project = Project.find(params[:project_id])
    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.all
    @trackers = @project.rolled_up_trackers
    cond = @project.project_condition(Setting.display_subprojects_issues?)
    @open_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])
    @total_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => cond)
    if User.current.allowed_to?(:view_time_entries, @project)
      @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end


end
