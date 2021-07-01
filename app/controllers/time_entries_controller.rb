class TimeEntriesController < ApplicationController
  before_action :authenticate_user

  def index
    representer = TimeEntriesRepresenter.new(all_time_entries)
    render json: representer.as_json
  end

  def show
    time_entry = TimeEntry.find_by(id: params[:time_entry_id])
    if time_entry && all_time_entries.incldue?(time_entry)
      representer = TimeEntryRepresenter.new(time_entry)
      render json: representer.as_json
    else
      render json: {error: "could not find time entry with id of #{params[:time_entry]}"}, status: :not_found
    end

  end
end
