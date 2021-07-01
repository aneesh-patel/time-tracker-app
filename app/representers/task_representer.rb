class TaskRepresenter
  def initialize(task)
    @task = task
  end

  def as_json
    {
      id: task.id,
      name: task.name,
      project_id: task.project_id,
    }
  end


  private

  attr_reader :task

end