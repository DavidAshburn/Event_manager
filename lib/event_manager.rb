require 'csv'
require './data_sets.rb'
require 'google/apis/civicinfo_v2'

attendees = Dataset.new

attendees.clean_values

puts "Event manager Initialized!"

form_letters = attendees.legislator_letters

puts form_letters[0..3] 








