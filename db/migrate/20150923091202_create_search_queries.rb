class CreateSearchQueries < ActiveRecord::Migration
  def change
    create_table :search_queries do |t|
      t.string :query_id
      t.string :patt, :null => false
      t.string :filter
      t.string :input_page, :default => 'expert'
      t.string :view_page, :default => 'expert'
      t.integer :user_id, :null => false
      t.integer :query_result_id

      t.timestamps null: false
    end

    add_index :search_queries, :query_id
    add_index :search_queries, :patt
    add_index :search_queries, :user_id
    add_index :search_queries, :filter
    add_index :search_queries, :created_at
    add_index :search_queries, :updated_at
  end
end
