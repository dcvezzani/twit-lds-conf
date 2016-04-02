class Quote < ActiveRecord::Base
  has_many :tags_quotes
  has_many :tags, through: :tags_quotes

  paginates_per 25
end
