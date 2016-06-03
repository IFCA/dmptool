class CreateInstitutionStatistics < ActiveRecord::Migration
  def change
    create_table :institution_statistics do |t|
      t.integer :institution_id
      t.string  :month
      
      t.integer :total_users
      t.integer :new_users
      t.integer :unique_users
      
      t.integer :new_completed_plans
      t.integer :new_public_plans
      t.integer :total_public_plans
      
      t.integer :most_used_public_template
      t.integer :new_plans_using_public_template
      t.integer :total_plans_using_public_template

      t.timestamps
    end
  end
end