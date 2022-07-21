require 'csv'
require './data_sets.rb'
require 'google/apis/civicinfo_v2'

attendees = Dataset.new

attendees.clean_values

puts "Event manager Initialized!"

attendees.puts_registration_weekdays








