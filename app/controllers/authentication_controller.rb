class AuthenticationController < ApplicationController
  class AuthenticationError < StandardError
  end
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from AuthenticationError, with: :handle_unauthenticated

  def create
    user = User.find_by(email: params.require(:email))
    raise AuthenticationError unless user.authenticate(params.require(:password))
    jwt = AuthenticationTokenService.call(user.id)
    update_databases()

    render json: { auth_token: jwt }, status: :created
  end

  private

  def parameter_missing(e)
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def handle_unauthenticated
    head :unauthorized
  end

end
