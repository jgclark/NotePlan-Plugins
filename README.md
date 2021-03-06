# NotePlan Plugin Architecture
A work in progress by Eduard Metzger and Jonathan Clark, with support from the discord server community.

## Triggering plugins
There are potentially four ways plugin functionality can be triggered:
1. By a `/command` typed at the start of a line in editor mode.
2. By a command typed in the command bar (which can be triggered anywhere by ⌥⌘J)
3. (Potentially) by a shortcut registered by the plugin
4. (Potentially) on a regular timer

## File/Folder structure
The new files and folders are in bold; the others are existing ones in NotePlan's data directory.

- Notes
- Calendar
- **Plugins**
  - **Plugin name** -- one folder per plugin. The name is expected to the `plugin.id` below.
    - **`plugin.json`** -- metadata about the plugin, including default configuration
    - **`config.json`** -- current configuration for the plugin
    - **`_script_file_`** -- the executable script file, in any suitable language, referred to in `config.json`
    - **other supporting files, libraries, graphics**
- Filters

## plugin.json
The plugin is configured in this JSON file, which shouldn't change (for any given version of the plugin). Here's an annotated view of an example:

``` json
{
  "noteplan.minAppVersion": "3.0.16", // x.y.z version of NotePlan required
  "plugin.id": "jgclark.Tidy", // author id.short name -- to allow multiple plugins with similar names by different authors.
  "plugin.name": "Tidy up NotePlan notes", // short display name for plugin catalog
  "plugin.description": "Delete multiple blank lines, empty todos and bullets, etc.", // longer description for plugin catalog
  "plugin.icon": "", // optional .png file
  "plugin.author": "Jonathan Clark", // author name
  "plugin.url": "tbd", // link to repository for the plugin
  "plugin.version": "0.0.1", // x.y.z plugin version
  "plugin.dependencies": [ // optional list of dependencies, and automated tests
    {
      "description": "Ruby interpreter", // human-readable desceription of the dependency
      "min_version": "2.4.0", // (optional) human-readable minimum version string
      "test_command": "ruby --version" // (optional) command to run on installation; if it returns true then the dependency is met; if not then warn user and disable.
    },
    {
      "description": "Ruby gem 'json'",
      "min_version": "2.0.0",
      "test_command": "gem spec json --local --version '>=2'"  // cool command to do a specific ruby gem test :-)
    }
  ],
  "plugin.commands": [ // array of commands; minimum 1
    {
      "name": "tidy", // short name to use in the command bar
      "description": "Tidy current note", // longer command description to use
      "command": "ruby npTidy.rb -n {FILENAME}", // the actual string that invokes the command
      "requested_shortcut": "" // optional shortcut to use for this command -- but up to NotePlan to decide how to honour this request (TODO: how to define this)
    },
    {
      "name": "tidy-recent",
      "description": "Tidy all notes changed in last 8 hours (configure using 'hours_to_process' preference), unless the filename matches the 'exclude_glob' preference",
      "command": "ruby npTidy.rb -a",
      "requested_interval": "8h" // optional time interval between automatic executions of this command.  TODO: Needs more definition on what to do when app is closed.
    }
  ],
  "plugin.preferences": [ // array, possibly with no members, for each preference that can be set
    {
      "name": "exclude_glob", // preference name
      "type": "string", // preference type: boolean, integer, string, real. TODO: what about arrays?
      "default": "*special.md" // mandatory default, which if boolean must be "true" or "false"
    },
    {
      "name": "hours_to_process",
      "type": "integer",
      "default": 8
    }
  ]
}
```
### Passing command parameters
In the first `command` string above, there is a `{FILENAME}`. This indicates that it is expecting a filename to be passed for the plugin to process. Compare the second command which doesn't need a particular note to be specified.  **Q for EM: This feels a bit of a hack, but I can't think of a more elegant solution right now.**

Other possible parameter type identifiers:
- `{STRING}` -- general string
- `{TITLE}` -- a note's title

**Q for EM: Any others? I think we'll also need a way to pass an array of filenames.**

All are passed as an UTF-8 string with any double-quote marks escaped.

## config.json
This is the JSON file that stores the actual current Preference settings. This will be maintained by NotePlan. When a plugin is installed, it copies any `plugin.preference` item defaults into this file.

## Referencing Files
The following **environment variables** will be set, which the plugin can look up:
1. `CALENDAR_DIR`, the full filepath of the 'Calendar' directory in the NotePlan data area.
2. `NOTES_DIR`, the full filepath of the 'Notes' directory in the NotePlan data area.
3. `PLUGIN_DIR`, the full filepath of the current Plugin's top-level folder.

When the plugin is called it can assume its **current working directory** is in the plugin's folder.

**Q for EM: This is the bit I'm least clear about. Does this even make sense? Is it possible?**

## Logging
NotePlan maintains two log files, in the `~/Library/Containers/co.noteplan.NotePlan3/Data/Documents/` folder:
- `np-out.log`
- `np-error.log`

When a script runs, by default the first of any output lines is treated as an error or log message, and will be copied to the relevant log, plus other output(s).
- `error: "message"` --> a modal error dialog, debug window, np-error.log 
- `log: "message"` --> debug window, np-out.log

NB: Plugin authors should assume the log files aren't visible to the plugin. **Q for EM: Is this right?**

## Output
Further lines of output are captured by NotePlan and used to insert at the current position, or replace the current selection (where there is one).

## Installing
We need a mechanism to enable/disable plugins (common practice in other extensible systems).  Not least because I can easily foresee the case that a less experienced user tries a plugin that requires script language X version Y, but doesn't have it on their Mac. (Particularly as I think I read that Apple have said they're going to stop shipping some language engines in macOS.)  So I think (in time, anyway) we need a way to test whether language X version Y is installed, to warn the user, and to disable it if it isn't.

We also need an array of dependencies, now added in the sample above. This includes an (optional?) one-line script that the author specifies to test whether the dependency is met or not. If the command executes OK then dependency is passed. If not, an error is generated.

----

## Future Work 
1. (**priority**) need way for plugin to access a list of some/all note titles without having to read in all files
2. installation issues
3. how to trigger UI elements or dialogs in NotePlan itself?

