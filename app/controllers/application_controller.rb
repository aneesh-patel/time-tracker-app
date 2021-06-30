class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token

  private

  # Authenticates user from JWT passed in Authorization header for each request
  def authenticate_user
    # Authorization: Bearer <token> is the header the user will pass
    token, _options = token_and_options(request)
    user_id = AuthenticationTokenService.decode(token).to_i
    @current_user = User.find(user_id)
  rescue ActiveRecord::RecordNotFound
    render status: :unauthorized
  rescue JWT::DecodeError
    render status: :unauthorized
  end

  # Finds user that sent request
  def current_user
    @current_user
  end

  # Gets all Sources for current user
  def all_sources
    sources = current_user.sources
  end

  def all_workspaces
    workspaces = []
    all_sources.each do |source|
      source_workspaces = source.workspaces
      source_workspaces.each do |workspace|
        workspaces.push(workspace)
      end
    end
    return workspaces
  end

  # Gets all projects for current user
  def all_projects
    projects = [];
    all_workspaces.each do |workspace|
      workspace_projects = workspace.projects
      workspace_projects.each do |project|
        projects.push(project)
      end
    end
    return projects
  end




end
