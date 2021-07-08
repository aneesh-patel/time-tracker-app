class FetchData
  include Mongoid::Document

  field :user_id,              type: String
  field :source,               type: String
  field :source_user_id,       type: String
  field :resource,             type: String
  field :resource_original_id, type: String
  field :payload

end
