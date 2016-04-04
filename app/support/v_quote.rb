# class Json < Virtus::Attribute
#   def coerce(value)
#     value.is_a?(::Hash) ? value : JSON.parse(value)
#   end
# end

class VQuote
  include Virtus.model

  attribute :tweet_id, Bignum
  attribute :tweet_text, String
end
