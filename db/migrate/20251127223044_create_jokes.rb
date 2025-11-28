class CreateJokes < ActiveRecord::Migration[8.0]
  def change
    create_table :jokes do |t|
      t.string :joke

      t.timestamps
    end
  end
end
