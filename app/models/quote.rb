class Quote < ActiveRecord::Base
  has_many :tags_quotes
  has_many :tags, through: :tags_quotes

  paginates_per 25

  def add_tags!(tag_values=[])
    assoc_tags = []
    Quote.transaction do
      existing_tag_values = self.tags.map(&:value)
      (tag_values - existing_tag_values).each do |tag_value|
        fnd_tags = Tag.where(value: tag_value)
        if(fnd_tags.length > 0)
          assoc_tags << fnd_tags.first
        else
          assoc_tags << Tag.create(tag_value)
        end
      end

      self.tags << assoc_tags
    end
  end
end
