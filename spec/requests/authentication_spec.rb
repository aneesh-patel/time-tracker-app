require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  before do
    User.create(name: 'aneesh', email: 'patel.aneeesh@gmail.com', password_digest: '$2a$12$NwQQyH5nfA2oJ/1cGjzthekaDjXqq82aNN.PMaVgAboyVBYSLmqzm')
  end
  it 'returns correct jwt when correct credentials are used' do
    post '/authenticate', params: {email: 'patel.aneeesh@gmail.com', password: 'foobar'}
    expect(response).to have_http_status(:created)
    expect(response.body).to eq({
      auth_token: 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.DiPWrOKsx3sPeVClrm_j07XNdSYHgBa3Qctosdxax3w'
    }.to_json)
  end

  it 'returns correct status when missing password param' do
    post '/authenticate', params: {email: 'patel.aneeesh@gmail.com'}
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns correct status when missing email param' do
    post '/authenticate', params: {password: 'foobar'}
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'returns correct status when password is wrong' do
    post '/authenticate', params: {email: 'patel.aneeesh@gmail.com', password: 'foobaz'}
    expect(response).to have_http_status(:unauthorized)
  end
  
end