class UsersController < ApplicationController
  before_action :dump_all_data_harvest, only: [:index]

  def index
  end


  private

  # Pulls out time_entry data from Harvest API
  def pull_time_entries_harvest(user_id)
    harvest_uri = URI("https://api.harvestapp.com/v2/time_entries?user_id=#{user_id}")

    Net::HTTP.start(harvest_uri.host, harvest_uri.port, use_ssl: true) do |http|
      harvest_request = Net::HTTP::Get.new harvest_uri

      harvest_request["Authorization"] = "Bearer #{harvest_access_token}"
      harvest_request["Harvest-Account-ID"] = harvest_account_id
      harvest_request["User-Agent"] = harvest_user_agent
      
      harvest_response = http.request harvest_request
      json_response = JSON.parse(harvest_response.body)
      return json_response["time_entries"]
    end
  end


  # Pulls out tasks from Harvest API
  def pull_tasks_harvest
    harvest_uri = URI("https://api.harvestapp.com/v2/task_assignments")

    Net::HTTP.start(harvest_uri.host, harvest_uri.port, use_ssl: true) do |http|
      harvest_request = Net::HTTP::Get.new harvest_uri

      harvest_request["Authorization"] = "Bearer #{harvest_access_token}"
      harvest_request["Harvest-Account-ID"] = harvest_account_id
      harvest_request["User-Agent"] = harvest_user_agent
      
      harvest_response = http.request harvest_request
      json_response = JSON.parse(harvest_response.body)
      return json_response["task_assignments"]
    end

  end

  # Pulls out all projects from Harvest API
  def pull_projects_harvest
    harvest_uri = URI("https://api.harvestapp.com/v2/projects")

    Net::HTTP.start(harvest_uri.host, harvest_uri.port, use_ssl: true) do |http|
      harvest_request = Net::HTTP::Get.new harvest_uri

      harvest_request["Authorization"] = "Bearer #{harvest_access_token}"
      harvest_request["Harvest-Account-ID"] = harvest_account_id
      harvest_request["User-Agent"] = harvest_user_agent
      
      harvest_response = http.request harvest_request
      json_response = JSON.parse(harvest_response.body)
      return json_response["projects"]
    end
  end

  # Puts tasks info in FetchData - MongoDB Database
  def dump_tasks_harvest
    tasks = pull_tasks_harvest()
    user_id = get_user_id_harvest()
    tasks.each do |task|
      task_id = task["id"]
      same_task = FetchData.where(resource_original_id: task_id, source: 'harvest', resource: 'task').to_a
      if same_task.length == 0
        FetchData.create!(user_id: '1', source_user_id: user_id, payload: task, resource_original_id: task_id, source: 'harvest', resource: 'task')
      else
        FetchData.where(resource_original_id: task_id, source: 'harvest').update(payload: task)
      end
    end
  end

  # Puts time_entry info in FetchData - MongoDB Database
  def dump_time_entries_harvest
    user_id = get_user_id_harvest()
    time_entries = pull_time_entries_harvest(user_id)
    time_entries.each do |time_entry|
      same_time_entry = FetchData.where(resource_original_id: time_entry["id"], source: 'harvest', resource: 'time_entry').to_a
      if same_time_entry.length == 0
        FetchData.create!(user_id: '1', source_user_id: user_id, payload: time_entry, resource_original_id: time_entry["id"], source: 'harvest', resource: 'time_entry')
      else
        FetchData.where(resource_original_id: time_entry["id"], source: 'harvest').update(payload: time_entry)
      end
    end
  end

  # Puts projects info in FetchData - MongoDB Database
  def dump_projects_harvest
    projects = pull_projects_harvest()
    projects.each do |project|
      same_project = FetchData.where(resource_original_id: project["id"], source: 'harvest').to_a
      if same_project.length == 0
        FetchData.create!(user_id: '1', source_user_id: get_user_id_harvest(), resource_original_id: project["id"], payload: project, source: 'harvest', resource: 'project')
      else
        FetchData.where(resource_original_id: project["id"], source: 'harvest').update(payload: project)
      end
    end
  end

  def dump_all_data_harvest
    dump_projects_harvest()
    dump_tasks_harvest()
    dump_time_entries_harvest()
  end
end
