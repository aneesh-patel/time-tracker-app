require 'rails_helper'

RSpec.describe 'User Endpoint', type: :request do
  AUTH_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMSJ9.M1vu6qDej7HzuSxcfbE6KAMekNUXB3EWtxwS0pg4UGg'
  AUTH_HEADER = "Bearer #{AUTH_TOKEN}"

  it 'returns user object for /users/me' do
    User.create(name: 'aneesh', email: 'patel.aneeesh@gmail.com', password_digest: '$2a$12$NwQQyH5nfA2oJ/1cGjzthekaDjXqq82aNN.PMaVgAboyVBYSLmqzm')
    get '/users/me', headers: {'Authorization': AUTH_HEADER, 'Content-Type': 'application/json'}
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq({
      id: 1,
      name: 'aneesh',
      email: 'patel.aneeesh@gmail.com',
    }.to_json)
  end

  it 'successfully creates a user' do
    post '/users', params: {user: {name: 'JK Rowling', email: 'jkrowling@example.com', password: 'foobar', password_confirmation: 'foobar'}}
    expect(response).to have_http_status(:created)
    expect(response.body).to eq({
      id: 1,
      email: 'jkrowling@example.com',
      name: 'JK Rowling',
      auth_token: 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.DiPWrOKsx3sPeVClrm_j07XNdSYHgBa3Qctosdxax3w',
    }.to_json)
  end


end