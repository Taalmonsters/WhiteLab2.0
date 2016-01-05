class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name, :null => false
      t.string :session_id
      t.string :default_locale, :default => 'nl'

      t.timestamps null: false
    end
    
    add_index :users, :name
  end
end
