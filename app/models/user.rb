class User < ApplicationRecord
  has_many :sources, dependent: :destroy
end
