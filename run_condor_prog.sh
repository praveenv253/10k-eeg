#!/bin/bash

# Create an array out of the arguments
args=( "$@" )

# Quote all but the first argument
# Note the usage of the array and slicing syntax. Refer:
# - http://stackoverflow.com/questions/12711786/
# - http://stackoverflow.com/questions/1335815/
quoted_args=$(for arg in "${args[@]:1}"; do echo \"$arg\"; done)

# Use the first argument as the program and run with the rest as arguments to
# this program
$1 $quoted_args
