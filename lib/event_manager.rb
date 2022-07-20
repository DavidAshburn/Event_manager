require 'csv'
require './data_sets.rb'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new

civic_info.key = "AIzaSyCEI4OqK8ATpY53vwllidm_6J2-lGgIIIQ"

attendees = Dataset.new

attendees.clean_values

puts "Event manager Initialized!"

form_letters = attendees.legislator_letters

puts form_letters[0] 





