class TimeEntriesController < ApplicationController
  before_action :authenticate_user
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def index
    representer = TimeEntriesRepresenter.new(all_time_entries)
    render json: representer.as_json
  end

  def show
    time_entry = TimeEntry.find_by(id: params[:time_entry_id])
    if time_entry && all_time_entries.include?(time_entry)
      representer = TimeEntryRepresenter.new(time_entry)
      render json: representer.as_json
    else
      render json: {error: "could not find time entry with id of #{params[:time_entry]}"}, status: :not_found
    end
  end

  def show_for_task
    task = Task.find_by(id: params[:task_id])
    if task && all_tasks.include?(task)
      time_entries = all_time_entries.filter { |time_entry| time_entry.task_id == task.id }
      representer = new TimeEntriesRepresenter(time_entries)
      render json: representer.as_json
    else
      render json: {error: "could not find task with id of #{params[:task_id]}"}, status: :not_found
    end
  end

  private

  
  def parameter_missing(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end
end