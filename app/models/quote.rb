class Quote < ActiveRecord::Base
  has_many :tags_quotes
  has_many :tags, through: :tags_quotes

  accepts_nested_attributes_for :tags, reject_if: :all_blank, allow_destroy: true
  
  paginates_per 25

  def add_tags!(tag_values=[])
    return true if tag_values.nil?

    assoc_tags = []
    Quote.transaction do
      existing_tag_values = self.tags.map(&:value)
      (tag_values - existing_tag_values).each do |tag_value|
        fnd_tags = Tag.where(value: tag_value)
        if(fnd_tags.length > 0)
          assoc_tags << fnd_tags.first
        else
          assoc_tags << Tag.create(value: tag_value)
        end
      end

      self.tags << assoc_tags
    end

    return true
  end

  def update_with_tag(params, extra={})
    res = false
    Quote.transaction do
      if extra[:is_applied]

        # if hiding and was favorite, un-favorite
        # if(params[:tag] == 'hide')
        #   fnd_tag = Tag.where(value: 'favorite').first
        #   self.tags.delete(fnd_tag) unless fnd_tag.nil?
        # end

        self.add_tags!([extra[:tag]])
        res = self.update(params)
        
      else
        fnd_tag = Tag.where(value: extra[:tag]).first
        self.tags.delete(fnd_tag) unless fnd_tag.nil?
        res = self.update(params)
      end
    end
    res
  end
end
