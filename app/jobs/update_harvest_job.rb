class UpdateHarvestJob < ApplicationJob
  queue_as :default

  def perform(*user_id)
    @user_id = user_id[0]
    dump_all_data_harvest()
    projects = FetchData.where(user_id: user_id[0], resource: 'project', source: 'harvest').to_a
    tasks = FetchData.where(user_id: user_id[0], resource: 'task', source: 'harvest').to_a
    time_entries = FetchData.where(user_id: user_id[0], resource: 'time_entry', source: 'harvest').to_a
    normalize_projects_harvest(projects)
    normalize_tasks_harvest(tasks)
    normalize_time_entries_harvest(time_entries)
  end

  private
  attr_reader :user_id

  # Time for one month ago - only want to pull data 1 month old
  def last_updated_time
    CGI.escape(1.month.ago.to_date.to_formatted_s)
  end
  # Gets harvest workspace
  def harvest_workspace
    Workspace.find_by(source_id: Source.find_by(user_id: user_id, name: 'harvest').id)
  end

  # Puts mongodb data into projects table from Harvest
  def normalize_projects_harvest(projects)

    projects.each do |project|
      
      found_project = Project.find_by(original_id: project["resource_original_id"])
      if found_project
        found_project.due_date = project["payload"]["ends_on"]
        found_project.start_date = project["payload"]["starts_on"]
        found_project.workspace_id = harvest_workspace.id
        found_project.name = project["payload"]["name"]
      else
        found_project = Project.create!(
          original_id: project["resource_original_id"],
          name: project["payload"]["name"],
          due_date: project["payload"]["ends_on"],
          start_date: project["payload"]["starts_on"],
          workspace_id: harvest_workspace.id,
        )
      end
    end
  end

  # Puts mongodb data into tasks table from Harvest
  def normalize_tasks_harvest(tasks)
    tasks.each do |task|
      project_original_id = task["payload"]["project"]["id"].to_s
      project = Project.find_by(workspace_id: harvest_workspace.id, original_id: project_original_id)
      found_task = Task.find_by(project_id: project.id, original_id: task["payload"]["task"]["id"].to_s)
      if found_task
        found_task.name = task["payload"]["task"]["name"]
      else
        found_task = Task.create!(project_id: project.id, name: task["payload"]["task"]["name"], original_id: task["payload"]["task"]["id"].to_s)
      end
    end
  end


  # Puts mongodb data into time_entries table from Harvest

  def normalize_time_entries_harvest(time_entries)
    time_entries.each do |time_entry|
      project_original_id = time_entry["payload"]["project"]["id"].to_s
      task_original_id = time_entry["payload"]["task"]["id"].to_s
      project = Project.find_by(original_id: project_original_id, workspace_id: harvest_workspace.id)
      task = Task.find_by(original_id: task_original_id, project_id: project.id)
    
      original_id = time_entry["payload"]["id"].to_s
      
      found_time_entry = TimeEntry.find_by(original_id: original_id)
      duration_seconds = (time_entry["payload"]["hours"] * 60 * 60).to_i
      started_at = time_entry["payload"]["spent_date"].to_datetime
      if found_time_entry
        found_time_entry.update(duration_seconds: duration_seconds)
        found_time_entry.update(started_at: started_at)
      else
        found_time_entry = TimeEntry.create!(task_id: task.id, started_at: started_at, duration_seconds: duration_seconds, original_id: original_id)
      end
    end
  end

  # Pulls out time_entry data from Harvest API
  def pull_time_entries_harvest(user_id)
    harvest_uri = URI("https://api.harvestapp.com/v2/time_entries?user_id=#{user_id}&from=#{last_updated_time}")

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
    harvest_user_id = get_user_id_harvest()
    tasks.each do |task|
      task_id = task["id"]
      same_task = FetchData.where(resource_original_id: task_id, source: 'harvest', resource: 'task').to_a
      if same_task.length == 0
        FetchData.create!(user_id: user_id, source_user_id: harvest_user_id, payload: task, resource_original_id: task_id, source: 'harvest', resource: 'task')
      else
        FetchData.where(resource_original_id: task_id, source: 'harvest', resource: 'task').update(payload: task)
      end
    end
  end

  # Puts time_entry info in FetchData - MongoDB Database
  def dump_time_entries_harvest
    harvest_user_id = get_user_id_harvest()
    time_entries = pull_time_entries_harvest(harvest_user_id)
    time_entries.each do |time_entry|
      same_time_entry = FetchData.where(resource_original_id: time_entry["id"], source: 'harvest', resource: 'time_entry').to_a
      if same_time_entry.length == 0
        FetchData.create!(user_id: user_id, source_user_id: harvest_user_id, payload: time_entry, resource_original_id: time_entry["id"], source: 'harvest', resource: 'time_entry')
      else
        FetchData.where(resource_original_id: time_entry["id"], source: 'harvest').update(payload: time_entry)
      end
    end
  end

  # Puts projects info in FetchData - MongoDB Database
  def dump_projects_harvest
    projects = pull_projects_harvest()
    projects.each do |project|
      same_project = FetchData.where(resource_original_id: project["id"], source: 'harvest', resource: 'project').to_a
      if same_project.length == 0
        FetchData.create!(user_id: user_id, source_user_id: get_user_id_harvest(), resource_original_id: project["id"], payload: project, source: 'harvest', resource: 'project')
      else
        FetchData.where(resource_original_id: project["id"], source: 'harvest', resource: 'project').update(payload: project)
      end
    end
  end

  def dump_all_data_harvest
    dump_projects_harvest()
    dump_tasks_harvest()
    dump_time_entries_harvest()
  end


  # Gets associated user's harvest source
  def harvest_source
    Source.find_by(user_id: user_id, name: 'harvest')
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
