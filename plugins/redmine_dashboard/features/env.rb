require 'rubygems'
require 'spork'
require 'spec/expectations'
require 'spec/matchers'

Spork.prefork do
  ENV["RAILS_ENV"] ||= "cucumber"
  require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
  
  require 'cucumber/formatter/unicode'
  require 'cucumber/rails/world'
  require 'cucumber/rails/active_record'
  require 'cucumber/web/tableish'


  require 'capybara/rails'
  require 'capybara/cucumber'
  require 'capybara/session'

  Capybara.default_selector = :css

end
 
Spork.each_run do  
  ActionController::Base.allow_rescue = false  
  
  Cucumber::Rails::World.use_transactional_fixtures = true
  
  if defined?(ActiveRecord::Base)
    begin
      require 'database_cleaner'
      DatabaseCleaner.strategy = :truncation
    rescue LoadError => ignore_if_database_cleaner_not_present
    end
  end
end
