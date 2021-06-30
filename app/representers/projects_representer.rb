class ProjectsRepresenter
  def initialize(projects)
    @projects =  projects
  end

  def as_json
    projects.map do |project|
      {
        id: project.id,
        name: project.name,
        start_date: project.start_date,
        due_date: project.due_date,
        source: project.workspace.source_name,
      }
    end
  end

  private

  attr_reader :projects

  def project_source_name
  end
end