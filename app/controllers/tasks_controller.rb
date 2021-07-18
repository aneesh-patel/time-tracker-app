class TasksController < ApplicationController
  before_action :authenticate_user
  
  def index
    representer = TasksRepresenter.new(all_tasks)
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
        puts (tasks_in_range)
        representer = TasksRepresenter.new(tasks_in_range)
        representer_json = representer.as_json.select do |task|
          all_projects.include?(Project.find_by(task.project_id))
        end
        render json: representer_json
      end
    else
      render json: representer.as_json
    end
  end

  def show
    task = Task.find_by(id: params[:task_id])
    if task && all_tasks.include?(task)
      representer = TaskRepresenter.new(task)
      render json: representer.as_json
    else
      render json: {error: "could not find task with id of #{params[:task_id]}"}, status: :not_found
    end
  end

  def show_for_project
    project = Project.find_by(id: params[:project_id])
    if project && all_projects.include?(project)
      tasks = all_tasks.filter { |task| task.project_id == project.id }
      representer = TasksRepresenter.new(tasks)
      if params[:startDate] && params[:endDate]
        begin
          start_date = CGI.unescape(params[:startDate])
          end_date = CGI.unescape(params[:endDate])
          start_date = start_date.to_datetime
          end_date = end_date.to_datetime
        rescue
          render json: {message: 'must put startDate or endDate parameter in ISO8601 formatted string if passing as a query param'}, status: :unprocessable_entity
        else
          representer_json = representer.as_json.select do |task|
            project = Project.find_by(id: task[:project_id])
            project.start_date >= start_date && project.start_date <= end_date
          end
          render json: representer_json
        end
      else
        render json: representer.as_json
      end
    else
      render json: {error: "could not find project with id of #{params[:project_id]}"}, status: :not_found
    end
  end
end
