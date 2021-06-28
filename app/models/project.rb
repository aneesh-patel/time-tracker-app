class Project < ApplicationRecord
  belongs_to :workspace
  has_many :tasks, dependent: :destroy
end
