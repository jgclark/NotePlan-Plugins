# Tidy Plugin for NotePlan
This provides a Plugin for NotePlan v3 and above that performs some tidy-up on particular notes. It is triggered by a command run inside NotePlan.

When invoked for a note it **tidies up** data files, by:
1. removing the time part of any `@done(...)` mentions that NotePlan automatically adds when the 'Append Completion Date' option is on.
2. removing `#waiting` or `#high` tags or `<dates` from completed or cancelled tasks (configurable)
3. removing scheduled (`* [>] task`) items in calendar files (as they've been copied to a new day)
4. removing any lines with just `* `or `-` or starting `#`s
5. removing header lines without any content before the next header line of the same or higher level (i.e. fewer `#`s)
6. removing any multiple consecutive blank lines.


## Installation
Eventually to be handled by NotePlan.

But for now, in NotePlan in Preferences > Sync > Advanced, click on 'Open Local Database Folder', and see if there's an existing `Plugins` directory. If not create it. Then copy the whole `jgclark.Tidy` folder (not just the contents) to this directory.

## Configuration
Configuration is done through the `plugin.json` file, as documented in the `config.json` definition file.

Also note that for development purposes, there are variables at the top of the script that can be set:
- `read_only`: if set to true, it stops the script from actually writing any changes.
- `$verbose`: if set to true, then it adds more logging output

## Testing the plugin
Use the `tidyTest.sh` script -- see comments embedded in it to set up some test data in some suitable place, or point it to the real NP3 data. It calls a series of commands to test out the plugin -- but the output has to be manually checked, until I work out how to automate this.

## Running the Plugin
To invoke the **tidy** command on the current note, by calling

`npTidy -n `

To invoke the **tidy** command on all files changed in the last `hours_to_process` hours, call

`npTidy -a`

**NB**: NotePlan has several options in the Markdown settings for how to mark a task, including `-`, `- [ ]', `*` and `* [ ]`. All are supported by this script.

## Future things to think about
- check > and < date moving
- Automatic running -- e.g. Tidy all files altered in last 24 hours

## Problems? Suggestions?
See the [GitHub project](https://github.com/jgclark/NotePlan-Tidy) for issues, or suggest improvements.
