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
# cp test_notes/*.* $NOTES_DIR
# cp test_dailies/*.* $CALENDAR_DIR

# Test 1: should fail with no arguments
npTidy
# PASSED

# Test 2: should fail with wrong number of args
npTidy -n
# PASSED

# Test 3: should fail to find a single note file
npTidy -n "ZZZZ.XXX"
# PASSED

# Test 4: should find a single note file in the top level of Notes/
npTidy -n "standard.md"
# PASSED

# Test 5: should find a single note file in the TEST folder of Notes/
npTidy -n "TEST/TEST various.md"
exit  # TESTED UP TO HERE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# Test 5: should find a single calendar file
npTidy -n "20210123.md"
