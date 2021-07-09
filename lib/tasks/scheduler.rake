desc "This task is called by the Heroku scheduler add-on"
task :update_database => :environment do
  Source.all.each do |source| do
    if source.name == 'harvest'
      UpdateHarvestPollingJob.perform_later(source.user_id)
    elsif source.name == 'clockify'
      UpdateClockifyJob.perform_later(source.user_id)
    elsif source.name == 'toggl'
      UpdateTogglJob.perform_later(source.user_id)
    end
  end
end
