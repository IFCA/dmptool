class CreateEnumerations < ActiveRecord::Migration
  def change
    create_table :enumerations do |t|
      t.integer :requirement_id
      t.string :value

      t.timestamps
    end
  end
end
