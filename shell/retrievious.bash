#! /bin/bash

# Defaults and Options {{{1
[[ -n "$RETRIEVIOUS_PRUNE_NAMES" ]] || RETRIEVIOUS_PRUNE_NAMES=""
[[ -n "$RETRIEVIOUS_PRUNE_PATHS" ]] || RETRIEVIOUS_PRUNE_PATHS=""
[[ -n "$RETRIEVIOUS_EDIT_PRUNE_NAMES" ]] || RETRIEVIOUS_EDIT_PRUNE_NAMES=""
[[ -n "$RETRIEVIOUS_EDIT_PRUNE_PATHS" ]] || RETRIEVIOUS_EDIT_PRUNE_PATHS=""
[[ -n "$RETRIEVIOUS_FDFIND_PATH" ]] || RETRIEVIOUS_FDFIND_PATH="fd"
[[ -n "$RETRIEVIOUS_FDFIND_OPTS" ]] || RETRIEVIOUS_FDFIND_OPTS=""
if [[ -z "${RETRIEVIOUS_GREP_TYPE}" ]]
then
    if [[ $(type -P "rg") ]]
    then
        export RETRIEVIOUS_GREP_TYPE="rg"
    elif [[ $(type -P "ack") ]]
    then
        export RETRIEVIOUS_GREP_TYPE="ack"
    else
        >&2 echo "RETRIEVIOUS requires either 'rg' (ripgrep) or 'ack' available for grep functionality."
    fi
fi
if [[ -z "${RETRIEVIOUS_NO_IGNORE_DOT}" ]]
then
    export RETRIEVIOUS_ACK_SPECIAL_OPTS="--ignore-dir='match:/^\./' --ignore-file='match:/^\./'"
else
    export RETRIEVIOUS_ACK_SPECIAL_OPTS=""
fi
if [[ -z "${RETRIEVIOUS_DEFAULT_OPEN_APP}" ]]
then
    function __f_xdg_open__() {
        xdg-open "$@"
    }
    [[ $(type -P "rifle") ]] && RETRIEVIOUS_DEFAULT_OPEN_APP="rifle" || RETRIEVIOUS_DEFAULT_OPEN_APP="__f_xdg_open__"
fi

# Directory that the (*shudder*) double-chord shortcuts (<alt-r><alt-f>,
# <alt-r><alt-d> etc.) search in.

[[ -n "$RETRIEVIOUS_GLOBAL_SEARCH_ROOT" ]] || RETRIEVIOUS_GLOBAL_SEARCH_ROOT="$HOME"
[[ -n "$RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT" ]] || RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT="$HOME"

# }}}1

# Main Service Functions {{{1

# Candidate Population Functions {{{2

# find/fdfind {{{3

if [[ $(type -P "$RETRIEVIOUS_FDFIND_PATH") ]]
then
    function __f_compose_fzf_fdfind_exclude__() {
        if [[ "$1" == "edit" ]]
        then
            local x_names=${RETRIEVIOUS_EDIT_PRUNE_NAMES}
            local x_paths=${RETRIEVIOUS_EDIT_PRUNE_PATHS}
        else
            local x_names=${RETRIEVIOUS_PRUNE_NAMES}
            local x_paths=${RETRIEVIOUS_PRUNE_PATHS}
        fi
        local name to_prune path
        to_prune=""
        for name in ${x_names}
        do
            to_prune+=" -E '${name}'"
        done
        for path in ${x_paths}
        do
            to_prune+=" -E '${path}'"
        done
        echo "$to_prune"
    }
    _FZF_FDFIND_EXCLUDE=$(__f_compose_fzf_fdfind_exclude__)
    _FZF_FDFIND_EDIT_EXCLUDE=$(__f_compose_fzf_fdfind_exclude__ "edit")
    function __f_find_file__() {
        if [[ $2 == "edit" ]]
        then
            local exc=${_FZF_FDFIND_EDIT_EXCLUDE}
        else
            local exc=${_FZF_FDFIND_EXCLUDE}
        fi
        # eval "${RETRIEVIOUS_FDFIND_PATH} . --type f ${exc} ${RETRIEVIOUS_FDFIND_OPTS} ${1}"
        # `$(tr '${RETRIEVIOUS_GLOBAL_PATH_SEPARATOR}' ' ' <<< ${1})`: split colon delimited string into space delimited strings
        eval "${RETRIEVIOUS_FDFIND_PATH} . --type f ${exc} ${RETRIEVIOUS_FDFIND_OPTS} $(tr ':' ' ' <<< ${1})"
    }

    function __f_find_dir__() {
        # eval "${RETRIEVIOUS_FDFIND_PATH} . --type d ${_FZF_FDFIND_EDIT_EXCLUDE} ${RETRIEVIOUS_FDFIND_OPTS} ${1}"
        # `$(tr '${RETRIEVIOUS_GLOBAL_PATH_SEPARATOR}' ' ' <<< ${1})`: split colon delimited string into space delimited strings
        eval "${RETRIEVIOUS_FDFIND_PATH} . --type d ${_FZF_FDFIND_EDIT_EXCLUDE} ${RETRIEVIOUS_FDFIND_OPTS} $(tr ':' ' ' <<< ${1})"
    }
else
    function __f_compose_fzf_find_prune__() {
        if [[ "$1" == "edit" ]]
        then
            local x_names=${RETRIEVIOUS_EDIT_PRUNE_NAMES}
            local x_paths=${RETRIEVIOUS_EDIT_PRUNE_PATHS}
        else
            local x_names=${RETRIEVIOUS_PRUNE_NAMES}
            local x_paths=${RETRIEVIOUS_PRUNE_PATHS}
        fi
        local name to_prune path
        to_prune=""
        # prune hidden directories by default
        to_prune+=" -name '.[a-zA-Z0-9]*'"
        for name in ${x_names}
        do
            if [ -n "$to_prune" ]
            then
                to_prune+=" -o"
            fi
            to_prune+=" -name '${name}'"
        done
        for path in ${x_paths}
        do
            if [ -n "$to_prune" ]
            then
                to_prune+=" -o"
            fi
            to_prune+=" -path '${path}'"
        done
        local cmd='\( '"${to_prune}"' \) -prune'
        echo "$cmd"
    }
    _FZF_FIND_PRUNE=$(__f_compose_fzf_find_prune__)
    _FZF_FIND_EDIT_PRUNE=$(__f_compose_fzf_find_prune__ "edit")
    function __f_find_file__() {
        if [[ $2 == "edit" ]]
        then
            local exc=${_FZF_FIND_EDIT_PRUNE}
        else
            local exc=${_FZF_FIND_PRUNE}
        fi
        eval "find ${1} ${exc} -o -type f -print"
    }

    function __f_find_dir__() {
        eval "find ${1} ${_FZF_FIND_PRUNE} -o -type d -print"
    }
fi
# }}}3

# ripgrep {{{3
function __f_compose_fzf_grep_prune__() {
    local RPI to_ignore
    if [[ "ack" == ${RETRIEVIOUS_GREP_TYPE} ]]
    then
        local exclude_flag="--ignore-dir "
    elif [[ "rg" == ${RETRIEVIOUS_GREP_TYPE} ]]
    then
        local exclude_flag="-g !"
    else
        # >&2 echo "Unsupported grep program: '${RETRIEVIOUS_GREP_TYPE}'"
        # exit 1
        echo ""
        return
    fi
    RPI=""
    for to_ignore in $RETRIEVIOUS_PRUNE_NAMES
    do
        RPI="${RPI} ${exclude_flag}${to_ignore}"
    done
    for to_ignore in $RETRIEVIOUS_PRUNE_PATHS
    do
        RPI="${RPI} ${exclude_flag}${to_ignore}"
    done
    echo "$RPI"
}
_FZF_GREP_PRUNE=$(__f_compose_fzf_grep_prune__)
# }}}3

# }}}2

# Selecting Functions {{{2

function __f_fasd_log__() {
    # log path in fasd database,
    # failing silently and gracefull
    # if fasd not available
    fasd -A $1 2>/dev/null || true
}

function __f_regularize_paths__() {
    local line entry
    while read -r line;
    do
        # entry=${line}
        # entry=$(realpath "${entry}")
        # entry=$(echo $entry | sed 's/ /\\ /g')
        # echo "${entry}"
        line=$(echo $line | python3 -c "import sys; import shlex; import os; print(shlex.quote(os.path.abspath(sys.stdin.read().strip())))")
        echo $line
    done
}

function __f_dir_of_first_path__() {
    local line
    read line
    line=$(echo $line | python3 -c "import sys; import shlex; import os; print(shlex.quote(os.path.dirname(shlex.split(sys.stdin.read())[0])))")
    echo $line
}

function __f_select_file__() {
    fzf --preview='head -n 500 {}' --preview-window=up:50 -1 --inline-info $@ | __f_regularize_paths__
}

function __f_select_dir__() {
    # fzf --preview='ls -l --color=always {}' --preview-window=up:50 -1 --inline-info --ansi
    [[ -n "$1" ]] && local header="--header=$1" || local header=""
    # export -f llc # make function available in subshell
    fzf --preview="ls -la {}" --preview-window=up:50 -1 --inline-info --ansi $header | __f_regularize_paths__
}
# }}}2

# Finding and Selecting Functions {{{2

function __find_and_select_file__() {
    local start_dir="$1"
    [[ -n "$2" ]] && local open_type="$2" || local open_type=""
    [[ ("edit" == "${open_type}") || ("multi" == "${open_type}") ]] && local select_opts="-m" || local select_opts=""
    local fullpath
    # FZF_DEFAULT_COMMAND="find $start_dir ${_FZF_FIND_PRUNE} -o -type f -print" \
    fullpath="$( \
        __f_find_file__ $start_dir $open_type \
        | __f_select_file__ "--header={$(readlink -f $start_dir)} ${select_opts}"
        )" \
        && echo ${fullpath} || echo ""
}

function __find_and_select_dir__() {
    [[ -n "$1" ]] && local start_dir="$1" || local start_dir="."
    [[ -n "$2" ]] && local open_type="$2" || local open_type=""
    [[ ("edit" == "${open_type}") || ("multi" == "${open_type}") ]] && local select_opts="-m" || local select_opts=""
    local fullpath
    # FZF_DEFAULT_COMMAND="find $start_dir ${_FZF_FIND_PRUNE} -o -type d -print" \
    fullpath="$( \
        __f_find_dir__ $start_dir \
        | __f_select_dir__ "{$(readlink -f $start_dir)} ${select_opts}"
        )" \
        && __f_fasd_log__ ${fullpath} && echo ${fullpath} || echo ""
}

function __find_and_select_frecent_file__() {
    local fullpath
    [[ -n "$1" ]] && local open_type="$1" || local open_type=""
    [[ ("edit" == "${open_type}") || ("multi" == "${open_type}") ]] && local select_opts="-m" || local select_opts=""
    # fullpath="$(fasd -Rfl | __f_select_file__ "--header={recent}")" \
    fullpath="$(fasd -Rfl | __f_select_file__ "--header={recent}" ${select_opts})" \
        && __f_fasd_log__ ${fullpath} && echo ${fullpath} || echo ""
}

function __find_and_select_frecent_dir__() {
    local dir
    dir="$(fasd -Rdl | __f_select_dir__ )" \
        && echo "${dir}" || echo ""
}

function __grep_and_select_file_rg__() {
    # [Ripgrep integration](https://github.com/junegunn/fzf/blob/master/ADVANCED.md#ripgrep-integration)
    [[ -n $1 ]] && cd $1 # go to provided folder or noop
    local INITIAL_QUERY=""
    local RG_PREFIX="rg ${_FZF_GREP_PRUNE} ${RETRIEVIOUS_RIPGREP_OPTS} --column --line-number --no-heading --color=always --smart-case ${@:2}"
    # bat preview:
    # --preview 'bat --color=always {1} --highlight-line {2}' \
    # --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
    # rg preview:
    # --preview "rg -i --colors match:fg:black --colors match:bg:yellow --colors match:style:bold --pretty --context 2 {q} {1}" \
    IFS=: read -ra selected < <(
        FZF_DEFAULT_COMMAND="${RG_PREFIX} '${INITIAL_QUERY}'" \
        fzf \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind "alt-f:change-prompt(fuzzy>)+enable-search+clear-query" \
        --bind "alt-r:change-prompt(regex>)+disable-search+clear-query" \
        --prompt 'regex> ' \
        --ansi \
        --disabled \
        --delimiter : \
        --query "${INITIAL_QUERY}" \
        --header=":::$(pwd):::" \
        --phony \
        --inline-info \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
    )
    [ -n "${selected[0]}" ] \
        && echo "$(echo ${selected[0]} | __f_regularize_paths__)" "+${selected[1]}"
}

function __grep_and_select_file_ack__() {
    [[ -n $1 ]] && cd $1 # go to provided folder or noop
    local ack_opts="${_FZF_GREP_PRUNE} ${RETRIEVIOUS_ACK_SPECIAL_OPTS} -i ${RETRIEVIOUS_ACK_OPTS} ${@:2}"
    local ACK_DEFAULT_COMMAND="ack ${ack_opts} -l"
    local fullpath=$(
        FZF_DEFAULT_COMMAND="ack ${ack_opts} -f" \
        fzf \
        --header=":::$(pwd):::" \
        --phony \
        --inline-info \
        -m \
        --bind "change:reload:$ACK_DEFAULT_COMMAND {q} || true" \
        --preview-window=up:50 \
        --preview "ack -i --color --color-match 'bold black on_yellow' {q} {}" \
        | cut -d":" -f1,2 \
        | __f_regularize_paths__
    ) \
        && echo ${fullpath} || echo ""
}

function __grep_and_select_file__() {
    if [[ "ack" == ${RETRIEVIOUS_GREP_TYPE} ]]
    then
        __grep_and_select_file_ack__ $1
    elif [[ "rg" == ${RETRIEVIOUS_GREP_TYPE} ]]
    then
        __grep_and_select_file_rg__ $1
    else
        >&2 echo "Unsupported grep program: '${RETRIEVIOUS_GREP_TYPE}'"
        echo ""
    fi
}

# }}}2

# Finding/Grepping, Selecting, and Doing Functions {{{2

function __find_and_select_file_and_cd_and_edit__() {
    local fullpath=$(__find_and_select_file__ $1 "edit")
    # non-multiselect version: echo "cd $(dirname ${fullpath}) && $EDITOR $(basename ${fullpath})"
    # multi-select version (only grabs the directory of the first item:  echo ${fullpath} | cut -d' ' -f1
    [[ -n "$fullpath" ]] \
        && echo "cd $(echo $fullpath | __f_dir_of_first_path__) && $EDITOR ${fullpath}" \
        || echo ""
}

function __find_and_select_file_and_edit__() {
    local fullpath=$(__find_and_select_file__ $1 "edit")
    # non-multiselect version: echo "cd $(dirname ${fullpath}) && $EDITOR $(basename ${fullpath})"
    [[ -n "$fullpath" ]] \
        && echo "$EDITOR ${fullpath}" \
        || echo ""
}

function __find_and_select_file_and_open__() {
    local fullpath=$(__find_and_select_file__ $1 "")
    # non-multiselect version: echo "cd $(dirname ${fullpath}) && $EDITOR $(basename ${fullpath})"
    [[ -n "$fullpath" ]] \
        && echo "$RETRIEVIOUS_DEFAULT_OPEN_APP ${fullpath}" \
        || echo ""
}

function __find_and_select_file_and_cd__() {
    local fullpath=$(__find_and_select_file__ $1)
    [[ -n "$fullpath" ]] && \
        echo "cd $(dirname ${fullpath})" \
        || echo ""
}

function __find_and_select_dir_and_cd__() {
    local fullpath=$(__find_and_select_dir__ $1)
    [[ -n "$fullpath" ]] && \
        echo "cd ${fullpath}" \
        || echo ""
}

function __grep_and_select_file_and_cd_and_edit__() {
    local fullpath=$(__grep_and_select_file__ $1)
    [[ -n $fullpath ]] && echo "cd $( echo ${fullpath} | __f_dir_of_first_path__) && $EDITOR ${fullpath}" || echo ""
}

function __grep_and_select_file_and_edit__() {
    local fullpath=$(__grep_and_select_file__ $1)
    [[ -n $fullpath ]] && echo "$EDITOR ${fullpath}" || echo ""
}

function __f_select_and_print_history__() {
    [[ -n $RETRIEVIOUS_BASH_COMMAND_HISTORY ]] && local hfile=$RETRIEVIOUS_BASH_COMMAND_HISTORY || local hfile=~/.bash_history
    local line
    # (1) pull last n lines from extended bash log
    # (2) strip extra information, so only command strings
    # (3) reverse lines, so most recent is at top
    # (4) keep only the first (i.e., most recent) duplicate of command strings
    # (5) pass to fuzzy selector
    line=$(tail -n10000 ${RETRIEVIOUS_BASH_COMMAND_HISTORY} \
            | awk -F ' ~~~ ' '{print $3}' \
            | awk '{a[NR]=$0} END {for(i=NR;i>0;i--)print a[i]}' \
            | awk '{ if (!h[$0]) { print $0; h[$0]=1 } }' \
            | fzf -1 --no-sort --inline-info)
    echo $line
}

function __f_select_frecent_dir_and_cd__() {
    local fullpath=$(__find_and_select_frecent_dir__)
    [[ -n "$fullpath" ]] && \
        echo "cd ${fullpath}" \
        || echo ""
}

function __f_select_frecent_file_edit__() {
    local fullpath=$(__find_and_select_frecent_file__ "edit")
    [[ -n "$fullpath" ]] && \
        echo "$EDITOR ${fullpath}" \
        || echo ""
}

function __f_select_frecent_file_and_cd_and_edit__() {
    local fullpath=$(__find_and_select_frecent_file__ "edit")
    [[ -n "$fullpath" ]] \
        && echo "cd $( echo ${fullpath} | __f_dir_of_first_path__) && $EDITOR ${fullpath}" \
        || echo ""
}

# }}}2

# Keybinding Support Functions {{{2

function _bind_special_fn() {
    local key="$1"
    local fn="$2"
    if [[ -o vi ]]; then
        # Reference:
        #   bind '"\C-fg": "\C-x\C-addi`__find_and_select_dir_and_cd__`\C-x\C-e\C-x\C-r\C-m"'
        #   bind -m vi-command '"\C-fg": "ddi`__find_and_select_dir_and_cd__`\C-x\C-e\C-x\C-r\C-m"'

        # vi insert mode
        local cmd1=""
        cmd1+='"'"${key}"'"'
        cmd1+=': "\C-x\C-addi$('
        cmd1+=${fn}
        cmd1+=')\C-x\C-e\C-x\C-r\C-m"'
        local cx1="bind '$cmd1'"
        eval $cx1

        # vi normal mode
        local cmd2=""
        cmd2+='"'"${key}"'"'
        cmd2+=': "ddi$('
        cmd2+=${fn}
        cmd2+=')\C-x\C-e\C-x\C-r\C-m"'
        cx2="bind -m vi-command '$cmd2'"
        eval $cx2

    else
        # bind '"\C-tg": " \C-e\C-u`__select_and_print_discovered_directory_cd__`\e\C-e\er\C-m"'
        local cmd1=""
        cmd1+='"'"${key}"'"'
        cmd1+=': " \C-e\C-u$('
        cmd1+=${fn}
        cmd1+=')\e\C-e\er\C-m"'
        local cx1="bind '$cmd1'"
        eval $cx1
    fi
}

function _bind_special_cmdline_fn1() {
    local key="$1"
    local fn="$2"
    if [[ -o vi ]]; then
        # Reference:
        # bind '"\C-rq": "\C-x\C-a$a \C-x\C-addi`__f_select_and_print_history__`\C-x\C-e\C-x\C-a0Px$a \C-x\C-r\C-x\C-axa "'
        # bind '"\C-rC": "\C-x\C-addi`__f_select_and_print_history__`\C-x\C-e\C-x\C-r\C-x^\C-x\C-a$a"'
        # bind '"\C-tD": "\C-x\C-a$a \C-x\C-addi`__select_and_print_discovered_directory__`\C-x\C-e\C-x\C-a0Px$a \C-x\C-r\C-x\C-axa "'
        # bind -m vi-command '"\C-tD": "i\C-tD"'

        # vi insert mode
        local cmd1=""
        cmd1+='"'"${key}"'"'
        cmd1+=': "\C-x\C-a$a \C-x\C-addi$('
        cmd1+=${fn}
        cmd1+=')\C-x\C-e\C-x\C-a0Px$a \C-x\C-r\C-x\C-axa "'
        local cx1="bind '$cmd1'"
        # echo $cx1
        eval $cx1

        # vi normal mode
        local cmd2=""
        cmd2+='"'"${key}"'"'
        cmd2+=': "i'"${key}"'"'
        cx2="bind -m vi-command '$cmd2'"
        # echo $cx2
        eval $cx2

    else
        local cmd1=""
        cmd1+='"'"${key}"'"'
        cmd1+=': " \C-u \C-a\C-k$('
        cmd1+=${fn}
        cmd1+=')\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\e% \C-h"'
        local cx1="bind '$cmd1'"
        eval $cx1
    fi
}


# }}}2

# }}}1

# Key Binding {{{1

function bind_fuzzy_functions() {
    if [[ -o vi ]]; then
        # We'd usually use "\e" to enter vi-movement-mode so we can do our magic,
        # but this incurs a very noticeable delay of a half second or so,
        # because many other commands start with "\e".
        # Instead, we bind an unused key, "\C-x\C-a",
        # to also enter vi-movement-mode,
        # and then use that thereafter.
        # (We imagine that "\C-x\C-a" is relatively unlikely to be in use.)
        bind '"\C-x\C-a": vi-movement-mode'
        bind '"\C-x\C-e": shell-expand-line'
        bind '"\C-x\C-r": redraw-current-line'
        bind '"\C-x^": history-expand-line'
    else
        # Required to refresh the prompt after fzf
        bind '"\e%": redraw-current-line'
        bind '"\e^": history-expand-line'
    fi

    #### 1.1.1. Retrieve [to visit]: [Find] [File]

    _bind_special_fn "\\er~"  '__find_and_select_file_and_cd_and_edit__ $HOME'
    _bind_special_fn "\\er\\ef"  '__find_and_select_file_and_cd_and_edit__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT'
    _bind_special_fn "\\er\\C-f"  '__find_and_select_file_and_cd_and_edit__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT'
    _bind_special_fn "\\er."  '__find_and_select_file_and_cd_and_edit__ .'
    _bind_special_fn "\\er1." '__find_and_select_file_and_cd_and_edit__ ..'
    _bind_special_fn "\\er2." '__find_and_select_file_and_cd_and_edit__ ../..'
    _bind_special_fn "\\er3." '__find_and_select_file_and_cd_and_edit__ ../../..'
    _bind_special_fn "\\er4." '__find_and_select_file_and_cd_and_edit__ ../../../..'
    _bind_special_fn "\\er5." '__find_and_select_file_and_cd_and_edit__ ../../../../..'
    _bind_special_fn "\\er6." '__find_and_select_file_and_cd_and_edit__ ../../../../../..'
    _bind_special_fn "\\er7." '__find_and_select_file_and_cd_and_edit__ ../../../../../../..'
    _bind_special_fn "\\er8." '__find_and_select_file_and_cd_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\er9." '__find_and_select_file_and_cd_and_edit__ ../../../../../../../../../'

    #### 1.1.2. Retrieve [to visit]: [Find] Directory

    _bind_special_fn "\\erd~"  '__find_and_select_dir_and_cd__ $HOME'
    _bind_special_fn "\\er\\ed"  '__find_and_select_dir_and_cd__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT'
    _bind_special_fn "\\er\\C-d"  '__find_and_select_dir_and_cd__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT'
    _bind_special_fn "\\erd."  '__find_and_select_dir_and_cd__ .'
    _bind_special_fn "\\erd1." '__find_and_select_dir_and_cd__ ..'
    _bind_special_fn "\\erd2." '__find_and_select_dir_and_cd__ ../..'
    _bind_special_fn "\\erd3." '__find_and_select_dir_and_cd__ ../../..'
    _bind_special_fn "\\erd4." '__find_and_select_dir_and_cd__ ../../../..'
    _bind_special_fn "\\erd5." '__find_and_select_dir_and_cd__ ../../../../..'
    _bind_special_fn "\\erd6." '__find_and_select_dir_and_cd__ ../../../../../..'
    _bind_special_fn "\\erd7." '__find_and_select_dir_and_cd__ ../../../../../../..'
    _bind_special_fn "\\erd8." '__find_and_select_dir_and_cd__ ../../../../../../../..'
    _bind_special_fn "\\erd9." '__find_and_select_dir_and_cd__ ../../../../../../../../../'

    #### 1.2.1. Retrieve [to visit]: Grep [File]

    _bind_special_fn "\\erg~" '__grep_and_select_file_and_cd_and_edit__ $HOME --smart-case --ignore-vcs --no-hidden'
    _bind_special_fn "\\er\\eg" '__grep_and_select_file_and_cd_and_edit__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT --smart-case --ignore-vcs --no-hidden'
    _bind_special_fn "\\er\\C-g" '__grep_and_select_file_and_cd_and_edit__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT --smart-case --ignore-vcs --no-hidden'
    _bind_special_fn "\\erg."  '__grep_and_select_file_and_cd_and_edit__ .'
    _bind_special_fn "\\erg1." '__grep_and_select_file_and_cd_and_edit__ ..'
    _bind_special_fn "\\erg2." '__grep_and_select_file_and_cd_and_edit__ ../..'
    _bind_special_fn "\\erg3." '__grep_and_select_file_and_cd_and_edit__ ../../..'
    _bind_special_fn "\\erg4." '__grep_and_select_file_and_cd_and_edit__ ../../../..'
    _bind_special_fn "\\erg5." '__grep_and_select_file_and_cd_and_edit__ ../../../../..'
    _bind_special_fn "\\erg6." '__grep_and_select_file_and_cd_and_edit__ ../../../../../..'
    _bind_special_fn "\\erg7." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../..'
    _bind_special_fn "\\erg8." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\erg9." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../../../../'
    _bind_special_fn "\\ergh"  '__grep_and_select_file_and_cd_and_edit__ . --smart-case --no-ignore-vcs --hidden'

    #### 1.3.1. Retrieve [to visit]: *R*ecent *f*iles and *d*irectories

    _bind_special_fn "\\errf" __f_select_frecent_file_and_cd_and_edit__
    _bind_special_fn "\\errd" __f_select_frecent_dir_and_cd__
    _bind_special_fn "\\errc" __f_select_and_print_history__

    #### 2.1.1. Retrieve to *p*aste: [Find] [File]

    _bind_special_cmdline_fn1 "\\erpf~"  '__find_and_select_file__ $HOME multi'
    _bind_special_cmdline_fn1 "\\er\\pf"  '__find_and_select_file__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT multi'
    _bind_special_cmdline_fn1 "\\er\\p\\C-f"  '__find_and_select_file__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT multi'
    _bind_special_cmdline_fn1 "\\erpf."  '__find_and_select_file__ . multi'
    _bind_special_cmdline_fn1 "\\erpf1." '__find_and_select_file__ .. multi'
    _bind_special_cmdline_fn1 "\\erpf2." '__find_and_select_file__ ../.. multi'
    _bind_special_cmdline_fn1 "\\erpf3." '__find_and_select_file__ ../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf4." '__find_and_select_file__ ../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf5." '__find_and_select_file__ ../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf6." '__find_and_select_file__ ../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf7." '__find_and_select_file__ ../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf8." '__find_and_select_file__ ../../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpf9." '__find_and_select_file__ ../../../../../../../../../ multi'

    #### 2.1.2. Retrieve to *p*aste: [Find] Directory

    _bind_special_cmdline_fn1 "\\erpd."  '__find_and_select_dir__ . multi'
    _bind_special_cmdline_fn1 "\\er\\pd"  '__find_and_select_dir__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT multi'
    _bind_special_cmdline_fn1 "\\er\\p\\C-d"  '__find_and_select_dir__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT multi'
    _bind_special_cmdline_fn1 "\\erpd1." '__find_and_select_dir__ .. multi'
    _bind_special_cmdline_fn1 "\\erpd2." '__find_and_select_dir__ ../.. multi'
    _bind_special_cmdline_fn1 "\\erpd3." '__find_and_select_dir__ ../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd4." '__find_and_select_dir__ ../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd5." '__find_and_select_dir__ ../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd6." '__find_and_select_dir__ ../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd7." '__find_and_select_dir__ ../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd8." '__find_and_select_dir__ ../../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\erpd9." '__find_and_select_dir__ ../../../../../../../../../ multi'

    #### 2.3.1. Retrieve to *p*aste: *R*ecent *f*iles, *d*irectories, and *c*ommands

    _bind_special_cmdline_fn1 "\\errpf" __find_and_select_frecent_file__
    _bind_special_cmdline_fn1 "\\errpd" __find_and_select_frecent_dir__
    _bind_special_cmdline_fn1 "\\errpc" __f_select_and_print_history__

    #### 3.1.1. Retrieve to *o*pen: [Find] [File]

    _bind_special_fn "\\ero~"  '__find_and_select_file_and_open__ $HOME'
    _bind_special_fn "\\er\\eo"  '__find_and_select_file_and_open__ $RETRIEVIOUS_GLOBAL_SEARCH_ROOT'
    _bind_special_fn "\\er\\e\\C-o"  '__find_and_select_file_and_open__ $RETRIEVIOUS_GLOBAL_SEARCH_ALT_ROOT'
    _bind_special_fn "\\ero."  '__find_and_select_file_and_open__ .'
    _bind_special_fn "\\ero1." '__find_and_select_file_and_open__ ..'
    _bind_special_fn "\\ero2." '__find_and_select_file_and_open__ ../..'
    _bind_special_fn "\\ero3." '__find_and_select_file_and_open__ ../../..'
    _bind_special_fn "\\ero4." '__find_and_select_file_and_open__ ../../../..'
    _bind_special_fn "\\ero5." '__find_and_select_file_and_open__ ../../../../..'
    _bind_special_fn "\\ero6." '__find_and_select_file_and_open__ ../../../../../..'
    _bind_special_fn "\\ero7." '__find_and_select_file_and_open__ ../../../../../../..'
    _bind_special_fn "\\ero8." '__find_and_select_file_and_open__ ../../../../../../../..'
    _bind_special_fn "\\ero9." '__find_and_select_file_and_open__ ../../../../../../../../../'


}
bind_fuzzy_functions

# }}}1

# Special Commands {{{1
function ef() {
    [[ -n "$1" ]] && local dir="$1" || local dir="."
    # __find_and_select_file__ ${dir} multi
    cmd="$(__find_and_select_file_and_edit__ ${dir} multi)"
    echo $cmd
    eval $cmd
}
# }}}1 Special Commands

