class User < ApplicationRecord
  has_many :sources, dependent: :destroy
  validates :email, uniqueness: true
  validates :email, presence: true
  has_secure_password
end
