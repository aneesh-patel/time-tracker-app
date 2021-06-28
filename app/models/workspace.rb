class Workspace < ApplicationRecord
  belongs_to :source
  has_many :projects, dependent: :destroy
end
