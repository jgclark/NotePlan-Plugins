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

But for now, in NotePlan in Preferences > Sync > Advanced, click on 'Open Local Database Folder', and see if there's an existing `Plugins` directory. If not create it. Then copy the whole `Tidy` folder (not just the contents) to this directory.

## Configuration
In time there will be a configuration system through the `plugin.json` file. But for now, update the relevant variables at the top of the `npTidy.rb` script.

- `-s` (`--keepschedules`) keep the scheduled (>) dates of completed tasks
- `TAGS_TO_REMOVE`: list of tags to remove. Default ["#waiting","#high"]

## Running the Plugin
Invoke the **tidy** command on the current note, by ??

**NB**: NotePlan has several options in the Markdown settings for how to mark a task, including `-`, `- [ ]', `*` and `* [ ]`. All are supported by this script.

## Future things to think about
- Automatic running -- e.g. Tidy all files altered in last 24 hours

## Problems? Suggestions?
See the [GitHub project](https://github.com/jgclark/NotePlan-Tidy) for issues, or suggest improvements.
