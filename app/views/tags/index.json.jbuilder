json.array!(@tags) do |tag|
  json.extract! tag, :id, :value
  json.url tag_url(tag, format: :json)
end
