class TimeEntriesRepresenter
  def initialize(time_entries)
    @time_entries = time_entries
  end

  def as_json
    time_entries.map do |time_entry|
      {
        id: time_entry.id,
        duration_seconds: time_entry.duration_seconds,
        task_id: time_entry.task_id,
        started_at: time_entry.started_at,
        project_id: time_entry.task.project.id,
      }
    end
  end

  private

  attr_reader :time_entries

end