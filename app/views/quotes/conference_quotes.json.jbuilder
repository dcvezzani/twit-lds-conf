# json.quotes @quotes, :id, :tweet_id, :tweet_text, :tag_value, :tag_values

# json.array! @quotes do |quote|
#   json.set! quote.tag_value do
#     json.set! :quote_id, quote.id
#     json.set! :tweet_id, quote.tweet_id
#     json.set! :tweet_text, quote.tweet_text
#     json.set! :tag_values, quote.tag_values
#   end
# end

json.quotes @quotes.inject({}){ |hash, quote| 
  if(!hash.has_key?(quote.tag_value))
    hash[quote.tag_value] = []
  end
  hash[quote.tag_value] << {id: quote.id, tweet_id: quote.tweet_id, tweet_text: quote.tweet_text, tag_values: quote.tag_values}
  hash
}
