# GIT BRANCH SELECTOR

alias lb="echo 'ran git branch --sort=committerdate | tail -30' && git branch --sort=committerdate | tail -30"

select_option() 
{

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

sb(){
  if [[ $# -gt 0 ]]; then
    echo "grepping is $1"
    IFS=$'\n' read -r -d '' -a options < <( git branch --sort=committerdate | grep "sprint$1" )
  else
    echo "no grepping"
    IFS=$'\n' read -r -d '' -a options < <( git branch --sort=committerdate | tail -20 && printf '\0' )
  fi

  echo "Select one option using up/down keys and enter to confirm:"
  echo

  select_option "${options[@]}"
  choice=$?

  echo "Choosen index = $choice"
  echo "        value = ${options[$choice]}"

  target=`echo "${options[$choice]}" | xargs`
  echo "branch '$target' selected"

  git co "${target}"
}

# END GIT BRANCH SELECTOR