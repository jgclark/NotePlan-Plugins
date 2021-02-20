#!/bin/zsh

# Script to test jgclark.npTidy plugin for NotePlan
# i.e. this is a stub for NotePlan, while it doesn't yet have plugin functionality
# JGC, 13.2.2021

# Set environment variables to a separate test location
CALENDAR_DIR=/tmp/Calendar
NOTES_DIR=/tmp/Notes
PLUGIN_DIR=/Users/jonathan/GitHub/NotePlan-Plugins/jgclark.Tidy
# mkdir $CALENDAR_DIR # do this first time
# mkdir $NOTES_DIR # do this first time
cd $PLUGIN_DIR

# Then create the test data in those locations, as needed
cp test_notes/*.* $NOTES_DIR
cp test_calendar/*.* $CALENDAR_DIR

# Test 1: should fail with no arguments
npTidy
# PASSED

# Test 2: should fail with wrong number of args
npTidy -n
# PASSED

# Test 3: should fail to find a single note file
npTidy -n "Notes/ZZZZ.XXX"
# PASSED

# Test 4: should find a single note file in the top level of Notes/
npTidy -n "Notes/standard.md"
# PASSED

# Test 5: should find a single note file with quotes in title
npTidy -n "Notes/TEST/TEST \"title in quotes\".md"
# PASSED

# Test 6: should find a single note file in the TEST folder of Notes/
npTidy -n "Notes/TEST/TEST various.md"
# PASSED

# Test 7: should find a single calendar file
npTidy -n "Calendar/20211201.md"
# PASSED

# Test 8: operate over all files changed in last 'hours_to_process' hours
npTidy -a
# PASSED
