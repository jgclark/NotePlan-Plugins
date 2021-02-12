# Plugin Architecture
A work in progress by Eduard Metzger and Jonathan Clark, with support from the discord server community.

## File/Folder structure
The new files and folders are in bold; the others are existing ones in NotePlan's data directory.

- Notes
- Calendar
- **Plugins**
  - **Plugin name** -- one folder per plugin. The name is expected to the `plugin.id` below.
    - **`plugin.json`** -- metadata about the plugin, including default configuration
    - **`config.json`** -- current configuration for the plugin
    - **`script_file`** -- the executable script file, in any suitable language, referred to in `config.json`
    - other supporting files, libraries, graphics
- Filters

## plugin.json
The plugin is configured in this JSON file, which shouldn't change, for any given versino of the plugin. Here's an annotated view of an example:

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
      "default": "8"
    }
  ]
}
```

## config.json
The JSON file that stores the actual current Preference settings. This will be maintained by NotePlan. When a plugin is installed, it copies any `plugin.preference` item defaults into this file.

## Logging
NotePlan maintains two log files, in the `~/Library/Containers/co.noteplan.NotePlan3/Data/Documents/` folder:
- `np-out.log`
- `np-error.log`

When a script runs, by default the first of any output lines is treated as an error or log message.
- `error: "message"` → modal dialog, debug window, np-error.log 
- `log: "message"` -→ debug window, np-out.log

## Output
Further lines of output are captured by NotePlan and used to insert at the current position, or replace the current selection (where there is one).
