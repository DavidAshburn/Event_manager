require 'csv'

$data = CSV.read('./event_attendees_full.csv')

module EventManager
	def clean_values
		clean = dataset.each do |line|
			line.zipcode = line.zipcode.to_s.rjust(5,'0')[0..4]
			line.first_name = line.first_name.downcase.capitalize
		end
		clean
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