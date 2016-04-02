class CreateQuotes < ActiveRecord::Migration
  def change
    create_table :quotes do |t|
      t.integer :tweet_id, :limit => 8
      t.text :tweet_text

      t.timestamps null: false
    end
  end
end
