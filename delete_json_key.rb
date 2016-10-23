require 'json'

if ARGV.size == 0
  raise "No input file provided!"
  exit
elsif ARGV.size == 1
  raise "No key provided!"
  exit
end

unless File.exists?(ARGV[0])
  raise "File not found: #{ARGV[0]}"
  exit
end

hash = JSON.parse(File.read(ARGV[0])).tap { |hs| hs.delete(ARGV[1]) }
File.open(ARGV[0], "w") do |file|
  file.write hash.to_json
end
