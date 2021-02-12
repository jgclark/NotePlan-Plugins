#!/usr/bin/ruby
#-------------------------------------------------------------------------------
# NotePlan Tidy Plugin
# by Jonathan Clark, v0.0.1, 11.2.2021
#-------------------------------------------------------------------------------
# See README.md file for details, how to run and configure it.
# Repository: https://github.com/jgclark/NotePlan-Tidy/
#-------------------------------------------------------------------------------
VERSION = "0.0.1"

require 'date'
require 'time'
require 'cgi'

#-------------------------------------------------------------------------------
# Setting variables to tweak ... TODO: reduce number here to about zero
#-------------------------------------------------------------------------------
$verbose = true
NUM_HEADER_LINES = 4 # suits my use, but probably wants to be 1 for most people

#-------------------------------------------------------------------------------
# Other Constants & Settings
#-------------------------------------------------------------------------------
JSON_SETTINGS_FILE = "config.json" # assumed to be in the current directory
DATE_TIME_LOG_FORMAT = '%e %b %Y %H:%M'.freeze # only used in logging
RE_DATE_FORMAT_CUSTOM = '\d{1,2}[\-\.//][01]?\d[\-\.//]\d{4}'.freeze # regular expression of alternative format used to find dates in templates. This matches DD.MM.YYYY and similar.
DATE_TODAY_FORMAT = '%Y%m%d'.freeze # using this to identify the "today" daily note
RE_YYYY_MM_DD = '\d{4}[\-\.//][01]?\d[\-\.//]\d{1,2}' # built-in format for finding dates of form YYYY-MM-DD and similar
USERNAME = ENV['LOGNAME'] # pull username from environment
USER_DIR = ENV['HOME'] # pull home directory from environment

# Variables that need to be globally available
time_now = Time.now
time_now_fmttd = time_now.strftime(DATE_TIME_LOG_FORMAT)
$date_today = time_now.strftime(DATE_TODAY_FORMAT)
# $archive = 0
# $allNotes = []  # to hold all note objects
$notes    = []  # to hold all relevant note objects
$npfile_count = -1 # number of NPFile objects created so far (incremented before first use)

#-------------------------------------------------------------------------
# Helper definitions
#-------------------------------------------------------------------------

def log_message(message)
  return "log: #{message}"
end

def error_message(message)
  return "error: #{message}"
end

# def create_new_empty_file(title, ext)
#   # Populate empty NPFile object, adding just title

#   # Use x-callback scheme to add a new note in NotePlan,
#   # as defined at http://noteplan.co/faq/General/X-Callback-Url%20Scheme/
#   #   noteplan://x-callback-url/addNote?text=New%20Note&openNote=no
#   # Open a note identified by the title or date.
#   # Parameters:
#   # - noteTitle optional, will be prepended if it is used
#   # - text optional, text will be added to the note
#   # - openNote optional, values: yes (opens the note, if not already selected), no
#   # - subWindow optional (only Mac), values: yes (opens note in a subwindow) and no
#   # NOTE: So far this can only create notes in the top-level Notes folder
#   # Does cope with emojis in titles.
#   uriEncoded = "noteplan://x-callback-url/addNote?noteTitle=" + URI.escape(title) + "&openNote=no"
#   begin
#     response = `open "#{uriEncoded}"` # TODO: try simpler open(...) with no response, and rescue errors
#   rescue StandardError => e
#     puts "    Error #{e.exception.message} trying to add note with #{uriEncoded}. Exiting.".colorize(WarningColour)
#     exit
#   end

#   # Now read this new file into the $allNotes array
#   Dir.chdir(NP_NOTES_DIR)
#   sleep(3) # wait for the file to become available. TODO: probably a smarter way to do this
#   filename = "#{title}.#{ext}"
#   new_note = NPFile.new(filename)
#   new_note_id = new_note.id
#   $allNotes[new_note_id] = new_note
#   puts "Added new note id #{new_note_id} with title '#{title}' and filename '#{filename}'. New $allNotes count = #{$allNotes.count}" if $verbose > 1
# end

#-------------------------------------------------------------------------
# Class definition: NPFile
# NB: in this script this class covers Note *and* Daily files
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
    $npfile_count += 1
    @id = $npfile_count
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
    f = File.open(@filename, 'r', encoding: 'utf-8')
    f.each_line do |line|
      @lines[n] = line
      @done_header = n  if line =~ /^## Done$/
      @cancelled_header = n if line =~ /^## Cancelled$/
      n += 1
    end
    f.close
    @line_count = @lines.size
    # Now make a title for this file:
    if @filename =~ /\d{8}\.(txt|md)/
      # for Calendar file, use the date from filename
      @title = @filename[0..7]
      @is_calendar = true
      @is_today = @title == $date_today
    else
      # otherwise use first line (but take off heading characters at the start and starting and ending whitespace)
      tempTitle = @lines[0].gsub(/^#+\s*/, '').gsub(/\s+$/, '')
      @title = !tempTitle.empty? ? tempTitle : 'temp_header' # but check it doesn't get to be blank
      @is_calendar = false
      @is_today = false
    end

    puts "Init NPFile #{@id} from #{this_file}, updated #{@modified_time} #{@line_count} #{@is_calendar}" if $verbose > 1
  end

  # def self.new2(*args)
  #   # TODO: Use NotePlan's addNote via x-callback-url instead?
  #   # This is a second initializer, to create a new empty file, so have to use a different syntax.
  #   # Create empty NPFile object, and then pass to detailed initializer
  #   object = allocate
  #   object.create_new_empty_file(*args)
  #   object # implicit return
  # end

  def clear_empty_tasks_or_headers
    # Clean up lines with just * or - or #s in them
    puts '  remove_empty_tasks_or_headers ...' if $verbose > 1
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
    puts "  - removed #{cleaned} empty lines" if $verbose > 0
  end

  def remove_unwanted_tags_dates
    # removes specific tags and >dates from complete or cancelled tasks
    puts '  remove_unwanted_tags_dates ...' if $verbose > 1
    n = cleaned = 0
    while n < @line_count
      # only do something if this is a completed or cancelled task
      if @lines[n] =~ /\[(x|-)\]/
        # remove any <YYYY-MM-DD on completed or cancelled tasks
        if options[:remove_scheduled] == 1
          if (@lines[n] =~ /\s<\d{4}\-\d{2}\-\d{2}/)
            @lines[n].gsub!(/\s<\d{4}\-\d{2}\-\d{2}/, '')
            cleaned += 1
          end
        end

        # Remove any tags from the TagsToRemove list. Iterate over that array:
        options[:tags_to_remove].each do |tag|
          if (@lines[n] =~ /#{tag}/[n].gsub!(/ #{tag}/, '')
            cleaned += 1
          end
        end
      end
      n += 1
    puts "  - removed #{cleaned} tags" if $verbose > 0
  end

  def remove_scheduled
    # remove [>] tasks from calendar notes, as there will be a duplicate
    # (whether or not the 'Append links when scheduling' option is set or not)
    puts '  remove_scheduled ...' if $verbose > 1
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
    puts "  - removed #{cleaned} scheduled" if $verbose > 0
  end

  def insert_new_line(new_line, line_number)
    # Insert 'line' into position 'line_number'
    puts '  insert_new_line ...' if $verbose > 1
    n = @line_count # start iterating from the end of the array
    while n >= line_number
      @lines[n + 1] = @lines[n]
      n -= 1
    end
    @lines[line_number] = new_line
    @line_count += 1
  end

  def process_repeats_and_done
  # TODO: remove repeats bit of this
    # Process any completed (or cancelled) tasks with @repeat(..) tags,
    # and also remove the HH:MM portion of any @done(...) tasks.
    #
    # When interval is of the form +2w it will duplicate the task for 2 weeks
    # after the date is was completed.
    # When interval is of the form 2w it will duplicate the task for 2 weeks
    # after the date the task was last due. If this can't be determined,
    # then default to the first option.
    # Valid intervals are [0-9][bdwmqy].
    # To work it relies on finding @done(YYYY-MM-DD HH:MM) tags that haven't yet been
    # shortened to @done(YYYY-MM-DD).
    # It includes cancelled tasks as well; to remove a repeat entirely, remoce
    # the @repeat tag from the task in NotePlan.
    puts '  process_repeats_and_done ...' if $verbose > 1
    n = cleaned = 0
    outline = ''
    # Go through each line in the active part of the file
    while n < (@done_header != 0 ? @done_header : @line_count)
      line = @lines[n]
      updated_line = ''
      completed_date = ''
      # find lines with date-time to shorten, and capture date part of it
      # i.e. @done(YYYY-MM-DD HH:MM[AM|PM])
      if line =~ /@done\(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}(?:.(?:AM|PM))?\)/
        # get completed date
        line.scan(/\((\d{4}\-\d{2}\-\d{2}) \d{2}:\d{2}(?:.(?:AM|PM))?\)/) { |m| completed_date = m.join }
        updated_line = line.gsub(/\(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}(?:.(?:AM|PM))?\)/, "(#{completed_date})")
        @lines[n] = updated_line
        cleaned += 1
        @is_updated = true
        if updated_line =~ /@repeat\(.*\)/
          # get repeat to apply
          date_interval_string = ''
          updated_line.scan(/@repeat\((.*?)\)/) { |mm| date_interval_string = mm.join }
          if date_interval_string[0] == '+'
            # New repeat date = completed date + interval
            date_interval_string = date_interval_string[1..date_interval_string.length]
            new_repeat_date = calc_offset_date(Date.parse(completed_date), date_interval_string)
            puts "      Adding from completed date --> #{new_repeat_date}" if $verbose > 1
          else
            # New repeat date = due date + interval
            # look for the due date (<YYYY-MM-DD)
            due_date = ''
            if updated_line =~ /<\d{4}\-\d{2}\-\d{2}/
              updated_line.scan(/<(\d{4}\-\d{2}\-\d{2})/) { |m| due_date = m.join }
              # need to remove the old due date (and preceding whitespace)
              updated_line = updated_line.gsub(/\s*<\d{4}\-\d{2}\-\d{2}/, '')
            else
              # but if there is no due date then treat that as today
              due_date = completed_date
            end
            new_repeat_date = calc_offset_date(Date.parse(due_date), date_interval_string)
            puts "      Adding from due date --> #{new_repeat_date}" if $verbose > 1
          end

          # Create new repeat line:
          updated_line_without_done = updated_line.chomp
          # Remove the @done text
          updated_line_without_done = updated_line_without_done.gsub(/@done\(.*\)/, '')
          # Replace the * [x] text with * [>]
          updated_line_without_done = updated_line_without_done.gsub(/\[x\]/, '[>]')
          outline = "#{updated_line_without_done} >#{new_repeat_date}"

          # Insert this new line after current line
          n += 1
          insert_new_line(outline, n)
        end
      end
      n += 1
    end
  end

  def remove_empty_header_sections
    # go backwards through the active part of the note, deleting any sections without content
    puts '  remove_empty_header_sections ...' if $verbose > 1
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
        # puts "    - #{later_header_level} / #{this_header_level}" if $verbose > 1
        # if later header is same or higher level (fewer #s) as this,
        # then we can delete this line
        if later_header_level == this_header_level || at_eof == 1
          puts "    - Removing empty header line #{n} '#{line.chomp}'" if $verbose > 1
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
    # @line_count = @lines.size
    puts "  - removed #{cleaned} lines of empty section(s)" if $verbose > 1
  end

  def remove_multiple_empty_lines
    # go backwards through the active parts of the note, deleting any blanks at the end
    puts '  remove_multiple_empty_lines ...' if $verbose > 1
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
    puts "  - removed #{cleaned} empty lines" if $verbose > 1
  end

  def rewrite_file
    # write out this update file
    puts '  > writing updated version of ' + @filename.to_s.bold unless $quiet
    # open file and write all the lines out
    filepath = if @is_calendar
                 "#{NP_CALENDAR_DIR}/#{@filename}"
               else
                 "#{NP_NOTES_DIR}/#{@filename}"
               end
    begin
      File.open(filepath, 'w') do |f|
        @lines.each do |line|
          f.puts line
        end
      end
    rescue StandardError => e
      puts "ERROR: #{e.exception.message} when re-writing note file #{filepath}".colorize(WarningColour)
    end
  end
end

#=======================================================================================
# Main logic
#=======================================================================================

#TODO: 
log_message("Starting npTidy v#{VERSION} for user #{USERNAME} at #{time_now_fmttd} in folder #{}")

# Setup program options, by reading from current 'config.json' file in this directory
# Read JSON settings from a file
options = {}
begin
  f = File.open(JSON_SETTINGS_FILE)
  json = f.read
  f.close
  parsed = JSON.parse(json) # returns a hash
  puts parsed if $verbose
  options[:exclude_glob] = parsed['exclude_glob'].exists? ? parsed['exclude_glob'] : ''
  options[:ignore_today] = parsed['ignore_today'].exists? ? parsed['ignore_today'] : false
  options[:remove_scheduled] = parsed['remove_scheduled'].exists? ? parsed['remove_scheduled'] : true
  options[:hours_to_process] = parsed['hours_to_process'].exists? ? parsed['hours'] : 8
  options[:tags_to_remove] = parsed['tags_to_remove'].exists? ? parsed['tags_to_remove'] : "'#waiting', '#high', '#started', '#⭐'"
  log_message("Options: #{options.to_s}")
rescue JSON::ParserError => e
  # FIXME: why doesn't this error fire when it can't find the file?
  error_message("Hit #{e.exception.message} when reading JSON settings file.")
  exit
end

# opt_parser = OptionParser.new do |opts|
#   # options[:skipfile] = ''
#   opts.on('-f', '--skipfile=TITLE[,TITLE2,etc]', Array, "Don't process specific file(s)") do |skipfile|
#     options[:skipfile] = skipfile
#   end
# end
# opt_parser.parse! # parse out options, leaving file patterns to process
# options[:remove_scheduled] = options[:remove_scheduled]

#--------------------------------------------------------------------------------------
# Start by reading all Notes files in
# (This is needed to have a list of all note titles that we might be moving tasks to.)
begin
  Dir.chdir(NP_NOTES_DIR)
  Dir.glob(['{[!@]**/*,*}.txt', '{[!@]**/*,*}.md']).each do |this_file|
    next if File.zero?(this_file) # ignore if this file is empty

    $allNotes << NPFile.new(this_file)
  end
rescue StandardError => e
  puts "ERROR: #{e.exception.message} when reading in all notes files".colorize(WarningColour)
end
puts "Read in all Note files: #{$npfile_count} found\n" if $verbose > 0

if ARGV.count.positive?
  # We have a file pattern given, so find that (starting in the notes directory), and use it
  puts "Starting npTools at #{time_now_fmttd} for files matching pattern(s) #{ARGV}." unless $quiet
  begin
    ARGV.each do |pattern|
      # if pattern has a '.' in it assume it is a full filename ...
      # ... otherwise treat as close to a regex term as possible with Dir.glob
      glob_pattern = pattern =~ /\./ ? pattern : '[!@]**/*' + pattern + '*.{md,txt}'
      puts "  Looking for note filenames matching glob_pattern #{glob_pattern}:" if $verbose > 0
      Dir.glob(glob_pattern).each do |this_file|
        puts "  - #{this_file}" if $verbose > 0
        # Note has already been read in; so now just find which one to point to, by matching filename
        $allNotes.each do |this_note|
          # copy the $allNotes item into $notes array
          $notes << this_note if this_note.filename == this_file
        end
      end

      # Now look for matches in Daily/Calendar files
      Dir.chdir(NP_CALENDAR_DIR)
      # if pattern has a '.' in it assume it is a full filename ...
      # ... otherwise treat as close to a regex term as possible with Dir.glob
      glob_pattern = pattern =~ /\./ ? pattern : '*' + pattern + '*.{md,txt}'
      puts "  Looking for daily note filenames matching glob_pattern #{glob_pattern}:" if $verbose > 0
      Dir.glob(glob_pattern).each do |this_file|
        puts "  - #{this_file}" if $verbose > 0
        $notes << NPFile.new(this_file) if !File.zero?(this_file) # read in file unless this file is empty
      end
    end
  rescue StandardError => e
    puts "ERROR: #{e.exception.message} when reading in files matching pattern #{pattern}".colorize(WarningColour)
  end

else
  # Read metadata for all Note files, and find those altered in the last 24 hours
  puts "Starting npTools at #{time_now_fmttd} for all NP files altered in last #{options[:hours_to_process]} hours." unless $quiet
  begin
    $allNotes.each do |this_note|
      next unless this_note.modified_time > (time_now - options[:hours_to_process] * 60 * 60)

      # Note has already been read in; so now just find which one to point to
      $notes << this_note
    end
  rescue StandardError => e
    puts "ERROR: #{e.exception.message} when finding recently changed files".colorize(WarningColour)
  end

  # Also read metadata for all Daily files, and find those altered in the last 24 hours
  begin
    Dir.chdir(NP_CALENDAR_DIR)
    Dir.glob(['{[!@]**/*,*}.{txt,md}']).each do |this_file|
      puts "    Checking daily file #{this_file}, updated #{File.mtime(this_file)}, size #{File.size(this_file)}" if $verbose > 1
      next if File.zero?(this_file) # ignore if this file is empty
      # if modified time (mtime) in the last 24 hours
      next unless File.mtime(this_file) > (time_now - options[:hours_to_process] * 60 * 60)

      # read the calendar file in
      $notes << NPFile.new(this_file)
    end
  rescue StandardError => e
    puts "ERROR: #{e.exception.message} when finding recently changed files".colorize(WarningColour)
  end
end

#--------------------------------------------------------------------------------------
if $notes.count.positive? # if we have some files to work on ...
  puts "\nProcessing #{$notes.count} files:" if $verbose > 0
  # For each NP file to process, do the following:
  $notes.sort! { |a, b| a.title <=> b.title }
  $notes.each do |note|
    if note.is_today && options[:ignore_today]
      puts '(Skipping ' + note.title.to_s.bold + ' due to --ignore_today option)' if $verbose > 0
      next
    end
    if options[:skipfile].include? note.title
      puts '(Skipping ' + note.title.to_s.bold + ' due to --skipfile option)' if $verbose > 0
      next
    end
    puts " Processing file id #{note.id}: " + note.title.to_s.bold if $verbose > 0
    note.clear_empty_tasks_or_headers
    note.remove_empty_header_sections
    note.remove_unwanted_tags_dates
    note.remove_scheduled if note.is_calendar
    note.process_repeats_and_done
    note.remove_multiple_empty_lines
    # If there have been changes, write out the file
    note.rewrite_file if note.is_updated
  end
else
  puts "  Warning: No matching files found.\n".colorize(WarningColour)
end