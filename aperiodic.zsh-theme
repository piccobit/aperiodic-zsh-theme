function precmd {

    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)-----()--}}
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
        PR_APM_RESULT=${$(pmset -g batt)[(w)8,(w)9]/;/}
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
    # See if we can use extended characters to look nicer.

    typeset -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    PR_HBAR=${altchar[q]:--}
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}


    ###
    # Some fancy unicode characters
    PR_SKULL=$'\u2620'
    PR_THUMBS_UP=$'\xF0\x9F\x91\x8D'
    PR_DOUBLE_RIGHT_ARROW=$'\u21D2'

    
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
        PR_APM='$PR_RED(${${PR_APM_RESULT[(f)1]}[(w)-2]}%%(${${PR_APM_RESULT[(f)3]}[(w)-1]}))$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
    elif which apm > /dev/null; then
        PR_APM='$PR_RED(${PR_APM_RESULT[(w)5,(w)6]/\% /%%})$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
    elif which pmset > /dev/null; then
        PR_APM='$PR_RED(${PR_APM_RESULT/\%/%%})$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
    else
        PR_APM=''
    fi


    ###
    # Finally, the prompt.

    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_CYAN$PR_SHIFT_IN$PR_ULCORNER$PR_HBAR$PR_SHIFT_OUT(\
%(!.$PR_RED%SROOT%s.$PR_GREEN%n)@%m:%l$PR_CYAN)\
${$(git_prompt_info):+"$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(${PR_LIGHT_GREEN}git:${$(git_prompt_info)/git:}$PR_CYAN)"}\
${VIRTUAL_ENV:+"$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(${PR_LIGHT_GREEN}venv:${VIRTUAL_ENV##*/}$PR_CYAN)"}\
${$(ruby_prompt_info):+"$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(${PR_LIGHT_GREEN}ruby:${${$(ruby_prompt_info)/\(ruby-/}/\)}$PR_CYAN)"}\
$PR_SHIFT_IN$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_SHIFT_OUT(\
$PR_MAGENTA%$PR_PWDLEN<...<%~%<<\
$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_URCORNER$PR_SHIFT_OUT\

$PR_CYAN$PR_SHIFT_IN$PR_LLCORNER$PR_HBAR$PR_SHIFT_OUT(\
%(?.${PR_LIGHT_GREEN}${PR_THUMBS_UP} $PR_DOUBLE_RIGHT_ARROW 0.$PR_LIGHT_RED$PR_SKULL $PR_DOUBLE_RIGHT_ARROW %?)$PR_CYAN\
$PR_LIGHT_BLUE:%(!.$PR_RED.$PR_WHITE)%#$PR_CYAN)\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_NO_COLOUR '

    RPROMPT=' $PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
${(e)PR_APM}\
($PR_YELLOW%D{%H:%M} - %D{%a %b %d}$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'

    PS2='$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_LIGHT_GREEN%_$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

setprompt
