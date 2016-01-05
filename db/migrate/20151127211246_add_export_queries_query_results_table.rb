class AddExportQueriesQueryResultsTable < ActiveRecord::Migration
  def change
    create_table 'export_queries_query_results', :id => false do |t|
      t.column :export_query_id, :integer
      t.column :query_result_id, :integer
    end
  end
end
