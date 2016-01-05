class CreateExportQueries < ActiveRecord::Migration
  def change
    create_table :export_queries do |t|
      t.integer :user_id
      t.string :input_page
      t.string :patt
      t.string :filter
      t.string :within, :default => 'document'
      t.integer :view, :default => 1
      t.string :group
      t.string :sort
      t.string :order
      t.integer :status, :default => 0
      t.integer :offset, :default => 0
      t.integer :number, :default => 1000

      t.timestamps null: false
    end

    add_index :export_queries, :patt
    add_index :export_queries, :user_id
    add_index :export_queries, :filter
    add_index :export_queries, :created_at
    add_index :export_queries, :updated_at
  end
end
