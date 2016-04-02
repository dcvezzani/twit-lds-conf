class CreateTagsQuotes < ActiveRecord::Migration
  def change
    create_table :tags_quotes do |t|
      t.integer :tag_id
      t.integer :quote_id

      t.timestamps null: false
    end
  end
end
