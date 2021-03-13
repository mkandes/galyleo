#!/usr/bin/env bash
#files_to_transfer='    /wnt/dev /proc/sys,/tmp,/usr/portage, /var/tmp'

IFS=', '
read -r -a files <<< "$(echo ${files_to_transfer})"
for file in "${files[@]}"; do
  echo $file
done
unset IFS
