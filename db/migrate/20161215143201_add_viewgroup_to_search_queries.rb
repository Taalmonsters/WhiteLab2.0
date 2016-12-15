class AddViewgroupToSearchQueries < ActiveRecord::Migration
  def change
    add_column :search_queries, :viewgroup, :string
  end
end
