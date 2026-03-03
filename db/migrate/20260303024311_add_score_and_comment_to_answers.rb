class AddScoreAndCommentToAnswers < ActiveRecord::Migration[7.2]
  def change
    add_column :answers, :score, :integer
    add_column :answers, :comment, :string
  end
end
