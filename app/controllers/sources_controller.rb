class SourcesController < ApplicationController
  before_action :authenticate_user, only: [:index, :create, :show, :destroy, :update]
  def index
    representer = SourcesRepresenter.new(all_sources)
    render json: representer.as_json
  end

  def test
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
    source = Source.find_by(id: params[:source_id])
    if source && all_sources.include?(source)
      render json: { id: source.id, name: source.name, access_token: source.access_token, account_id: source.account_id }, status: :found
    else
      render json: {error: "Could not find source with id of #{params[:source_id]}"}, status: :not_found
    end
  end

  def destroy
    source = Source.find_by(id: params[:source_id])
    if source && all_sources.include?(source)
      source.destroy!
      head :no_content
    else
      render json: {error: "Could not find source with id of #{params[:source_id]}"}, status: :not_found
    end
  end

  def update
    source = Source.find_by(id: params[:source_id])
    if source && all_sources.include?(source)
      source.name = source_params[:name]
      source.access_token = source_params[:access_token]
      source.account_id = source_params[:account_id]
      if source.save
        render json: { id: source.id, name: source.name, access_token: source.access_token, account_id: source.account_id }, status: :found
      else
        render json: source.errors, status: :unprocessable_entity
      end
    else
      render json: {error: "could not find source with source id of #{params[:source_id]}"}, status: :not_found
    end
  end

  private
  def source_params
    params.require(:source).permit(:name, :access_token, :account_id)
  end
end
