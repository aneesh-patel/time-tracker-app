class UsersController < ApplicationController
  before_action :authenticate_user, only: [:show, :update]
  
  def create
    new_user = User.new(user_params)
    # must send params in form {user: {name: 'blah', email: 'blah', password: 'blah', password_confirmation: 'blah'}}

    if new_user.save
      render json: {email: new_user.email, name: new_user.name, auth_token: AuthenticationTokenService.call(new_user.id)}, status: :created
    else
      render json: new_user.errors, status: :unprocessable_entity
    end
  end

  def test
  end 

  def show
    render json: {id: current_user.id, name: current_user.name, email: current_user.email}
  end

  def update
  end



  def index
  end



  private
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  
  
end
