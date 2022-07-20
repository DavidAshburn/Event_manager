require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'



$data = CSV.read('./event_attendees.csv')

module EventManager

	

	def clean_values
		clean = dataset.each do |line|
			line.zipcode = line.zipcode.to_s.rjust(5,'0')[0..4]
			line.first_name = line.first_name.downcase.capitalize
		end
		clean
	end

	def display_legislators()

		@civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
		@civic_info.key = "AIzaSyCEI4OqK8ATpY53vwllidm_6J2-lGgIIIQ"
		list = []
		dataset.each do |row|

			begin
				legislators = @civic_info.representative_info_by_address(
					address: row.zipcode, 
					levels: 'country', 
					roles: ['legislatorUpperBody', 'legislatorLowerBody']
				)
				legislators = legislators.officials.map(&:name)

				legislators = legislators.join(" - ")
			rescue
				legislators = 'Find your representatives at www.commoncause.org/take-action/find-elected-officials'
			end 

			list.push("#{row.first_name} #{row.last_name} : #{row.zipcode} : #{legislators}")
		end

		puts list

	end

	def legislator_letters
		
		@civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
		@civic_info.key = "AIzaSyCEI4OqK8ATpY53vwllidm_6J2-lGgIIIQ"
		form = File.read('form_letter.erb')


		letters_out = []
		dataset.each do |row|

			begin
				legislators = @civic_info.representative_info_by_address(
					address: row.zipcode, 
					levels: 'country', 
					roles: ['legislatorUpperBody', 'legislatorLowerBody']
				)
				legislators = legislators.officials

			rescue
				legislators = "We couldn't find your legislators."
			end 

			template = ERB.new(form)

			this_letter = template.result(binding)

			Dir.mkdir('output') unless Dir.exist?('output')

			filename = "output/thanks_#{row.id}.html"

			File.open(filename,"w") do |file|
				file.puts this_letter
			end

		end

		return letters_out
	end
end


class Dataline
	
	class << self
		def define_getters(attributes)
			attributes.each do |attribute|
				define_method attribute.to_sym do #needs no argument other than attribute
					return instance_variable_get("@#{attribute}")
				end
			end
		end

		def define_setters(attributes)
			attributes.each do |attribute|
				define_method ("#{attribute}=") do |arg|
					return instance_variable_set("@#{attribute}", arg)
				end
			end
		end

		def define_initialize(attributes)
			define_method(:initialize) do |*args| #handles an arbitrary number of arguments
				attributes.zip(args) do |attribute, value|
					instance_variable_set("@#{attribute}", value)
				end
			end
		end
	end
end

class Dataset
	include Enumerable
	include EventManager

	attr_reader :dataset

	def initialize(dataset = nil)
		if dataset.nil?

			attributes = $data[0].map do |attribute|
				attribute.downcase.gsub(" ", "_").gsub("-","_").gsub(/[^_,A-Za-z]/, '')
			end

			table = $data[1..-1]

			Dataline.define_getters(attributes)
			Dataline.define_setters(attributes)
			Dataline.define_initialize(attributes)

			@dataset = table.map do |row|
				Dataline.new(*row)
			end
		else
			@dataset = dataset
		end
	end

	def mean(attribute)
		dataset.map{ |dataline| dataline.send(attribute).to_f }.reduce(:+) / dataset.count
		# pulls out a single attribute.to_f from each, reduces with addition and takes the mean
	end

	def tally(attribute)
		dataset.map{ |dataline| dataline.send(attribute) }.each_with_object(Hash.new(0)) { |item,tally| tally[item] += 1}
	end

	def print(attribute)
		dataset.map{ |dataline| dataline.send(attribute) }
	end

	def each
		dataset.each {|dataline| yield dataline }
	end

	def where(conditions)
		results = dataset.find_all do |dataline|
			conditions.all? do |key,value|
				dataline.send(key) == value
			end
		end
		dataset.new(results)
	end
end