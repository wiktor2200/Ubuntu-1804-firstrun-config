#!/bin/bash
#===============================================================================
#          FILE:  generate-script-from-config.bash
#         USAGE:  bash ./generate-script-from-config.bash
#   DESCRIPTION:  Generate Ubuntu config script from CSV config file
#                 Config file syntax (colon separated)
#                 state:name:description:subscript_name
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#         NOTES:  ---
#        AUTHOR:  wiktor2200, https://github.com/wiktor2200
#          REPO:  https://github.com/wiktor2200/Ubuntu-1804-firstrun-config
#       CREATED:  2018-06-12
#===============================================================================

# Get script's main directory
DIR=`dirname $0`

# Create dir for subscripts in main repo directory
mkdir -p $DIR/../scripts

function start_generate () {
      echo -e "#!/bin/bash"
# Add information header from file to generated script including current date
  cat $DIR/description.txt | sed "s/CURRENT_DATE/`date +%F`/g"
      echo -e "# This script is generated using: generate-script-from-config.bash from repo: https://github.com/wiktor2200/Ubuntu-1804-firstrun-config\n"
      echo "# Get script's main directory"
      echo -e 'DIR=`dirname $0`\n'
}

function generate_subscripts_files () {
  # Read config file from main script directory
  INPUT="$DIR/config.csv"
  IFS=':'

  # Read config from CSV file
  [ ! -f $INPUT ] && { echo "$INPUT File not found"; exit 99; }
  while read state task description script
  do
    # Check if script exist in subfolder, if not create it.
    if [ ! -f $DIR/../scripts/$script ]; then
          echo -e "# $script \n# $description" > $DIR/../scripts/$script
    fi
  done < $INPUT
  unset IFS
}

# Generate zenity menu from CSV file
function generate_zenity_menu () {
      echo "# Render zenity menu"
      echo -n 'response=$(zenity --height=700 --width=1200 --window-icon=$DIR/ubuntu_icon.png --list --checklist --title="Configure your Ubuntu 18.04" --column="State" --column="Task" --column="Description" '
  INPUT="$DIR/config.csv"

  IFS=':'
  # Read config from CSV file
  [ ! -f $INPUT ] && { echo "$INPUT File not found"; exit 99; }
  while read state task description script
  do
        echo "$state \"$task\" \"$description\" \\"
  done < $INPUT
  unset IFS

      echo -e '--separator=":")\n'
}

# Generate case syntax from CSV file
function generate_case () {
      echo "# Case function"
      echo -e "IFS=\":\" \nfor word in \$response ; do \n case \$word in"
  INPUT="$DIR/config.csv"
  IFS=':'

  [ ! -f $INPUT ] && { echo "$INPUT File not found"; exit 99; }
  while read state task description script
  do
        echo -e " \"$task\") \n SUMMARY+=\"\`cat \$DIR/scripts/$script\`\\\\n\\\\n\" \n COMMAND_TO_RUN+=\"bash \$DIR/scripts/$script; \" \n ;;"
  done < $INPUT
      echo -e " esac \ndone"
      echo -e "unset IFS \n"
  unset IFS
}

# Generate summary window
function generate_summary () {
      echo "# Check if variable SUMMARY was set ('! -n'  = not null variable)"
      echo "if [ ! -n \"\$SUMMARY\" ]; then
              zenity --error --title=\"Installation aborted!\" --text \"Installation aborted!\"
            else
              echo -e \"\$SUMMARY\" | zenity --height=700 --width=1200 --text-info --title=\"Summary - commands to run\" --text=\"\$SUMMARY\"

              # Check if OK was pressed
              if [ \$? = 0 ] ; then
                  # OK pressed
                  pkexec -u \`whoami\` bash -c \"cd \$PWD; \$COMMAND_TO_RUN\"
                  zenity --info --text \"All done!\nPress OK to quit.\"
              else
                  # Cancel pressed
                  zenity --error --text \"Cancel pressed!\"
              fi
fi"
}

# Generate Markdown features table
function generate_markdown_feature_table () {
  # Read config file from main script directory
  echo -e "`date +%F`\n\n|Task|Description|Subscript|\n|---|---|---|"
  INPUT="$DIR/config.csv"
  IFS=':'

  # Read config from CSV file
  [ ! -f $INPUT ] && { echo "$INPUT File not found"; exit 99; }
  while read state task description script
  do
        echo "|$task|$description|[$script](/scripts/$script)|"
  done < $INPUT
  unset IFS
}


# Main program
generate_subscripts_files
start_generate > $DIR/../ubuntu-1804-firstrun-config.bash
generate_zenity_menu >> $DIR/../ubuntu-1804-firstrun-config.bash
generate_case >> $DIR/../ubuntu-1804-firstrun-config.bash
generate_summary >> $DIR/../ubuntu-1804-firstrun-config.bash
generate_markdown_feature_table > $DIR/feature_list.md
