class ProjectsController < ApplicationController
  before_action :authenticate_user

  def index
    representer = ProjectsRepresenter.new(all_projects)
    render json: representer.as_json
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
    start_date = CGI.unescape(params.require(:startDate)).to_datetime
    end_date = CGI.unescape(params.require(:endDate)).to_datetime
    
    sorted = sort_time_entries_by_date_grouped_by_project(start_date, end_date)
    render json: sorted, status: :ok
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
