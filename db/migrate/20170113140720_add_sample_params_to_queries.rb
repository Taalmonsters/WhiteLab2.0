class AddSampleParamsToQueries < ActiveRecord::Migration
  def change
    add_column :explore_queries, :sample, :integer
    add_column :explore_queries, :samplenum, :integer
    add_column :explore_queries, :sampleseed, :integer, :limit => 8
    add_column :search_queries, :sample, :integer
    add_column :search_queries, :samplenum, :integer
    add_column :search_queries, :sampleseed, :integer, :limit => 8
  end
end
