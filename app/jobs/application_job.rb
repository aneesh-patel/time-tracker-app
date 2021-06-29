class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Gets associated user's harvest source
  def harvest_source
    # Will have to change how we find source after JWTs are implemented
    Source.find_by(user_id: 1, name: 'harvest')
  end

  # Gets harvest account_id
  def harvest_account_id
    return harvest_source.account_id || harvest_source
  end

  # Gets harvest access_token
  def harvest_access_token
    return harvest_source.access_token || harvest_source
  end

  # Creates fake harvest user agent field
  def harvest_user_agent
    return "TimeTrackingConsolidator (patel.aneeesh@gmail.com)"
  end


  # Get API Data from Harvest API
  def get_user_id_harvest
    harvest_uri = URI("https://api.harvestapp.com/v2/users/me")

    Net::HTTP.start(harvest_uri.host, harvest_uri.port, use_ssl: true) do |http|
      harvest_request = Net::HTTP::Get.new harvest_uri

      harvest_request["Authorization"] = "Bearer #{harvest_access_token}"
      harvest_request["Harvest-Account-ID"] = harvest_account_id
      harvest_request["User-Agent"] = harvest_user_agent
      
      harvest_response = http.request harvest_request
      json_response = JSON.parse(harvest_response.body)
      return json_response["id"]
    end
  end
end
