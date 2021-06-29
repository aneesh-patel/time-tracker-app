class User < ApplicationRecord
  has_many :sources, dependent: :destroy
  has_secure_password
end
