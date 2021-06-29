class SourcesController < ApplicationController
  def index
    UpdateHarvestJob.perform_later()
    render json: {message: "Job performed successfully"}, status: :ok
  end

  def create
  end

  def show
  end

  def delete
  end

  def update
  end
end
