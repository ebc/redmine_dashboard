# Dashboard - Administrative Dashboard
# EBC - Empresa Brasil de Comunicacao
# Author: Daniel Negri
# Date: 07/12/2011

class DashboardsController < ApplicationController
  helper :custom_fields
  helper :projects    
  helper :queries
  helper :timelog
  include DashboardsHelper
  include QueriesHelper  
  include IssuesHelper
  include TimelogHelper
  unloadable

  before_filter :find_project, :only => [:index]  

  # TODO - Refactoring
  def index
    # Retrieve date range
    retrieve_date_range 

    if @project
      # Load issues data table 
      @per_page = params[:per_page].present? ? params[:per_page].to_i : per_page_option    
      @issue_count = all_issues_by_project_count(@project.id, {:from => @from, :to => @to})
      @issue_pages = Paginator.new self, @issue_count, @per_page, params[:page]          
      @issues = all_issues_by_project(@project.id, { :from => @from, :to => @to, :offset => @issue_pages.current.offset, :limit => @per_page }) 
      
      
      # Calculate done ratio   
      issues_done_ratio = IssuesDashboard.issues_by_project_done_ratio(@project.id, @from, @to)
      @total = issues_done_ratio[:total]
      @done_ratio = issues_done_ratio[:done_ratio]
      @remaining_ratio = issues_done_ratio[:remaining_ratio]

      # Calculate total of issues grouped by start date    
      issues_by_date_count = IssuesDashboard.issues_by_project_and_date_count(@project.id, @from, @to)  
      @open_issues = issues_by_date_count[:open_issues_count]
      @closed_issues = issues_by_date_count[:closed_issues_count]                 
    else
      # Load issues by project data table 
      @per_page = params[:per_page].present? ? params[:per_page].to_i : per_page_option    
      @issue_count =  all_issues_count({:from => @from, :to => @to})
      @issue_pages = Paginator.new self, @issue_count, @per_page, params[:page]          
      @issues = all_issues({ :from => @from, :to => @to, :offset => @issue_pages.current.offset, :limit => @per_page })    
    
      # Calculate done ratio by project
      issues_done_ratio = IssuesDashboard.issues_done_ratio(@from, @to)
      @total = issues_done_ratio[:total]
      @done_ratio = issues_done_ratio[:done_ratio]
      @remaining_ratio = issues_done_ratio[:remaining_ratio]

      # Calculate total of issues grouped by project and start date   
      issues_by_date_count = IssuesDashboard.issues_by_date_count(@from, @to)  
      @open_issues = issues_by_date_count[:open_issues_count]
      @closed_issues = issues_by_date_count[:closed_issues_count]       
    end

    # Load project tree for select
    @project_values = select_project_values    
    
    respond_to do |format|
      format.html { render :layout => "dashboards"}
    end          

  rescue ActiveRecord::RecordNotFound
    render_404    
  end  

  def analytics
    # Retrieve date range
    retrieve_date_range

    # Calculate total of issues grouped by start date    
    issues_by_date_count = IssuesDashboard.issues_by_date_count(@from, @to)  
    @open_issues = issues_by_date_count[:open_issues_count]
    @closed_issues = issues_by_date_count[:closed_issues_count]  

    # Calculate total of issues created by date
    @created_issues = IssuesDashboard.created_issues_by_date(@from, @to)

    # Calculate total of issues updated by date
    @updated_issues = IssuesDashboard.updated_issues_by_date(@from, @to)
  rescue ActiveRecord::RecordNotFound
    render_404    
  end 

  def team
    @groups = Group.find(:all, :order => 'lastname')    
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
