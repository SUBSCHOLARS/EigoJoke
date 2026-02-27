class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.integer :user_id
      t.integer :joke_id
      t.string :body
      t.timestamps
    end
  end
end
