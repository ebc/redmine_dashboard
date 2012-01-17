# Dashboard - Administrative Dashboard
# EBC - Empresa Brasil de Comunicacao
# Autor: Daniel Negri
# Data: 07/12/2011

class DashboardsController < ApplicationController
  helper :custom_fields
  helper :projects    
  helper :queries
  include DashboardsHelper
  include QueriesHelper  
  include IssuesHelper
  helper :timelog
    
  unloadable

  def index
    # Load issues data table 
    @per_page = params[:per_page].present? ? params[:per_page].to_i : per_page_option    
    @issue_count = all_issues_count
    @issue_pages = Paginator.new self, @issue_count, @per_page, params[:page]            
    @issues = all_issues(@issue_pages.current.offset, @per_page) 
    
    # Calculate done ratio   
    issues_done_ratio = IssuesDashboard.issues_done_ratio
    @total = issues_done_ratio[:total]
    @done_ratio = issues_done_ratio[:done_ratio]
    @remaining_ratio = issues_done_ratio[:remaining_ratio]

    # Calculate total of issues grouped by start date    
    issues_by_date_count = IssuesDashboard.issues_by_date_count  
    @open_issues = issues_by_date_count[:open_issues_count]
    @closed_issues = issues_by_date_count[:closed_issues_count]          
  rescue ActiveRecord::RecordNotFound
    render_404    
  end 
  
private
  def find_project    
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end 

  def retrieve_selected_tracker_ids(selectable_trackers, default_trackers=nil)
    if ids = params[:tracker_ids]
      @selected_tracker_ids = (ids.is_a? Array) ? ids.collect { |id| id.to_i.to_s } : ids.split('/').collect { |id| id.to_i.to_s }
    else
      @selected_tracker_ids = (default_trackers || selectable_trackers).collect {|t| t.id.to_s }
    end
  end
end
