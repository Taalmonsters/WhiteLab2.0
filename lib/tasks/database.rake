namespace :database do
  desc "Clear old records from database"
  task :clean => [:clean_explore, :clean_search]

  desc "Clear old Explore Queries from database"
  task :clean_explore => :environment do
    ExploreQuery.where("updated_at < ?", 7.days.ago).destroy_all
  end

  desc "Clear old Search Queries from database"
  task :clean_search => :environment do
    SearchQuery.where("updated_at < ?", 7.days.ago).destroy_all
  end

end
