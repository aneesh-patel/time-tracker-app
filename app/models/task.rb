class Task < ApplicationRecord
  belongs_to :project
  has_many :time_entries, dependent: :destroy
end
