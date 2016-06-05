class CreateSearchQueries < ActiveRecord::Migration
  def change
    create_table :search_queries do |t|
      t.integer :user_id, :null => false
      t.string :patt, :null => false
      t.string :filter
      t.string :within, :default => 'document'
      t.integer :view, :default => 1
      t.string :group
      t.string :sort
      t.string :order
      t.integer :status, :default => 0
      t.integer :offset, :default => 0
      t.integer :number, :default => 50
      t.string :input_page, :default => 'expert'
      t.integer :hit_count
      t.integer :document_count
      t.integer :group_count

      t.timestamps null: false
    end

    add_index :search_queries, :patt
    add_index :search_queries, :user_id
    add_index :search_queries, :filter
    add_index :search_queries, :created_at
    add_index :search_queries, :updated_at
  end
end
