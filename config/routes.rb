Rails.application.routes.draw do
  get  'users/index'
  get      '/test',    to: 'users#test'
  # post   '/users'
  # get    '/users/me'
  # post   '/users/me'
  # get    '/projects'
  # get    '/projects/{project_id}'
  # get    '/projects/{project_id}/tasks',  to: 'tasks#index'
  # get    '/tasks',                        to: 'tasks#index'
  # get    '/tasks/{task_id}'
  # get    '/tasks/{task_id}/time_entries', to: 'time_entries#index'
  # get    '/time_entries'
  # get    '/time_entries/{time_entry_id}'
  # get    '/sources'
  # get    '/sources/{source_id}'
  # post   '/sources'
  # post   '/sources/{source_id}'
  # delete '/sources/{source_id}'
  
    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end