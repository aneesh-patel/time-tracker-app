class TasksController < ApplicationController
  before_action :authenticate_user
  
  def index
    representer = TasksRepresenter.new(all_tasks)
    render json: representer.as_json
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
end
