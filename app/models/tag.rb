class Tag < ActiveRecord::Base
  has_many :tags_quotes
  has_many :quotes, through: :tags_quotes
end
