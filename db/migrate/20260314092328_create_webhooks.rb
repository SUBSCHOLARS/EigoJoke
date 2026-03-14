class CreateWebhooks < ActiveRecord::Migration[7.2]
  def change
    create_table :webhooks do |t|
      t.integer :user_id
      t.string :name
      t.string :url
      t.timestamps
    end
  end
end
