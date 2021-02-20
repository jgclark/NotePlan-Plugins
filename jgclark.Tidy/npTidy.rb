#!/usr/bin/ruby
#-------------------------------------------------------------------------------
# NotePlan Tidy Plugin
# by Jonathan Clark, v0.1.3, 20.2.2021
#-------------------------------------------------------------------------------
# See README.md file for details, how to run and configure it.
# Repository: https://github.com/jgclark/NotePlan-Tidy/
#-------------------------------------------------------------------------------
VERSION = "0.1.3"

require 'date'
require 'time'
require 'cgi'
require 'json'
require 'csv'

#-------------------------------------------------------------------------------
# Setting variables to tweak ... TODO: reduce number here to about zero
#-------------------------------------------------------------------------------
$verbose = false
read_only = false  # for testing, stop any actual re-writing of notes

#-------------------------------------------------------------------------------
# TODO: look these up from the environment, when NP supports this
#-------------------------------------------------------------------------------
# BASE_DATA_DIR = "#{ENV['HOME']}/Library/Containers/co.noteplan.NotePlan3/Data/Library/Application Support/co.noteplan.NotePlan3"
PLUGIN_DIR = '/Users/jonathan/GitHub/NotePlan-Plugins/jgclark.Tidy'
BASE_DATA_DIR = '/tmp'
NP_NOTES_DIR = "#{BASE_DATA_DIR}/Notes".freeze
NP_CALENDAR_DIR = "#{BASE_DATA_DIR}/Calendar".freeze

#-------------------------------------------------------------------------------
# Other Constants & Settings
#-------------------------------------------------------------------------------
JSON_SETTINGS_FILE = "config.json" # assumed to be in the current directory
DATE_TIME_LOG_FORMAT = '%e %b %Y %H:%M'.freeze # only used in logging
DATE_TODAY_FORMAT = '%Y%m%d'.freeze # using this to identify the "today" daily note
USERNAME = ENV['LOGNAME'] # pull username from environment
USER_DIR = ENV['HOME'] # pull home directory from environment
CURRENT_DIR = ENV['PWD'] # pull home directory from environment

# Variables that need to be globally available
time_now = Time.now
time_now_fmttd = time_now.strftime(DATE_TIME_LOG_FORMAT)
$date_today = time_now.strftime(DATE_TODAY_FORMAT)
# $archive = 0
# $allNotes = []  # to hold all note objects
$notes    = []  # to hold all relevant note objects
$npfile_count = 0 # number of NPFile objects created so far (incremented before first use)
$options = {} # to hold settings/options
$tags_to_remove = []

#-------------------------------------------------------------------------
# Helper definitions
#-------------------------------------------------------------------------

def log_message(message)
  puts "log: #{message}"
end

def error_message(message)
  puts "error: #{message}"
end

#-------------------------------------------------------------------------
# Class definition: NPFile
# NB: in this script this class covers Note *and* Daily Calendar files
#-------------------------------------------------------------------------
class NPFile
  # Define the attributes that need to be visible outside the class instances
  attr_reader :id
  attr_reader :title
  attr_reader :cancelled_header
  attr_reader :done_header
  attr_reader :is_today
  attr_reader :is_calendar
  attr_reader :is_updated
  attr_reader :filename
  attr_reader :modified_time

  def initialize(this_file)
    # Create NPFile object from reading 'this_file' file

    # Set variables that are visible outside the class instance
    @id = $npfile_count + 1
    @filename = this_file
    @modified_time = File.exist?(filename) ? File.mtime(this_file) : 0
    @title = ''
    @lines = []
    @line_count = 0
    @cancelled_header = 0
    @done_header = 0
    @is_today = false
    @is_calendar = false
    @is_updated = false

    # initialise other variables (that don't need to persist with the class)
    n = 0

    # Open file and read in all lines (finding any Done and Cancelled headers)
    # NB: needs the encoding line when run from launchctl, otherwise you get US-ASCII invalid byte errors (basically the 'locale' settings are different)
    begin
      f = File.open(@filename, 'r', encoding: 'utf-8')
      f.each_line do |line|
        @lines[n] = line
        @done_header = n  if line =~ /^## Done$/
        @cancelled_header = n if line =~ /^## Cancelled$/
        n += 1
      end
      f.close
    rescue StandardError => e
      error_message("ERROR: #{e.exception.message} when initialising note file #{this_file}")
    end
    @line_count = @lines.size
    # Now make a title for this file:
    if @filename =~ /\d{8}\.(txt|md)$/
      # for Calendar file, use the date from filename
      @title = File.basename(@filename,".*") # remove path and extension suffix
      @is_calendar = true
      @is_today = @title == $date_today
    else
      # otherwise use first line (but take off heading characters at the start and starting and ending whitespace)
      tempTitle = @lines[0].gsub(/^#+\s*/, '').gsub(/\s+$/, '')
      @title = !tempTitle.empty? ? tempTitle : 'temp_header' # but check it doesn't get to be blank
      @is_calendar = false
      @is_today = false
    end

    $npfile_count += 1
    log_message("Initialised NPFile #{@id} from #{this_file}") if $verbose
  end

  def append_new_line(new_line)
    # Append 'new_line' into position
    # TODO: should ideally split on '\n' and add each potential line separately
    log_message('  append_new_line ...') if $verbose
    @lines << new_line
    @line_count = @lines.size
  end

  def clear_empty_tasks_or_headers
    # Clean up lines with just * or - or #s in them
    # puts '  remove_empty_tasks_or_headers ...' if $verbose > 1
    n = cleaned = 0
    while n < @line_count
      # blank any lines which just have a * or -
      if @lines[n] =~ /^\s*[\*\-]\s*$/
        @lines[n] = ''
        cleaned += 1
      end
      # blank any lines which just have #s at the start (and optional following whitespace)
      if @lines[n] =~ /^#+\s?$/
        @lines[n] = ''
        cleaned += 1
      end
      n += 1
    end
    return unless cleaned.positive?

    @is_updated = true
    @line_count = @lines.size
    log_message("  - removed #{cleaned} empty tasks/headers") if $verbose
  end

  def remove_unwanted_dates
    # removes <dates from complete or cancelled tasks
    # log_message('  remove_unwanted_dates ...') if $verbose
    n = 0
    cleaned = 0
    while n < @line_count
      # only do something if this is a completed or cancelled task
      if @lines[n] =~ /\[(x|-)\]/
        # remove any <YYYY-MM-DD on completed or cancelled tasks
        if (@lines[n] =~ /\s<\d{4}-\d{2}-\d{2}/)
          @lines[n].gsub!(/\s<\d{4}-\d{2}-\d{2}/, '')
          cleaned += 1
        end
      end
      n += 1
    end
    return unless cleaned.positive?

    @is_updated = true
    log_message("  - removed #{cleaned} dates") if $verbose
  end

  def remove_unwanted_tags
    # removes specific tags from complete or cancelled tasks
    # log_message('  remove_unwanted_tags ...') if $verbose
    n = 0
    cleaned = 0
    while n < @line_count
      # only do something if this is a completed or cancelled task
      if @lines[n] =~ /\[(x|-)\]/
        # Remove any tags from the TagsToRemove list. Iterate over that array:
        $tags_to_remove.each do |tag|
          if (@lines[n] =~ /#{tag}[\s$]/) # look for whitespace or end of line after it as well
            @lines[n].gsub!(/#{tag}\s?/, '')
            cleaned += 1
          end
        end
      end
      n += 1
    end
    return unless cleaned.positive?

    @is_updated = true
    log_message("  - removed #{cleaned} tags") if $verbose
  end

  def remove_scheduled
    # remove [>] tasks from calendar notes, as there will be a duplicate
    # (whether or not the 'Append links when scheduling' option is set or not)
    # log_message('  remove_scheduled ...') if $verbose
    n = cleaned = 0
    while n < @line_count
      # Empty any [>] todo lines
      if @lines[n] =~ /\[>\]/
        @lines.delete_at(n)
        @line_count -= 1
        n -= 1
        cleaned += 1
      end
      n += 1
    end
    return unless cleaned.positive?

    @is_updated = true
    log_message("  - removed #{cleaned} scheduled") if $verbose
  end

  def insert_new_line(new_line, line_number)
    # Insert 'line' into position 'line_number'
    # log_message('  insert_new_line ...') if $verbose > 1
    n = @line_count # start iterating from the end of the array
    while n >= line_number
      @lines[n + 1] = @lines[n]
      n -= 1
    end
    @lines[line_number] = new_line
    @line_count += 1
  end

  def remove_done_times
    # Process any completed (or cancelled) tasks and remove the HH:MM portion of the @done(...).
    n = cleaned = 0
    outline = ''
    # Go through each line in the active part of the file
    while n < (@done_header != 0 ? @done_header : @line_count)
      line = @lines[n]
      updated_line = ''
      completed_date = ''
      # find lines with date-time to shorten, and capture date part of it
      # i.e. @done(YYYY-MM-DD HH:MM[AM|PM])
      if line =~ /@done\(\d{4}-\d{2}-\d{2} \d{2}:\d{2}(?:.(?:AM|PM))?\)/
        # get completed date
        line.scan(/\((\d{4}-\d{2}-\d{2}) \d{2}:\d{2}(?:.(?:AM|PM))?\)/) { |m| completed_date = m.join }
        updated_line = line.gsub(/\(\d{4}-\d{2}-\d{2} \d{2}:\d{2}(?:.(?:AM|PM))?\)/, "(#{completed_date})")
        @lines[n] = updated_line
        cleaned += 1
        @is_updated = true
      end
      n += 1
    end
    return unless cleaned.positive?
    log_message("  - removed #{cleaned} done times") if $verbose
  end

  def remove_empty_header_sections
    # go backwards through the active part of the note, deleting any sections without content
    # log_message('  remove_empty_header_sections ...') if $verbose
    cleaned = 0
    n = @done_header != 0 ? @done_header - 1 : @line_count - 1

    # Go through each line in the file
    later_header_level = this_header_level = 0
    at_eof = 1
    while n.positive? || n.zero?
      line = @lines[n]
      if line =~ /^#+\s\w/
        # this is a markdown header line; work out what level it is
        line.scan(/^(#+)\s/) { |m| this_header_level = m[0].length }
        # log_message("    - #{later_header_level} / #{this_header_level}") if $verbose
        # if later header is same or higher level (fewer #s) as this,
        # then we can delete this line
        if later_header_level == this_header_level || at_eof == 1
          # log_message("   - Removing empty header line #{n} '#{line.chomp}'") if $verbose
          @lines.delete_at(n)
          cleaned += 1
          @line_count -= 1
          @is_updated = true
        end
        later_header_level = this_header_level
      elsif line !~ /^\s*$/
        # this has content but is not a header line
        later_header_level = 0
        at_eof = 0
      end
      n -= 1
    end
    return unless cleaned.positive?

    @is_updated = true
    log_message("  - removed #{cleaned} lines of empty section(s)") if $verbose
  end

  def remove_multiple_empty_lines
    # go backwards through the active parts of the note, deleting any blanks at the end
    # log_message('  remove_multiple_empty_lines ...') if $verbose
    cleaned = 0
    n = (@done_header != 0 ? @done_header - 1 : @line_count - 1)
    last_was_empty = false
    while n.positive?
      line_to_test = @lines[n]
      if line_to_test =~ /^\s*$/ && last_was_empty
        @lines.delete_at(n)
        cleaned += 1
      end
      last_was_empty = line_to_test =~ /^\s*$/ ? true : false
      n -= 1
    end
    return unless cleaned.positive?

    @is_updated = true
    @line_count = @lines.size
    log_message("  - removed #{cleaned} empty lines") if $verbose
  end

  def rewrite_file
    # write out this update file
    log_message("  -> writing updated version of #{@filename.to_s}")
    # open file and write all the lines out
    filepath = @filename
    begin
      File.open(filepath, 'w') do |f|
        @lines.each do |line|
          f.puts line
        end
      end
    rescue StandardError => e
      error_message("ERROR: #{e.exception.message} when re-writing note file #{filepath}")
    end
  end
end

#=======================================================================================
# Main Program
#=======================================================================================

log_message("Starting npTidy v#{VERSION} for user #{USERNAME} at #{time_now_fmttd} in folder #{CURRENT_DIR}")

#--------------------------------------------------------------------------------------
# Setup program options, by reading from current 'config.json' file in this directory
# Read JSON settings from a file
begin
  f = File.open(JSON_SETTINGS_FILE)
  json = f.read
  f.close
rescue StandardError => e
  error_message("Hit #{e.exception.message} when reading JSON settings file '${JSON_SETTINGS_FILE}'.")
  exit
end
begin
  parsed = JSON.parse(json) # returns a hash
  $options[:hours_to_process] = !parsed['hours_to_process'].nil? ? parsed['hours_to_process'].to_i : 8
  $options[:ignore_file_regex] = !parsed['ignore_file_regex'].nil? ? parsed['ignore_file_regex'] : ''
  $options[:ignore_today] = !parsed['ignore_today'].nil? ? parsed['ignore_today'] : false
  $options[:remove_scheduled] = !parsed['remove_scheduled'].nil? ? parsed['remove_scheduled'] : true
  $options[:tags_to_remove] = !parsed['tags_to_remove'].nil? ? parsed['tags_to_remove'] : nil
  if !$options[:tags_to_remove].nil?
    $temp = CSV.parse($options[:tags_to_remove])
    $temp[0].each do |tag| # items are all under array item [0] for some reason
      $tags_to_remove << tag.strip
    end
  end
  # log_message("Options: #{$options.to_s}") if $verbose
rescue JSON::ParserError => e
  error_message("Hit #{e.exception.message} when parsing JSON settings file.")
  exit
end

#--------------------------------------------------------------------------------------
# Main logic

if ARGV.count.zero?
  error_message("No arguments passed to plugin. Exiting.")
  exit
elsif ARGV.first == '-a'
  # Tidy all files changed in last 'hours_to_process' hours
  # Read metadata for all Note files, and find those altered in the last 'hours_to_process' hours
  begin
    Dir.chdir(NP_NOTES_DIR)
    Dir.glob(['{[!@]**/*,*}.{txt,md}']).each do |this_file|
      # log_message("  - found #{this_file}") if $verbose
      # ignore if this file not changed in the last 'hours_to_process' hours
      modified_time = File.exist?(this_file) ? File.mtime(this_file) : 0
      next unless modified_time > (time_now - $options[:hours_to_process] * 60 * 60)
      # ignore if this file is empty
      next if File.zero?(this_file)
      # OK, we want to read in this file
      $notes << NPFile.new(this_file)
    end
  rescue StandardError => e
    error_message("#{e.exception.message} when finding recently changed files")
  end

  # Also read metadata for all Daily files, and find those altered in the last 'hours_to_process' hours
  begin
    Dir.chdir(NP_CALENDAR_DIR)
    Dir.glob(['{[!@]**/*,*}.{txt,md}']).each do |this_file|
      # log_message("    Checking daily file #{this_file}, updated #{File.mtime(this_file)}, size #{File.size(this_file)}") if $verbose
      # ignore if this file is empty
      next if File.zero?(this_file)
      # ignore if modified time (mtime) not in the last 'hours_to_process' hours
      next unless File.mtime(this_file) > (time_now - $options[:hours_to_process] * 60 * 60)

      # read the calendar file in
      $notes << NPFile.new(this_file)
    end
  rescue StandardError => e
    error_message("ERROR: #{e.exception.message} when finding recently changed files")
  end

elsif ARGV.first == '-n'
  Dir.chdir(BASE_DATA_DIR)
  # we want to tidy the given single file, passed in ARGV[1]
  this_file = ARGV[1].nil? ? '' : ARGV[1]
  # have we been asked to ignore this file?
  if !$options[:ignore_file_regex].empty? && this_file =~ /$options[:ignore_file_regex]/
    log_message("Ignoring '#{this_file} as it matches 'ignore_file_regex'.")
    exit
  end
  # error if file doesn't exist
  if !File.exist?(this_file)
    error_message("File '#{this_file}' doesn't exist. Exiting.")
    exit
  end
  # or the note is empty
  if File.zero?(this_file)
    log_message("Ignoring '#{this_file} as it is empty.")
  end
  # OK, let's read it in
  $notes << NPFile.new(this_file)
else
  error_message("Invalid argument(s) passed '#{ARGV}'. Exiting.")
  exit
end

#--------------------------------------------------------------------------------------
if $notes.count.positive? # if we have some files to work on ...
  c = 0
  ignore_file_regex = $options[:ignore_file_regex]
  log_message("Processing #{$notes.count} files ...") if $verbose
  # $notes.sort! { |a, b| a.title <=> b.title }
  $notes.each do |note|
    # ignore if this file matches 'ignore_file_regex'
    if !ignore_file_regex.empty? && note.filename =~ /#{ignore_file_regex}/
      log_message("  Ignoring '#{note.filename}' as it matches 'ignore_file_regex' option")
      next
    end

    # For each NP file to process, do the following
    log_message("  Processing file id #{note.id}: #{note.title.to_s}") if $verbose
    note.clear_empty_tasks_or_headers
    note.remove_empty_header_sections
    note.remove_unwanted_dates
    note.remove_unwanted_tags
    note.remove_scheduled if note.is_calendar && $options[:remove_scheduled]
    note.remove_done_times
    note.remove_multiple_empty_lines
    # If there have been changes, write out the file
    note.rewrite_file if note.is_updated && !read_only
    c += 1
  end
  log_message("Processed #{c} note(s). Stopping.") if $verbose
else
  log_message("No matching files found to tidy.")
end
