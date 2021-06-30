class ProjectRepresenter
  def initialize(project)
    @project = project
  end

  def as_json
    {
      id: project.id,
      name: project.name,
      start_date: project.start_date,
      due_date: project.due_date,
      source: project.workspace.source_name,
    }
  end

  private

  attr_reader :project
end