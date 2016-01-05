class CreateQueryResults < ActiveRecord::Migration
  def change
    create_table :query_results do |t|
      t.string :patt
      t.string :filter
      t.string :within, :default => 'document'
      t.integer :view, :default => 1
      t.string :group
      t.string :sort
      t.string :order
      t.integer :status, :default => 0
      t.integer :offset, :default => 0
      t.integer :number, :default => 50
      t.text :result, :limit => 16.megabyte
      t.integer :hit_count
      t.integer :document_count
      t.integer :group_count

      t.timestamps null: false
    end

    add_index :query_results, :patt
    add_index :query_results, :filter
    add_index :query_results, :created_at
    add_index :query_results, :updated_at
  end
end
