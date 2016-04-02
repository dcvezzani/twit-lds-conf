json.array!(@quotes) do |quote|
  json.extract! quote, :id, :tweet_id, :tweet_text
  json.url quote_url(quote, format: :json)
end
