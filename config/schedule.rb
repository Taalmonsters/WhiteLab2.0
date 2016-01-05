# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

every 24.hours do
  rake "database:clean"
end

every 1.hours do
  rake "database:clean_query_result"
end


