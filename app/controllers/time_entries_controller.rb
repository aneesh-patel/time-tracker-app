class TimeEntriesController < ApplicationController
  before_action :authenticate_user
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def index
    representer = TimeEntriesRepresenter.new(all_time_entries)
    if params[:startDate] && params[:endDate]
      begin
        start_date = CGI.unescape(params[:startDate])
        end_date = CGI.unescape(params[:endDate])
        start_date = start_date.to_datetime
        end_date = end_date.to_datetime
      rescue
        render json: {message: 'must put startDate or endDate parameter in ISO8601 formatted string if passing as a query param'}, status: :unprocessable_entity
      else
        representer = representer.as_json
        representer = representer.select do |time_entry|
          time_entry[:started_at] >= start_date && time_entry[:started_at] <= end_date unless time_entry[:started_at].nil?
        end
        render json: representer
      end
    else
      render json: representer.as_json
    end
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
      if params[:startDate] && params[:endDate]
        begin
          start_date = CGI.unescape(params[:startDate])
          end_date = CGI.unescape(params[:endDate])
          start_date = start_date.to_datetime
          end_date = end_date.to_datetime
        rescue
          render json: {message: 'must put startDate or endDate parameter in ISO8601 formatted string if passing as a query param'}, status: :unprocessable_entity
        else
          representer = representer.as_json
          representer = representer.select do |time_entry|
            time_entry[:started_at] >= start_date && time_entry[:started_at] <= end_date
          end
          render json: representer
        end
      else
        render json: representer.as_json
      end
    else
      render json: {error: "could not find task with id of #{params[:task_id]}"}, status: :not_found
    end
  end

  private

  
  def parameter_missing(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
