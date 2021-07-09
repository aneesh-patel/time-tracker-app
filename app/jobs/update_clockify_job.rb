class UpdateClockifyJob < ApplicationJob
  def perform(user_id)
    @user_id = user_id
  end


end