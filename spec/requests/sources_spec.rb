require 'rails_helper'

RSpec.describe 'Sources', type: :request do
  ACCESS_TOKEN = "2693794.pt.PsGJ7k_Tpcn63qb9rNaD7D6wmunEXpEkoZ5IvbbgwYAusXWtY6SRcoeHpm1sNPfJxiDzmMCqB1pjkukAoI3d6A"
  ACCOUNT_ID = "1460632"
  AUTH_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMSJ9.M1vu6qDej7HzuSxcfbE6KAMekNUXB3EWtxwS0pg4UGg'
  AUTH_HEADER = "Bearer #{AUTH_TOKEN}"
  before do
    User.create(name: 'aneesh', email: 'patel.aneeesh@gmail.com', password_digest: '$2a$12$NwQQyH5nfA2oJ/1cGjzthekaDjXqq82aNN.PMaVgAboyVBYSLmqzm')
    Source.create(name: 'harvest', access_token: ACCESS_TOKEN, account_id: ACCOUNT_ID, user_id: 1)
  end

  it 'retrieves all the sources for the user from get /sources' do
    get '/sources', headers: {'Authorization': AUTH_HEADER, 'Content-Type': 'application/json'}
    expect(response).to have_http_status(:ok)
    expect(response.body).to match('harvest')
    expect(response.body).to eq([{
      id: 1,
      name: 'harvest',
      access_token: ACCESS_TOKEN,
      account_id: ACCOUNT_ID,
    }].to_json)
  end

  it 'shows correct source when given correct source id and source id accessible to user' do
    get '/sources/1', headers: {'Authorization': AUTH_HEADER, 'Content-Type': 'application/json'}
    expect(response).to have_http_status(:found)
  end



end