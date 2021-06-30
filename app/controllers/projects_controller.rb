class ProjectsController < ApplicationController
  before_action :authenticate_user

  def index
    representer = ProjectsRepresenter.new(all_projects)
    render json: representer.as_json
  end

  def show
  end

  private

  
  
end
