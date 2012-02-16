require 'redmine'

Redmine::Plugin.register :redmine_dashboard do
  name 'Dashboard plugin for Redmine'
  author 'Daniel Negri'
  description 'Custom extension for EBC Dashboards'
  version '0.0.1'
  url 'http://redmine.ebc'
  author_url 'http://blog.danielnegri.com'
    
  permission :dashboards, {:dashboards => [:index] }, :public => true
  menu :application_menu, :dashboards, { :controller => "dashboards", :action => 'index'}, :caption => 'Dashboards'
end
