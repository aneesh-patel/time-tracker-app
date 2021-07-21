class UpdateTogglJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    @user_id = user_id
    @api_key = toggl_api_key # Confirm this is ok
    @source_id = toggl_source_id
    @payload = request_data_toggl
    FetchData.create!(payload: @payload, source: 'toggl', source_user_id: @payload["data"]["id"])
    update_toggl_workspaces
    update_toggl_projects
    update_toggl_tasks
    update_toggl_time_entries
  end

  private

  # Gets associated user's Toggl source
  def toggl_source
    Source.find_by(user_id: @user_id, name: 'toggl')
  end

  # Gets Toggl api key
  def toggl_api_key
    toggl_source["access_token"] #|| toggl_source -> Necessary?
  end

  # Gets source id
  def toggl_source_id
    toggl_source["id"] #|| toggl_source -> Necessary?
  end

  def request_data_toggl
    # Returns user and all related data
    uri = URI.parse("https://api.track.toggl.com/api/v8/me?with_related_data=true")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(@api_key, "api_token")

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      response = http.request(request)
      
      data = JSON.parse(response.body)
      return data
    end
  end

  def update_toggl_workspaces
    workspaces_payload = @payload["data"]["workspaces"]
    workspaces_payload.each do |workspace|
      workspace_entry = Workspace.find_by(original_id: workspace["id"])

      if !workspace_entry
        Workspace.create!(
          original_id: workspace["id"],
          source_name: "toggl",
          source_id: @source_id
        )
      end
    end
  end

  def update_toggl_projects
    projects_payload = @payload["data"]["projects"]
    projects_payload.each do |project|
      project_entry = Project.find_by(original_id: project["id"])

      if project_entry
        project_entry["name"] = project["name"]
        project_entry["start_date"] = project["created_at"]
        project_entry["due_date"] = project["at"]
      else
        workspace_id = Workspace.find_by(original_id: project["wid"]).id
        Project.create!(
          original_id: project["id"],
          name: project["name"],
          workspace_id: workspace_id,
          start_date: project["created_at"],
          due_date: project["at"]
        )
      end
    end
  end


  def update_toggl_tasks
    tasks_payload = @payload["data"]["tasks"]
    
    if tasks_payload
      tasks_payload.each do |task|
        task_entry = Task.find_by(original_id: task["id"])
        if task_entry
          task_entry["name"] = task["name"]
        else
          project_id = Project.find_by(original_id: task["pid"]).id
          Task.create!(
            original_id: task["id"],
            name: task["name"],
            project_id: project_id
          )
        end
      end
    end
  end

  def toggl_entry_project_lookup(toggl_entry)
    toggl_entry["pid"] || toggl_entry["id"]
  end

  def update_toggl_time_entries
    time_entries_payload = @payload["data"]["time_entries"]
    return nil unless time_entries_payload
    puts("Made it")
    time_entries_payload.each do |toggl_entry|
      existing_time_entry = TimeEntry.find_by(original_id: toggl_entry["id"].to_s)
      if existing_time_entry
        existing_time_entry["duration_seconds"] = toggl_entry["duration"]
      else
        task = Task.find_by(original_id: toggl_entry["tid"].to_s) # || create_placeholder_task(toggl_entry)
        if task
          task_id = task.id
        elsif task = Task.find_by(original_id: "Generic Task - Workspace - #{toggl_entry["wid"].to_s}")
          task_id = task.id
        else
          new_task = create_placeholder_task(toggl_entry)
          task_id = new_task.id
        end
        TimeEntry.create!(
          original_id: toggl_entry["id"],
          duration_seconds: toggl_entry["duration"],
          started_at: toggl_entry["start"],
          task_id: task_id,
        )
      end
    end
  end

  def create_placeholder_task(toggl_entry)
    original_project = nil
    original_project = Project.find_by(original_id: toggl_entry["pid"]) if toggl_entry["pid"]
    if original_project
      project_id = original_project.id
    else
      new_project = create_placeholder_project(toggl_entry["wid"])
      project_id = new_project.id
    end
    # project_id = !!original_project ? original_project.id : create_placeholder_project(toggl_entry["wid"]).id
    puts "Project ID HERE IS =================== #{project_id}"
    new_task = Task.create!(project_id: project_id, original_id: "Generic Task - Workspace - #{toggl_entry["wid"]}")
    return new_task
  end

  def create_placeholder_project(workspace_id)
    id = Workspace.find_by(original_id: workspace_id.to_s).id
    new_project = Project.create!(workspace_id: id, original_id: "Generic Project - Workspace - #{toggl_entry["wid"]}")
    return new_project
  end
end
