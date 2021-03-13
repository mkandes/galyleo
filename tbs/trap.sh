#!/usr/bin/env bash

# Set a trap for SIGINT and SIGTERM signals
trap "echo The program is terminated." SIGTERM SIGINT
 
#Display message to generate SIGTERM
echo "Press Ctrl+Z stop the process"
 
#Initialize counter variable, i
i=1
 
#declare infinite for loop
for(;;)
do
  #Print message with counter i
  echo “running the loop for $i times”
  #Increment the counter by one
  ((i++))
done
