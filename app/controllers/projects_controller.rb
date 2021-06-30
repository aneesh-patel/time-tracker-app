class ProjectsController < ApplicationController
  before_action :authenticate_user

  def index
    representer = ProjectsRepresenter.new(all_projects)
    render json: representer.as_json
  end

  def show
    project_id = params[:project_id]
    project = Project.find_by(id: project_id)
    representer = ProjectRepresenter.new(project)
    render json: representer.as_json
  end
end
