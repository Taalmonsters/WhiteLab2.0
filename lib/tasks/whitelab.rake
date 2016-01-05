namespace :whitelab do
  
  desc "Initialize application for first use."
  task :init => [:reset_db, :precompile, :whenever]
  
  desc "Recreate the query database."
  task :reset_db => :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end
  
  desc "Precompile the web application assets (Javascript, CSS)."
  task :precompile => :environment do
    Rake::Task["assets:precompile"].invoke
  end
  
  desc "Write cron jobs to crontab."
  task :whenever => :environment do
    `whenever -w`
  end

end
