# frozen_string_literal: false

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

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

def create_form_letter
  contents = open_csv

  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    id = row[0]
    # name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
  end
end

def clean_home_phone(phone)
  phone.gsub!(/[^0-9]/, '')
  phone.delete_prefix!('1') if phone.length == 11 # && phone[0] == '1'
  phone.length != 10 ? 'Bad Number' : phone
end

def peak_registration_hours
  contents = open_csv
  array = []
  contents.each do |row|
    array.push(
      DateTime.strptime(row[:regdate].to_s, '%m/%d/%Y %k:%M').hour
    )
  end
  array.reduce(Hash.new(0)) { |total, e| total[e] += 1; total }
  # hash.sort
  # array.sort!
  # array[0]
end

puts 'EventManager initialized.', "\n"

# create_form_letter

# home_phone = clean_home_phone(row[:homephone])

answer = peak_registration_hours
puts "Peak Registration Hours: #{answer}"

# 11/25/08 19:21
# newdate = DateTime.strptime('11/25/08 19:21', '%m/%d/%Y %k:%M')
# puts newdate
# puts newdate.strftime('%k')
# puts newdate.hour

puts "\n", 'EventManager done.'
