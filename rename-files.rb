
require 'bundler/setup'
require 'exifr/jpeg'
require 'fileutils'
require 'optparse'

DEFAULT_DATETIME_FORMAT = "%Y-%m-%d-%H.%M.%S"

OptionsStruct = Struct.new(:directory_path, :custom_format, :custom_file_prefix)

def main()
  options = OptionsStruct.new

  OptionParser.new do |parser|
    parser.on("-d", "--directory DIRECTORY", "Directory path is required") do |d|
      options.directory_path = d
    end
    parser.on("-f", "--format FORMAT", "Provide custom format") do |f|
      options.custom_format = f
    end
    parser.on("-c", "--custom CUSTOM", "Set custom file prefix") do |c|
      options.custom_file_prefix = c
    end
  end.parse!

  unless options.directory_path
    p "Missing directory_path argument"
    return
  end

  options.custom_format ||= DEFAULT_DATETIME_FORMAT
  unless valid_strftime_format?(options.custom_format)
    p "Invalid custom format"
    return
  end

  rename_files_in_directory(options)
end

def valid_strftime_format?(custom_format)
  begin
    Time.now.strftime(custom_format)
    true
  rescue ArgumentError
    false
  end
end

def rename_files_in_directory(options)
  return p "Directory does not exist! #{options.directory_path}" unless Dir.exist?(options.directory_path)

  Dir.foreach(options.directory_path) do |file|
    next if file == '.' || file == '..' # Skip special entries

    current_file_path = File.join(options.directory_path, file)
    next unless File.file?(current_file_path)

    rename_file(file, current_file_path, options)
  end
end

def rename_file(file, current_file_path, options)
  custom_file_prefix = options.custom_file_prefix ? "#{options.custom_file_prefix}-" : ""
  formated_creation_time = get_formated_creation_time(current_file_path, options.custom_format)
  extension = File.extname(file)
  current_directory = File.dirname(current_file_path)

  i = 0
  begin
    new_name = "#{custom_file_prefix}#{formated_creation_time}-#{i.to_s.rjust(3, '0')}#{extension}"
    new_name = new_name.sub(/-000#{extension}/, "#{extension}") if new_name.end_with?("-000#{extension}") # remove trailing 000 for for first file
    new_file_path = File.join(current_directory, new_name)

    if current_file_path == new_file_path
      p "Keep current name: #{new_name}"
      return
    end

    i += 1
  end while File.exist?(new_file_path)

  File.rename(current_file_path, new_file_path)
  p "Renamed: #{file} -> #{new_name}"
end

def get_formated_creation_time(file_path, datetime_format)
  exif = EXIFR::JPEG.new(file_path)
  date_time_taken = exif.date_time

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

main()

