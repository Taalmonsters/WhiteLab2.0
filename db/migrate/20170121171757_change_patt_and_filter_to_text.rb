class ChangePattAndFilterToText < ActiveRecord::Migration
  def change
    remove_index :explore_queries, :filter
    remove_index :search_queries, :patt
    remove_index :search_queries, :filter
    change_column :explore_queries, :patt, :text
    change_column :explore_queries, :filter, :text
    change_column :search_queries, :patt, :text
    change_column :search_queries, :filter, :text
  end
end
