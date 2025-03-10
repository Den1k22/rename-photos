
require 'bundler/setup'
require 'mini_exiftool'
require 'fileutils'
require 'optparse'

DEFAULT_DATETIME_FORMAT = "%Y%m%d-%H.%M.%S"

def rename_files_in_directory(directory_path, datetime_format, custom_file_prefix)
  return p "Directory does not exist! #{directory_path}" unless Dir.exist?(directory_path)

  Dir.foreach(directory_path) do |file|
    next if file == '.' || file == '..' # Skip special entries
    
    current_file_path = File.join(directory_path, file)
    next unless File.file?(current_file_path)

    rename_file(file, current_file_path, custom_file_prefix, datetime_format)
  end
end

def rename_file(file, current_file_path, custom_file_prefix, datetime_format)
  formated_creation_time = get_formated_creation_time(current_file_path, datetime_format)
  extension = File.extname(file)
  current_directory = File.dirname(current_file_path)

  custom_file_prefix += "-" if !custom_file_prefix.empty?

  new_name = "#{custom_file_prefix}#{formated_creation_time}#{extension}"
  new_file_path = File.join(current_directory, new_name)

  i = 1
  while File.exist?(new_file_path)
    new_name = "#{custom_file_prefix}#{formated_creation_time}-#{i.to_s.rjust(3, '0')}#{extension}"
    new_file_path = File.join(current_directory, new_name)
    i += 1
  end

  File.rename(current_file_path, new_file_path)
  p "Renamed: #{file} -> #{new_name}"
end

def get_formated_creation_time(file_path, datetime_format)
  exif = MiniExiftool.new(file_path)
  date_time_taken = exif.date_time_original

  if date_time_taken
    date_time_taken.strftime(datetime_format)
  else
    file_stat = File.stat(file_path)
    if file_stat.respond_to?(:ctime)
      file_stat.ctime.strftime(datetime_format)
    elsif file_stat.respond_to?(:birthtime) 
      file_stat.birthtime.strftime(datetime_format)
    else
      File.mtime(file_path).strftime(datetime_format)
    end
  end
end

def valid_strftime_format?(custom_format)
  begin
    Time.now.strftime(custom_format)
    true
  rescue ArgumentError
    false
  end
end

options = {}
OptionParser.new do |parser|
  parser.on("-d", "--directory DIRECTORY", "Directory path is required") do |d|
    options[:directory_path] = d
  end
  parser.on("-f", "--format FORMAT", "Provide custom format") do |f|
    options[:custom_format] = f
  end
  parser.on("-c", "Set custom file prefix") do |c|
    options[:custom_file_prefix] = c
  end
end.parse!

unless options[:directory_path]
  p "Missing directory_path argument"
  return
end

options[:custom_format] ||= DEFAULT_DATETIME_FORMAT
options[:custom_file_prefix] ||= ""

if options[:custom_format]
  p "Set custom format: #{options[:custom_format]}"
  unless valid_strftime_format?(options[:custom_format])
    p "Invalid custom format"
    return
  end
end

rename_files_in_directory(options[:directory_path], options[:custom_format], options[:custom_file_prefix])
