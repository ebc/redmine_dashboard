class ProjectStatus 

  def initialize(proj)
    @project = proj
  end
  
  def project
    @project
  end

  def name 
    @project.name
  end
  
  def versions 
    versions = @project.versions ||= []
  end
  
  def effective_date     
    versions.each do |version|
      @effective_date ||= version.effective_date      
      if ( @effective_date && version.effective_date && @effective_date < version.effective_date )
        @effective_date = version.effective_date  
      end
    end
    
    @effective_date
  end
  
  def completed?
    versions.each do |version|
      return false unless version.completed?
    end 
    
    true
  end
  
  def completed_versions 
    versions = []    
    @project.versions.each do |v|
      versions << v if v.completed?
    end
    versions    
  end 
  
  def closed_pourcent
    @closed_pourcent = 0
    count = 0
    @project.versions.each do |v|
      @closed_pourcent = ( @closed_pourcent + v.closed_pourcent )
      count = count + 1
    end   
    
    @closed_pourcent / count
  end
  
  def completed_pourcent
    @completed_pourcent = 0
    count = 0    
    @project.versions.each do |v|
      @completed_pourcent = ( @completed_pourcent + v.completed_pourcent )
      count = count + 1
    end   
    
    @completed_pourcent / count
  end
    
  def fixed_issues
    @fixed_issues = []
    @project.versions.each do |v|
      @fixed_issues << v.fixed_issues if v.fixed_issues
    end
    @fixed_issues
  end
  
  def empty?
    @project.versions.empty?
  end

  def total_hours 
    cond = @project.project_condition(Setting.display_subprojects_issues?)
    total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
  end 
end