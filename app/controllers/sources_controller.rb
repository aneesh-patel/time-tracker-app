class SourcesController < ApplicationController
  before_action :authenticate_user, only: [:index, :create, :show, :destroy, :update, :refresh, :test_for_polling]
  before_action :validates_unique_source, only: [:create]
  def index
    representer = SourcesRepresenter.new(all_sources)
    render json: representer.as_json
  end

  # Refreshed data for user in mongoDB and Sqlite3
  def refresh
    update_databases()
    render json: {message: "Information will be updated shortly"}, status: :ok
  end

  def test_for_polling
    update_databases_polling()
    render json: {message: "testing in progress, fingers crossed"}, status: :ok
  end

  def create
    new_source = Source.new(source_params)
    new_source.user_id = current_user.id
    if new_source.save
      # Creates generic workspace for Harvest clients
      create_harvest_workspace(new_source) if new_source.name == 'harvest'
      render json: { id: new_source.id, name: new_source.name, access_token: new_source.access_token, account_id: new_source.account_id }, status: :created
    else
      render json: new_source.errors, status: :unprocessable_entity
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

  # Does not allow you to update name (will have to delete source if you want to make a new connection to an external API)
  def update
    source = Source.find_by(id: params[:source_id])
    unless source_params[:name] == source.name
      render json: {error: 'You cannot change external api for a source, you must delete that source if you wish to remove it'}, status: :unprocessable_entity
    end
    if source && all_sources.include?(source)
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
  # Parameters for source
  def source_params
    params.require(:source).permit(:name, :access_token, :account_id)
  end

  # Creates Harvest generic workspace 
  def create_harvest_workspace(source)
    Workspace.create!(original_id: 1, source_name: 'harvest', source_id: source.id)
  end

  # Makes sure there are not two sources with same name for a user 
  def validates_unique_source
    source_name = source_params[:name]
    all_sources.each do |source|
      if source.name == source_name
        render json: {error: 'Cannot have two sources with same name, must delete one first'}, status: :unprocessable_entity
      end
    end
  end
end
