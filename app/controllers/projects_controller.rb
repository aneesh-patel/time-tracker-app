class ProjectsController < ApplicationController
  before_action :authenticate_user

  def index
    representer = ProjectsRepresenter.new(all_projects)
    if params[:startDate] && params[:endDate]
      begin
        start_date = CGI.unescape(params[:startDate])
        end_date = CGI.unescape(params[:endDate])
        start_date = start_date.to_datetime
        end_date = end_date.to_datetime
      rescue
        render json: {message: 'must put startDate or endDate parameter in ISO8601 formatted string if passing as a query param'}, status: :unprocessable_entity
      else
        time_range = (start_date)..(end_date)
        tasks_in_range = Task.joins(:time_entries).where(time_entries: { started_at: time_range }).distinct
        tasks_in_range = tasks_in_range.select do |task|
          all_projects.include?(Project.find_by(task.project_id))
        end
        projects_in_range = tasks_in_range.map do |task|
          Project.find_by(task.project_id)
        end
        representer = ProjectsRepresenter.new(projects_in_range)
        representer_json = representer.as_json.select do |project|
          all_workspaces.include?(project[:workspace_id])
        end
        render json: representer_json
      end
    else
      render json: representer.as_json
    end
  end

  def show
    project_id = params[:project_id]
    project = Project.find_by(id: project_id)
    if project && all_projects.include?(project)
      representer = ProjectRepresenter.new(project)
      render json: representer.as_json
    else
      render json: {error: "could not find project with id of #{project_id}"}, status: :not_found
    end
  end

  def map_by_time
    begin
      start_date = CGI.unescape(params.require(:startDate)).to_datetime
      end_date = CGI.unescape(params.require(:endDate)).to_datetime
    rescue
      render json: {message: "You must put valid datetimes for startDate and endDate, preferably in ISO8601 format"}, status: :unprocessable_entity
    else
      sorted = sort_time_entries_by_date_grouped_by_project(start_date, end_date)
      render json: sorted, status: :ok
    end
  end

  private
  
  # Will need to optimize === currently is O(3N)
  def sort_time_entries_by_date_grouped_by_project(start_date, end_date)
    sorted = {}
    all_projects.each do |project|
      sorted[project.name] = Project.find_by(id: project.id).tasks.sum do |task| 
        task.time_entries.sum do |time_entry| 
          if (time_entry.started_at >= start_date && time_entry.started_at <= end_date)
            time_entry.duration_seconds
          else
            0
          end
        end
      end
    end
    return sorted
  end

end
