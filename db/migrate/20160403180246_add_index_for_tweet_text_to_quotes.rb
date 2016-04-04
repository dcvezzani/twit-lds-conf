class AddIndexForTweetTextToQuotes < ActiveRecord::Migration
  def change
    add_index :quotes, :tweet_text
  end
end
