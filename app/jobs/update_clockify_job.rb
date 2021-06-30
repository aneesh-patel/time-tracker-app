class UpdateClockifyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
  end
end

# Jose's code unaltered
require 'uri'
require 'net/http'
require 'json'
​
​
def request_simple_clockify(clockify_api_key, endpoint)
  uri = URI.parse("https://api.clockify.me/api/v1/#{endpoint}")
  request = Net::HTTP::Get.new(uri)
  request.content_type = "application/json"
  request["X-Api-Key"] = clockify_api_key
  req_options = {
    use_ssl: uri.scheme == "https",
  }
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end
​
  data = JSON.parse(response.body)
  return data
end
​
def request_projects_clockify(clockify_api_key, workspace_ids)
  # Return a user's Clockify projects
  projects = []
​
  workspace_ids.each do |id|
    uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{id}/projects")
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
    projects.push(data)
  end
  projects
end
​
def extract_ids(payload)
  # Get the user's workspace ids
  ids = []
  payload.each { |hash| ids.push(hash["id"]) }
  ids
end
​
def extract_project_ids(payload)
  data = []
  payload.each do |subarray|
    subarray.each { |hash| data.push([hash['id'], hash['workspaceId']]) }
  end
​
  data
end
​
def request_tasks_clockify(clockify_api_key, project_ids)
  tasks = []
​
  project_ids.each do |ids|
    uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{ids[1]}/projects/#{ids[0]}")
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
    tasks.push(data)
  end
  tasks
end
​
def request_time_entries_clockify(clockify_api_key, workspace_ids, user_id)
  time_entries = []
​
  workspace_ids.each do |workspace|
    uri = URI.parse("https://api.clockify.me/api/v1/workspaces/#{workspace}/user/#{user_id}/time-entries")
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
​
# Puts time_entry info in FetchData - MongoDB Database
def dump_data(payload)
  # user_id is provisional and reflects our user's internal id
  FetchData.create!(user_id: '1', payload: payload, source: 'clockify')
end
​
def consolidate_payloads_clockify(user_payload, workspaces_payload, projects_payload, tasks_payload, time_entries_payload)
  # Consolidate all of the payloads into a single hash
  payloads = {
    user_payload: user_payload,
    workspaces_payload: workspaces_payload,
    projects_payload: projects_payload,
    tasks_payload: tasks_payload,
    time_entries_payload: time_entries_payload
  }
​
  payloads
end

def orchestrate_request_data_clockify(api_key)
  # Extract all payloads and return a hash with all of them
  user_payload = request_simple_clockify(api_key, 'user')
  user_id = user_payload["id"]
​
  workspaces_payload = request_simple_clockify(api_key, 'workspaces')
  workspace_ids = extract_ids(workspaces_payload)
​
  projects_payload = request_projects_clockify(api_key, workspace_ids)
  project_ids = extract_project_ids(projects_payload)
​
  tasks_payload = request_tasks_clockify(api_key, project_ids)
​
  time_entries_payload = request_time_entries_clockify(api_key, workspace_ids, user_id)
​
  consolidate_payloads_clockify(user_payload, workspaces_payload, projects_payload, tasks_payload, time_entries_payload)
end
