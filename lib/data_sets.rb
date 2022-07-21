require 'csv'
require 'erb'
require 'date'
require 'google/apis/civicinfo_v2'

$data = CSV.read('./event_attendees.csv')

module EventManager
  def clean_values
    dataset.each do |line|
      phone = []
      line.zipcode = line.zipcode.to_s.rjust(5, '0')[0..4]
      line.first_name = line.first_name.downcase.capitalize
      line.homephone.split('').each do |char|
        phone.push(char) if char.match?(/[[:digit:]]/)
      end
      line.homephone = if phone.length < 10 || phone.length > 11
                         'Bad Number'
                       elsif phone.length == 11
                         if (phone[0] = '1')
                           "(#{phone[1..3].join})#{phone[4..6].join}-#{phone[7..10].join}"
                         else
                           'Bad Number'
                         end
                       else
                         "(#{phone[0..2].join})#{phone[3..5].join}-#{phone[6..9].join}"
                       end
    end
  end

  def display_legislators
    @civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    @civic_info.key = 'AIzaSyCEI4OqK8ATpY53vwllidm_6J2-lGgIIIQ'
    list = []
    dataset.each do |row|
      begin
        legislators = @civic_info.representative_info_by_address(
          address: row.zipcode,
          levels: 'country',
          roles: %w[legislatorUpperBody legislatorLowerBody]
        )
        legislators = legislators.officials.map(&:name)

        legislators = legislators.join(' - ')
      rescue StandardError
        legislators = 'Find your representatives at www.commoncause.org/take-action/find-elected-officials'
      end

      list.push("#{row.first_name} #{row.last_name} : #{row.zipcode} : #{row.homephone} : #{legislators}")
    end

    puts list
  end

  def legislator_letters
    @civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    @civic_info.key = 'AIzaSyCEI4OqK8ATpY53vwllidm_6J2-lGgIIIQ'
    form = File.read('form_letter.erb')

    letters_out = []
    dataset.each do |row|
      begin
        legislators = @civic_info.representative_info_by_address(
          address: row.zipcode,
          levels: 'country',
          roles: %w[legislatorUpperBody legislatorLowerBody]
        )
        legislators = legislators.officials
      rescue StandardError
        legislators = "We couldn't find your legislators."
      end

      template = ERB.new(form)

      this_letter = template.result(binding)

      Dir.mkdir('output') unless Dir.exist?('output')

      filename = "output/thanks_#{row.id}.html"

      File.open(filename, 'w') do |file|
        file.puts this_letter
      end
    end

    letters_out
  end

#ID,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode
#1, 11/12/08 10:47,


  
  def puts_registration_hours
    hours = dataset.each_with_object(Hash.new(0)) do |dataline, hours| 
      hours[dataline.regdate.split(' ')[1].split(':')[0]] += 1
    end
    hours.sort_by { |k,v| -v }.each do |k,v|
      puts "#{v} registrations after #{k} o'clock"
    end
  end

  def which_day(date)
    if(date.monday?)
      return 'Monday'
    elsif(date.tuesday?)
      return 'Tuesday'
    elsif(date.wednesday?)
      return 'Wednesday'
    elsif(date.thursday?)
      return 'Thursday'
    elsif(date.friday?)
      return 'Friday'
    elsif(date.saturday?)
      return 'Saturday'
    elsif(date.sunday?)
      return 'Sunday'
    end
  end

  def puts_registration_weekdays
    days = dataset.each_with_object(Hash.new(0)) do |dataline, days|
      date = dataline.regdate.split(' ')[0].split('/')
      day = Date.new("20#{date[2]}".to_i,date[0].to_i,date[1].to_i)
      days[which_day(day)] += 1
    end
    days.sort_by { |k,v| -v }.each do |k,v|
      puts "#{v} registrations on #{k}s"
    end
  end
  
end

class Dataline
  class << self
    def define_getters(attributes)
      attributes.each do |attribute|
        define_method attribute.to_sym do # needs no argument other than attribute
          return instance_variable_get("@#{attribute}")
        end
      end
    end

    def define_setters(attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=") do |arg|
          return instance_variable_set("@#{attribute}", arg)
        end
      end
    end

    def define_initialize(attributes)
      define_method(:initialize) do |*args| # handles an arbitrary number of arguments
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
        attribute.downcase.gsub(' ', '_').gsub('-', '_').gsub(/[^_,A-Za-z]/, '')
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
    dataset.map { |dataline| dataline.send(attribute).to_f }.reduce(:+) / dataset.count
    # pulls out a single attribute.to_f from each, reduces with addition and takes the mean
  end

  def tally(attribute)
    dataset.map do |dataline|
      dataline.send(attribute)
    end.each_with_object(Hash.new(0)) { |item, tally| tally[item] += 1 }
  end

  def print(attribute)
    dataset.map { |dataline| dataline.send(attribute) }
  end

  def each(&block)
    dataset.each(&block)
  end

  def where(conditions)
    results = dataset.find_all do |dataline|
      conditions.all? do |key, value|
        dataline.send(key) == value
      end
    end
    dataset.new(results)
  end
end
