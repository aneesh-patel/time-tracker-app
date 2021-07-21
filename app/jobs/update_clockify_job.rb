class UpdateClockifyJob < ApplicationJob
  queue_as :default
  def perform(user_id)
    @user_id = user_id
    @api_key = clockify_api_key
    @source_id = clockify_source_id
    orchestrate_data_dump_clockify
    update_clockify_workspaces
    update_clockify_projects
    update_clockify_tasks
    update_clockify_time_entries
  end
  private
  # === Extract data ===
  # Gets associated user's clockify source
  def clockify_source
    Source.find_by(user_id: @user_id, name: 'clockify')
  end
  # Gets clockify api key
  def clockify_api_key
    clockify_source["access_token"] #|| clockify_source -> Necessary?
  end
  # Gets source id
  def clockify_source_id
    clockify_source["id"] #|| clockify_source -> Necessary?
  end
  # Extract all payloads and return a hash with all of them
  def orchestrate_data_dump_clockify
    # To do: dump per resrouce type as in harvest
    user_payload = request_simple_clockify('user')
    @clockify_user_id = user_payload["id"]
    update_or_create_entry("user", user_payload)
    workspaces_payload = request_simple_clockify('workspaces')
    @workspace_ids = extract_workspace_ids(workspaces_payload)
    update_or_create_entry("workspace", workspaces_payload)
    @projects_payload = request_projects_clockify
    @project_ids = extract_project_ids
    update_or_create_entry("project", @projects_payload)
    @tasks_payload = request_tasks_clockify
    update_or_create_entry("task", @tasks_payload)
    @time_entries_payload = request_time_entries_clockify
    update_or_create_entry("time_entry", @time_entries_payload)
  end
  def request_simple_clockify(endpoint)
    uri = URI.parse("https://api.clockify.me/api/v1/#{endpoint}")
    request = Net::HTTP::Get.new(uri)
    request.content_type = "application/json"
    request["X-Api-Key"] = @api_key
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    data = JSON.parse(response.body)
  end
  def request_projects_clockify
    # Return a user's Clockify projects
    projects = []
    @workspace_ids.each do |id|
      uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{id}/projects")
      request = Net::HTTP::Get.new(uri)
      request.content_type = "application/json"
      request["X-Api-Key"] = @api_key
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      data = JSON.parse(response.body)
      projects.push(data)
    end
    projects
  end
  def request_tasks_clockify
    tasks = []
    @project_ids.each do |ids|
      uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{ids[1]}/projects/#{ids[0]}/tasks")
      request = Net::HTTP::Get.new(uri)
      request.content_type = "application/json"
      request["X-Api-Key"] = @api_key
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      data = JSON.parse(response.body)
      tasks.push(data)
    end
    tasks
  end
  def request_time_entries_clockify
    time_entries = []
    @workspace_ids.each do |workspace|
      uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{workspace}/user/#{@clockify_user_id}/time-entries")
      request = Net::HTTP::Get.new(uri)
      request.content_type = "application/json"
      request["X-Api-Key"] = clockify_api_key
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      data = JSON.parse(response.body)
      time_entries.push(data)
    end
    time_entries
  end
  # === Process request data before Mongo dump ===
  def extract_workspace_ids(payload)
    # Get the user's workspace ids
    ids = []
    payload.each { |hash| ids.push(hash["id"]) }
    ids
  end
  def extract_project_ids
    data = []
    @projects_payload.each do |subarray|
      subarray.each { |hash| data.push([hash['id'], hash['workspaceId']]) }
    end
    data
  end
  def update_or_create_entry(resource_type, payload)
    same_entry = FetchData.where(resource: resource_type, source_user_id: @clockify_user_id)
    if same_entry.length == 0
      FetchData.create!(payload: payload, source: 'clockify', resource: resource_type, source_user_id: @clockify_user_id)
    else
      same_entry.update(payload: payload)
    end
  end
  # === SQL insertion and adaption ===
  def update_clockify_workspaces
    @workspace_ids.each do |id|
      workspace_entry = Workspace.find_by(original_id: id)
      if !workspace_entry
        Workspace.create!(
          original_id: id,
          source_name: "clockify",
          source_id: @source_id
        )
      end
    end
  end
  def update_clockify_projects
    @projects_payload.each do |workspace|
      workspace.each do |project|
        project_entry = Project.find_by(original_id: project["id"])
        if project_entry
          project_entry["name"] = project["name"]
        else
          workspace_id = Workspace.find_by(original_id: project["workspaceId"]).id
          Project.create!(
            original_id: project["id"],
            name: project["name"],
            workspace_id: workspace_id,
            start_date: nil,
            due_date: nil
          )
        end
      end
    end
  end
  def update_clockify_tasks
    @tasks_payload.each do |array|
      array.each do |task|
        task_entry = Task.find_by(original_id: task["id"])
        if !task_entry
          original_project_id = task["projectId"]
          project_id = Project.find_by(original_id: original_project_id).id
          Task.create!(
            project_id: project_id,
            original_id: task["id"],
            name: task["name"]
          )
        end
      end
    end
  end
  def update_clockify_time_entries
    @time_entries_payload.each do |workspace|
      workspace.each do |time_entry|
        existing_time_entry = TimeEntry.find_by(original_id: time_entry["id"])
        if !existing_time_entry
          task = Task.find_by(original_id: time_entry["taskId"]) #|| create_placeholder_task(time_entry)
          if (task)
            task_id = task.id
          elsif (task = Task.find_by(original_id: "Generic Task - Project #{time_entry["projectId"]}"))
            task_id = task.id
          else
            new_task = create_placeholder_task(time_entry)
            task_id = new_task.id
          end
          start_time = DateTime.parse(time_entry["timeInterval"]["start"]).to_time
          end_time = DateTime.parse(time_entry["timeInterval"]["end"]).to_time
          duration = (end_time - start_time).to_i
          TimeEntry.create!(
            duration_seconds: duration,
            original_id: time_entry["id"],
            task_id: task_id,
            started_at: start_time
          )
        end
      end
    end
  end
  def create_placeholder_task(time_entry)
    original_project_id = time_entry["projectId"]
    project_id = Project.find_by(original_id: original_project_id).id
    new_task = Task.create!(
      project_id: project_id,
      original_id: "Generic Task - Project #{original_project_id}" 
    )
    return new_task
  end
end