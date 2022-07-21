require 'csv'
require './data_sets.rb'
require 'google/apis/civicinfo_v2'

attendees = Dataset.new

attendees.clean_values

puts "Event manager Initialized!"

=begin
#Module - Event Manager methods
#display_legislators
Call this to display the list of attendees and their relevant legislators

#legislator_letters
Call this to output the .erb template for each attendee to an output folder

#puts_registration_hours
Call to rank the hours by registrations

#puts_registration_weekdays
Call to rank the days by registrations

=end








