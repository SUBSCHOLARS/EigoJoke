class CreateJokes < ActiveRecord::Migration[7.2]
  def change
    create_table :jokes do |t|
      t.string :joke
      t.string :translation
      t.string :explanation
      t.string :key_exp
      t.timestamps
    end
  end
end
