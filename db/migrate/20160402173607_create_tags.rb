class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.text :value

      t.timestamps null: false
    end
  end
end
