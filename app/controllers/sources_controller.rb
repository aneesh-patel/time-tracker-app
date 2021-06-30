class SourcesController < ApplicationController
  before_action :authenticate_user, only: [:create, :show, :delete, :update]
  def index
    UpdateHarvestJob.perform_later()
    render json: {message: "Job performed successfully"}, status: :ok
  end

  def create
  
    new_source = Source.new(source_params)
    
    new_source.user_id = current_user.id

    if new_source.save
      render json: { id: new_source.id, name: new_source.name, access_token: new_source.access_token, account_id: new_source.account_id }, status: :created
    else
      render json: new_user.errors, status: :unprocessable_entity
    end
  end

  def show
  end

  def delete
  end

  def update
  end

  private
  def source_params
    params.require(:source).permit(:name, :access_token, :account_id)
  end
end
