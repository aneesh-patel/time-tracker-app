class Source < ApplicationRecord
  belongs_to :user
  has_many :workspaces, dependent: :destroy
end
