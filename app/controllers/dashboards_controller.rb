# Dashboard - Administrative Dashboard
# EBC - Empresa Brasil de Comunicacao
# Autor: Daniel Negri
# Data: 07/12/2011

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

  # before_filter :find_project, :only => [:index]    

  def index
    # Retrieve date range
    retrieve_date_range

    # Load issues data table 
    @per_page = params[:per_page].present? ? params[:per_page].to_i : per_page_option    
    @issue_count = all_issues_count({:from => @from, :to => @to})
    @issue_pages = Paginator.new self, @issue_count, @per_page, params[:page]          
    @issues = all_issues({ :from => @from, :to => @to, :offset => @issue_pages.current.offset, :limit => @per_page }) 
    
    
    # Calculate done ratio   
    issues_done_ratio = IssuesDashboard.issues_done_ratio(@from, @to)
    @total = issues_done_ratio[:total]
    @done_ratio = issues_done_ratio[:done_ratio]
    @remaining_ratio = issues_done_ratio[:remaining_ratio]

    # Calculate total of issues grouped by start date    
    issues_by_date_count = IssuesDashboard.issues_by_date_count(@from, @to)  
    @open_issues = issues_by_date_count[:open_issues_count]
    @closed_issues = issues_by_date_count[:closed_issues_count]            
  rescue ActiveRecord::RecordNotFound
    render_404    
  end 

  def collaborators

  end
  
private
  def find_project    
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end
