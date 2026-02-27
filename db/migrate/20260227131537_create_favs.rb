class CreateFavs < ActiveRecord::Migration[7.2]
  def change
    create_table :favs do |t|
      t.integer :user_id
      t.integer :joke_id
      t.timestamps
    end
  end
end
