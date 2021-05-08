# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

# rubocop:disable Metrics/MethodLength
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
# rubocop:enable Metrics/MethodLength

def open_csv
  CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

# rubocop:disable Metrics/MethodLength
def create_form_letter
  contents = open_csv

  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
  end
end
# rubocop:enable Metrics/MethodLength

def clean_home_phone(phone)
  phone.gsub!(/[^0-9]/, '')
  phone.delete_prefix!('1') if phone.length == 11 # && phone[0] == '1'
  phone.length != 10 ? 'Bad Number' : phone
end

def format_date_day(csv)
  csv.each_with_object([]) do |row, a|
    a.push(DateTime.strptime(row[:regdate].to_s, '%m/%d/%Y %k:%M').wday)
  end
end

def format_date_hour(csv)
  csv.each_with_object([]) do |row, a|
    a.push(DateTime.strptime(row[:regdate].to_s, '%m/%d/%Y %k:%M').hour)
  end
end

def peak_occurance(array)
  hash = array.each_with_object(Hash.new(0)) { |time, h| h[time] += 1 }
  maxvalue = (hash.max_by { |_k, v| v })[1]
  hash.delete_if { |_k, v| v < maxvalue }
  hash.keys
end

def peak_registration_hours
  peak_occurance(format_date_hour(open_csv))
end

def most_popular_day
  Date::DAYNAMES[peak_occurance(format_date_day(open_csv))[0]]
end

puts 'EventManager initialized.', "\n"

puts 'Form Letter(s) created.' if create_form_letter
puts

puts 'Home Phones:'
open_csv.each { |row| puts "#{row[:first_name].ljust(10)}: #{clean_home_phone(row[:homephone])}" }
puts

print 'Peak Registration At:'
peak_registration_hours.each { |time| print " #{time}00 Hours." }
puts

puts "Most Popular Day: #{most_popular_day}"

puts "\n", 'EventManager done.'
