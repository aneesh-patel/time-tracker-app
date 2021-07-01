class TimeEntryRepresenter
  def initialize(time_entry)
    @time_entry = time_entry
  end

  def as_json
    {
      id: time_entry.id,
      duration_seconds: time_entry.duration_seconds,
      task_id: time_entry.task_id,
      started_at: time_entry.started_at,
      project_id: time_entry.task.project.id,
    }
  end

  private

  attr_reader :time_entry

end