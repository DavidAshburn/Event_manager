require 'csv'
require './data_sets.rb'

puts "Event manager Initialized!" 

def clean_zip(zipcode)
	zipcode.to_s.rjust(5,'0')[0..4]
end

list = Dataset.new

list.clean_values

puts list.print('zipcode')


