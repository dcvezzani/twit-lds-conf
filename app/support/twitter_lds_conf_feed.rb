module TwitterLdsConfFeed
  
  def fetch_twitter_lds_conf_feed(count)
    count = (count) ? count : 20
    count = 200 if count > 200

    @settings = Settings.load

    access_token = prepare_access_token(@settings[:AccessToken], @settings[:AccessTokenSecret])
    resp = access_token.request(:get, "https://api.twitter.com/1.1/statuses/user_timeline.json?count=#{count}&screen_name=LDSquotable")

    resp_body = JSON.load(resp.body)
    persist_feed_results(resp_body) if(resp.code == "200")

    resp
  end

  private

  def persist_feed_results(content)
    content.map do |entry|
      tweet_id = entry['id']
      tweet_text = entry['text']

      current_tags = Tag.all.map(&:value)

      tag_values = entry['entities']['hashtags'].map{|x| x['text']}
      exsiting_tag_values = tag_values.select{|x| current_tags.include?(x)}
      new_tag_values = tag_values - exsiting_tag_values

      #"#{tweet_id}:#{tweet_text}:existing ==> #{exsiting_tag_values.join(",")}:new ==> #{new_tag_values.join(",")}"

      unless( Quote.where(["tweet_id = ?", tweet_id]).count > 0 )
        new_tag_attrs = (new_tag_values.length > 0) ? new_tag_values.inject([]){|arr, tag| arr << {value: tag}} : []

        q = Quote.new({tweet_id: tweet_id, tweet_text: tweet_text})
        q.tags.build(new_tag_attrs) if new_tag_attrs.length > 0

        Quote.transaction do
          q.save
        end

        Quote.transaction do
          existing_tag_attrs = (exsiting_tag_values.length > 0) ? exsiting_tag_values.inject([]){|arr, tag| 
            fnd = Tag.where(["value = ?", tag]).first
            raise "should have found tag, but didn't find it: #{tag}" if fnd.nil?

            arr << {quote_id: q.id, tag_id: fnd.id}
          } : []

          if existing_tag_attrs.length > 0
            q.tags_quotes.build(existing_tag_attrs)
            q.save
          end
        end
      end
    end
  end

  def prepare_access_token(oauth_token, oauth_token_secret)
      consumer = OAuth::Consumer.new(@settings[:APIKey], @settings[:APISecret], { :site => "https://api.twitter.com", :scheme => :header })
       
      # now create the access token object from passed values
      token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
      access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
   
      return access_token
  end
    
end

