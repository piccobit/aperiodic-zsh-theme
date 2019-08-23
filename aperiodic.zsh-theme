function precmd {

    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)-----()}}
    local pwdsize=${#${(%):-%~}}

    local git_prompt_info_text=$(git_prompt_info)
    local git_prompt_info_size=${#${git_prompt_info_text/git:}}

    if [[ "$git_prompt_info_size" -gt 0 ]]; then
        git_prompt_info_size=$(( git_prompt_info_size + 6 ))
    else
        git_prompt_info_size=-1
    fi

    local virtualenv_prompt_info_size=${#${VIRTUAL_ENV##*/}}

    if [[ "$virtualenv_prompt_info_size" -gt 0 ]]; then
        virtualenv_prompt_info_size=$(( virtualenv_prompt_info_size + 7 ))
    else
        virtualenv_prompt_info_size=-1
    fi

    local ruby_prompt_info_text=$(ruby_prompt_info)
    local ruby_prompt_info_size=${#${${ruby_prompt_info_text/\(ruby-}/\)}}

    if [[ "$ruby_prompt_info_size" -gt 0 ]]; then
        ruby_prompt_info_size=$(( ruby_prompt_info_size + 7 ))
    else
        ruby_prompt_info_size=-1
    fi

    if [[ "$promptsize + $pwdsize + $git_prompt_info_size + $virtualenv_prompt_info_size + $ruby_prompt_info_size" -gt $TERMWIDTH ]]; then
            ((PR_PWDLEN=$TERMWIDTH - $promptsize - $git_prompt_info_size - $virtualenv_prompt_info_size - $ruby_prompt_info_size))
    else
        PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize + $git_prompt_info_size + $virtualenv_prompt_info_size + $ruby_prompt_info_size)))..${PR_HBAR}.)}"
    fi

    ###
    # Get APM info.

    if which ibam > /dev/null; then
        PR_APM_RESULT=`ibam --percentbattery`
    elif which apm > /dev/null; then
        PR_APM_RESULT=`apm`
    elif which pmset > /dev/null; then
        PR_APM_RESULT=${$(pmset -g batt)[(w)8,(w)9]/;}
    fi
}


setopt extended_glob
preexec () {
    if [[ "$TERM" == "screen" ]]; then
        local CMD=${1[(wr)^(*=*|sudo|-*)]}
        echo -n "\ek$CMD\e\\"
    fi
}


setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # Disable some already used prefix and suffix

    unset ZSH_THEME_GIT_PROMPT_PREFIX
    unset ZSH_THEME_GIT_PROMPT_SUFFIX
    export VIRTUAL_ENV_DISABLE_PROMPT=1


    ###
    # See if we can use colors.

    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
        colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
        eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
        eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
        (( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"


    ###
    # Some fancy unicode characters

    PR_ARROW=$'\u27A0'
    PR_CHECKMARK=$'\u2705'
    PR_CROSS=$'\u274C'
    PR_VRBAR=$'\u251C'
    PR_VLBAR=$'\u2524'
    PR_HBAR=$'\u2500'
    PR_URCORNER=$'\u256E'
    PR_ULCORNER=$'\u256D'
    PR_LRCORNER=$'\u256F'
    PR_LLCORNER=$'\u2570'

    
    ###
    # Decide if we need to set titlebar text.

    case $TERM in
        xterm*)
            PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
            ;;
        screen)
            PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
            ;;
        *)
            PR_TITLEBAR=''
            ;;
    esac
    
    
    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
        PR_STITLE=$'%{\ekzsh\e\\%}'
    else
        PR_STITLE=''
    fi
    
    
    ###
    # APM detection

    if which ibam > /dev/null; then
        PR_APM='$PR_VLBAR$PR_RED${${PR_APM_RESULT[(f)1]}[(w)-2]}%%(${${PR_APM_RESULT[(f)3]}[(w)-1]})$PR_CYAN$PR_VRBAR$PR_HBAR'
    elif which apm > /dev/null; then
        PR_APM='$PR_VLBAR$PR_RED${PR_APM_RESULT[(w)5,(w)6]/\% /%%}$PR_CYAN$PR_VRBAR$PR_HBAR'
    elif which pmset > /dev/null; then
        PR_APM='$PR_VLBAR$PR_RED${PR_APM_RESULT/\%/%%}$PR_CYAN$PR_VRBAR$PR_HBAR'
    else
        PR_APM=''
    fi


    ###
    # Finally, the prompt.

    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_CYAN$PR_ULCORNER$PR_VLBAR\
%(!.$PR_RED%SROOT%s.$PR_GREEN%n)@%m:%l$PR_CYAN$PR_VRBAR\
${$(git_prompt_info):+"$PR_HBAR$PR_VLBAR${PR_LIGHT_GREEN}git:${$(git_prompt_info)/git:}$PR_CYAN$PR_VRBAR"}\
${VIRTUAL_ENV:+"$PR_HBAR$PR_VLBAR${PR_LIGHT_GREEN}venv:${VIRTUAL_ENV##*/}$PR_CYAN$PR_VRBAR"}\
${$(ruby_prompt_info):+"$PR_HBAR$PR_VLBAR${PR_LIGHT_GREEN}ruby:${${$(ruby_prompt_info)/\(ruby-/}/\)}$PR_CYAN$PR_VRBAR"}\
$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_VLBAR\
$PR_LIGHT_GREEN%$PR_PWDLEN<...<%~%<<\
$PR_CYAN$PR_VRBAR$PR_URCORNER\

$PR_CYAN$PR_LLCORNER$PR_VLBAR\
%(?.${PR_LIGHT_GREEN}${PR_CHECKMARK} $PR_ARROW 0.$PR_LIGHT_RED$PR_CROSS $PR_ARROW %?)$PR_CYAN\
$PR_LIGHT_BLUE:%(!.$PR_RED.$PR_WHITE)%#$PR_CYAN$PR_VRBAR\
$PR_CYAN\
$PR_NO_COLOUR '

    RPROMPT=' $PR_CYAN\
${(e)PR_APM}\
$PR_VLBAR$PR_YELLOW%D{%H:%M} - %D{%a %b %d}$PR_CYAN$PR_VRBAR$PR_LRCORNER$PR_NO_COLOUR'

    PS2='$PR_CYAN$PR_HBAR\
$PR_CYAN$PR_HBAR$PR_VLBAR\
$PR_LIGHT_GREEN%_$PR_CYAN$PR_VRBAR$PR_HBAR\
$PR_CYAN$PR_NO_COLOUR '
}

setprompt
