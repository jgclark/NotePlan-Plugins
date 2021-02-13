#!/bin/zsh

# Script to test jgclark.npTidy plugin for NotePlan
# i.e. this is a stub for NotePlan, while it doesn't yet have plugin functionality
# JGC, 13.2.2021

# Set environment variables to a separate test location
CALENDAR_DIR=/tmp/Calendar
NOTES_DIR=/tmp/Notes
PLUGIN_DIR=/Users/jonathan/GitHub/NotePlan-Plugins/jgclark.Tidy
# mkdir $CALENDAR_DIR
# mkdir $NOTES_DIR
cd $PLUGIN_DIR

# Then create the test data in those locations
# cp test_notes/*.* $NOTES_DIR
# cp test_dailies/*.* $CALENDAR_DIR

# Test 1: should fail with no arguments
# PASSED npTidy

# Test 2: should fail with wrong number of args
npTidy -n
exit  # ----------------------------

# Test 3: should find a single note file
npTidy -n "ZZZZ.XXX"

# Test 4: should find a single note file
npTidy -n "TEST various.md"

# Test 5: should find a single calendar file
npTidy -n "20210123.md"
