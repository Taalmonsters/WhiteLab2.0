class CreateExploreQueries < ActiveRecord::Migration
  def change
    create_table :explore_queries do |t|
      t.string :query_id
      t.string :patt
      t.string :filter
      t.string :input_page
      t.integer :query_result_id
      t.integer :user_id, :null => false

      t.timestamps null: false
    end

    add_index :explore_queries, :query_id
    add_index :explore_queries, :filter
    add_index :explore_queries, :user_id
    add_index :explore_queries, :input_page
    add_index :explore_queries, :created_at
    add_index :explore_queries, :updated_at
  end
end
