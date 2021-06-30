class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token

  private

  # Authenticates user from JWT passed in Authorization header for each request
  def authenticate_user
    # Authorization: Bearer <token> is the header the user will pass
    token, _options = token_and_options(request)
  end
end
