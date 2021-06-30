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
