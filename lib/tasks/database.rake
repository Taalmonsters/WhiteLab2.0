namespace :database do
  desc "Clear old records from database"
  task :clean => [:clean_explore, :clean_search, :clean_export, :clean_query_result]

  desc "Clear old Explore Queries from database"
  task :clean_explore => :environment do
    ExploreQuery.where("updated_at < ?", 7.days.ago).delete_all
  end

  desc "Clear old Search Queries from database"
  task :clean_search => :environment do
    SearchQuery.where("updated_at < ?", 7.days.ago).delete_all
  end

  desc "Clear old Export Queries from database"
  task :clean_export => :environment do
    ExportQuery.where("updated_at < ? AND status < ?", 1.hours.ago, 5).each do |query|
      query.update_attribute(:status, 5)
    end
    ExportQuery.where("updated_at < ?", 7.days.ago).delete_all
  end

  desc "Clear stuck and unconnected Explore Query Results from database"
  task :clean_query_result => :environment do
    QueryResult.where("updated_at < ? AND status < ?", 1.hours.ago, 5).each do |query|
      query.update_attribute(:status, 5)
    end
    QueryResult.where("updated_at < ? AND status < ?", 1.days.ago, 10).delete_all
    QueryResult.where("NOT id IN (SELECT DISTINCT query_result_id FROM export_queries_query_results) 
    AND NOT id IN (SELECT DISTINCT query_result_id FROM explore_queries) 
    AND NOT id IN (SELECT DISTINCT query_result_id FROM search_queries)").delete_all
  end

end
