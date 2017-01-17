class AddGapValuesTsvToQueries < ActiveRecord::Migration
  def change
    add_column :explore_queries, :gap_values_tsv, :text
    add_column :search_queries, :gap_values_tsv, :text
  end
end
