#! /bin/bash

# https://github.com/clvv/fasd
# FASD="$WORKHOST_ECOLOGY_HOME/provision/package/fasd/fasd"
# if [[ -f $FASD ]]
# then
#     # Simply aliasing the function as we do below with others
#     # works, but causes weirdness when scp/ssh-ing in
#     # Instead, we hope the provisioner/manager correctly
#     # links to it from somewhere on the path
#     eval "$(fasd --init auto)"
# fi
# unset FASD

# Defaults and Options {{{1
[[ -n "$RETRIEVIOUS_PRUNE_NAMES" ]] || RETRIEVIOUS_PRUNE_NAMES=""
[[ -n "$RETRIEVIOUS_PRUNE_PATHS" ]] || RETRIEVIOUS_PRUNE_PATHS=""
[[ -n "$RETRIEVIOUS_EDIT_PRUNE_NAMES" ]] || RETRIEVIOUS_EDIT_PRUNE_NAMES=""
[[ -n "$RETRIEVIOUS_EDIT_PRUNE_PATHS" ]] || RETRIEVIOUS_EDIT_PRUNE_PATHS=""
[[ -n "$RETRIEVIOUS_FDFIND_PATH" ]] || RETRIEVIOUS_FDFIND_PATH="fdfind"
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
if [[ -z "${RETRIEVIOUS_DEFAULT_OPEN_APP}" ]]
then
    function __f_xdg_open__() {
        xdg-open "$@"
    }
    [[ $(type -P "rifle") ]] && RETRIEVIOUS_DEFAULT_OPEN_APP="rifle" || RETRIEVIOUS_DEFAULT_OPEN_APP="__f_xdg_open__"
fi
# }}}1

# Functions {{{1

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
        eval "${RETRIEVIOUS_FDFIND_PATH} . --type f ${exc} ${RETRIEVIOUS_FDFIND_OPTS} ${1}"
    }

    function __f_find_dir__() {
        eval "${RETRIEVIOUS_FDFIND_PATH} . --type d ${_FZF_FDFIND_EDIT_EXCLUDE} ${RETRIEVIOUS_FDFIND_OPTS} ${1}"
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
    export -f llc # make function available in subshell
    fzf --preview='llc {}' --preview-window=up:50 -1 --inline-info --ansi $header | __f_regularize_paths__
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
        && echo ${fullpath} || echo ""
}

function __find_and_select_frecent_file__() {
    local fullpath
    [[ -n "$1" ]] && local open_type="$1" || local open_type=""
    [[ ("edit" == "${open_type}") || ("multi" == "${open_type}") ]] && local select_opts="-m" || local select_opts=""
    # fullpath="$(fasd -Rfl | __f_select_file__ "--header={recent}")" \
    fullpath="$(fasd -Rfl | __f_select_file__ "--header={recent}" ${select_opts})" \
        && echo ${fullpath} || echo ""
}

function __find_and_select_frecent_dir__() {
    local dir
    dir="$(fasd -Rdl | __f_select_dir__ )" \
        && echo "${dir}" || echo ""
}

function __grep_and_select_file_rg__() {
    [[ -n $1 ]] && cd $1 # go to provided folder or noop
    local RG_DEFAULT_COMMAND="rg ${_FZF_GREP_PRUNE} -l -i ${RETRIEVIOUS_RIPGREP_OPTS} ${@:2}"
    local fullpath=$(
        FZF_DEFAULT_COMMAND="rg --files" fzf \
        --header=":::$(pwd):::" \
        --phony \
        --inline-info \
        -m \
        --bind "change:reload:$RG_DEFAULT_COMMAND {q} || true" \
        --preview-window=up:50 \
        --preview "rg -i --colors match:fg:black --colors match:bg:yellow --colors match:style:bold --pretty --context 2 {q} {}" | cut -d":" -f1,2 \
        | __f_regularize_paths__
    ) \
        && echo ${fullpath} || echo ""
}

function __grep_and_select_file_ack__() {
    [[ -n $1 ]] && cd $1 # go to provided folder or noop
    local ACK_DEFAULT_COMMAND="ack ${_FZF_GREP_PRUNE} -l -i ${RETRIEVIOUS_ACK_OPTS} ${@:2}"
    echo $ACK_DEFAULT_COMMAND >> log.txt
    local fullpath=$(
        FZF_DEFAULT_COMMAND="ack -f" fzf \
        --header=":::$(pwd):::" \
        --phony \
        --inline-info \
        -m \
        --bind "change:reload:$ACK_DEFAULT_COMMAND {q} || true" \
        --preview-window=up:50 \
        --preview "ack -i --color --color-match 'bold black on_yellow' {q} {}" | cut -d":" -f1,2 \
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

    # Alt-g f <location>: *G*o to found *f*ile path: change to selected file's directory and edit it

    _bind_special_fn "\\egf."  '__find_and_select_file_and_cd_and_edit__ .'
    _bind_special_fn "\\egf1." '__find_and_select_file_and_cd_and_edit__ ..'
    _bind_special_fn "\\egf2." '__find_and_select_file_and_cd_and_edit__ ../..'
    _bind_special_fn "\\egf3." '__find_and_select_file_and_cd_and_edit__ ../../..'
    _bind_special_fn "\\egf4." '__find_and_select_file_and_cd_and_edit__ ../../../..'
    _bind_special_fn "\\egf5." '__find_and_select_file_and_cd_and_edit__ ../../../../..'
    _bind_special_fn "\\egf6." '__find_and_select_file_and_cd_and_edit__ ../../../../../..'
    _bind_special_fn "\\egf7." '__find_and_select_file_and_cd_and_edit__ ../../../../../../..'
    _bind_special_fn "\\egf8." '__find_and_select_file_and_cd_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\egf9." '__find_and_select_file_and_cd_and_edit__ ../../../../../../../../../'
    _bind_special_fn "\\egf~"  '__find_and_select_file_and_cd_and_edit__ $HOME'

    # Alt-g d <location>: *G*o to found *d*irectory path: change to selected directory

    _bind_special_fn "\\egd."  '__find_and_select_dir_and_cd__ .'
    _bind_special_fn "\\egd1." '__find_and_select_dir_and_cd__ ..'
    _bind_special_fn "\\egd2." '__find_and_select_dir_and_cd__ ../..'
    _bind_special_fn "\\egd3." '__find_and_select_dir_and_cd__ ../../..'
    _bind_special_fn "\\egd4." '__find_and_select_dir_and_cd__ ../../../..'
    _bind_special_fn "\\egd5." '__find_and_select_dir_and_cd__ ../../../../..'
    _bind_special_fn "\\egd6." '__find_and_select_dir_and_cd__ ../../../../../..'
    _bind_special_fn "\\egd7." '__find_and_select_dir_and_cd__ ../../../../../../..'
    _bind_special_fn "\\egd8." '__find_and_select_dir_and_cd__ ../../../../../../../..'
    _bind_special_fn "\\egd9." '__find_and_select_dir_and_cd__ ../../../../../../../../../'
    _bind_special_fn "\\egd~"  '__find_and_select_dir_and_cd__ $HOME'

    # Alt-g g <location>: *G*o to *g*repped file path: change to selected file's directory and edit it

    _bind_special_fn "\\egg."  '__grep_and_select_file_and_cd_and_edit__ .'
    _bind_special_fn "\\egg1." '__grep_and_select_file_and_cd_and_edit__ ..'
    _bind_special_fn "\\egg2." '__grep_and_select_file_and_cd_and_edit__ ../..'
    _bind_special_fn "\\egg3." '__grep_and_select_file_and_cd_and_edit__ ../../..'
    _bind_special_fn "\\egg4." '__grep_and_select_file_and_cd_and_edit__ ../../../..'
    _bind_special_fn "\\egg5." '__grep_and_select_file_and_cd_and_edit__ ../../../../..'
    _bind_special_fn "\\egg6." '__grep_and_select_file_and_cd_and_edit__ ../../../../../..'
    _bind_special_fn "\\egg7." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../..'
    _bind_special_fn "\\egg8." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\egg9." '__grep_and_select_file_and_cd_and_edit__ ../../../../../../../../../'
    _bind_special_fn "\\egg~" '__grep_and_select_file_and_cd_and_edit__ $HOME --smart-case --ignore-vcs --no-hidden'
    _bind_special_fn "\\egh"  '__grep_and_select_file_and_cd_and_edit__ . --smart-case --no-ignore-vcs --hidden'

    # Alt-g r f: *G*o to *r*ecent file path: change to selected file's directory and edit it

    _bind_special_fn "\\egrf" __f_select_frecent_file_and_cd_and_edit__

    # Alt-g r d: *G*o to *r*ecent directory path: change to selected directory

    _bind_special_fn "\\egrd" __f_select_frecent_dir_and_cd__

    # Alt-e f <location>: *E*dit *f*ound file (without changing directory)

    _bind_special_fn "\\eef."  '__find_and_select_file_and_edit__ .'
    _bind_special_fn "\\eef1." '__find_and_select_file_and_edit__ ..'
    _bind_special_fn "\\eef2." '__find_and_select_file_and_edit__ ../..'
    _bind_special_fn "\\eef3." '__find_and_select_file_and_edit__ ../../..'
    _bind_special_fn "\\eef4." '__find_and_select_file_and_edit__ ../../../..'
    _bind_special_fn "\\eef5." '__find_and_select_file_and_edit__ ../../../../..'
    _bind_special_fn "\\eef6." '__find_and_select_file_and_edit__ ../../../../../..'
    _bind_special_fn "\\eef7." '__find_and_select_file_and_edit__ ../../../../../../..'
    _bind_special_fn "\\eef8." '__find_and_select_file_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\eef9." '__find_and_select_file_and_edit__ ../../../../../../../../../'
    _bind_special_fn "\\eef~"  '__find_and_select_file_and_edit__ $HOME'

    # Alt-e g <location>: *E*dit *g*repped file (without changing directory)

    _bind_special_fn "\\eeg."  '__grep_and_select_file_and_edit__ .'
    _bind_special_fn "\\eeg1." '__grep_and_select_file_and_edit__ ..'
    _bind_special_fn "\\eeg2." '__grep_and_select_file_and_edit__ ../..'
    _bind_special_fn "\\eeg3." '__grep_and_select_file_and_edit__ ../../..'
    _bind_special_fn "\\eeg4." '__grep_and_select_file_and_edit__ ../../../..'
    _bind_special_fn "\\eeg5." '__grep_and_select_file_and_edit__ ../../../../..'
    _bind_special_fn "\\eeg6." '__grep_and_select_file_and_edit__ ../../../../../..'
    _bind_special_fn "\\eeg7." '__grep_and_select_file_and_edit__ ../../../../../../..'
    _bind_special_fn "\\eeg8." '__grep_and_select_file_and_edit__ ../../../../../../../..'
    _bind_special_fn "\\eeg9." '__grep_and_select_file_and_edit__ ../../../../../../../../../'
    _bind_special_fn "\\eeg~"  '__grep_and_select_file_and_edit__ $HOME'

    # Alt-e r f: *E*dit *r*ecent file (without changing directory)

    _bind_special_fn "\\eerf" __f_select_frecent_file_edit__

    # Alt-p f <location>: *P*ut found filepath: print selected file path on the command line

    _bind_special_cmdline_fn1 "\\epf."  '__find_and_select_file__ . multi'
    _bind_special_cmdline_fn1 "\\epf1." '__find_and_select_file__ .. multi'
    _bind_special_cmdline_fn1 "\\epf2." '__find_and_select_file__ ../.. multi'
    _bind_special_cmdline_fn1 "\\epf3." '__find_and_select_file__ ../../.. multi'
    _bind_special_cmdline_fn1 "\\epf4." '__find_and_select_file__ ../../../.. multi'
    _bind_special_cmdline_fn1 "\\epf5." '__find_and_select_file__ ../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epf6." '__find_and_select_file__ ../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epf7." '__find_and_select_file__ ../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epf8." '__find_and_select_file__ ../../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epf9." '__find_and_select_file__ ../../../../../../../../../ multi'
    _bind_special_cmdline_fn1 "\\epf~"  '__find_and_select_file__ $HOME multi'

    # Alt-p f <location>: *P*ut found directory: print selected directory path on the command line

    _bind_special_cmdline_fn1 "\\epd."  '__find_and_select_dir__ . multi'
    _bind_special_cmdline_fn1 "\\epd1." '__find_and_select_dir__ .. multi'
    _bind_special_cmdline_fn1 "\\epd2." '__find_and_select_dir__ ../.. multi'
    _bind_special_cmdline_fn1 "\\epd3." '__find_and_select_dir__ ../../.. multi'
    _bind_special_cmdline_fn1 "\\epd4." '__find_and_select_dir__ ../../../.. multi'
    _bind_special_cmdline_fn1 "\\epd5." '__find_and_select_dir__ ../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epd6." '__find_and_select_dir__ ../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epd7." '__find_and_select_dir__ ../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epd8." '__find_and_select_dir__ ../../../../../../../.. multi'
    _bind_special_cmdline_fn1 "\\epd9." '__find_and_select_dir__ ../../../../../../../../../ multi'
    _bind_special_cmdline_fn1 "\\epd~"  '__find_and_select_dir__ $HOME multi'

    # Alt-p r *: *P*ut *r*ecent *c*ommands, *f*ilepaths, or *d*irectories on the command line

    _bind_special_cmdline_fn1 "\\erc" __f_select_and_print_history__
    _bind_special_cmdline_fn1 "\\epc" __f_select_and_print_history__
    _bind_special_cmdline_fn1 "\\eprc" __f_select_and_print_history__
    _bind_special_cmdline_fn1 "\\eprf" __find_and_select_frecent_file__
    _bind_special_cmdline_fn1 "\\eprd" __find_and_select_frecent_dir__

    # Alt-o f <location>: *O*pen (using default app) *f*ound file (without changing directory)

    _bind_special_fn "\\eof."  '__find_and_select_file_and_open__ .'
    _bind_special_fn "\\eof1." '__find_and_select_file_and_open__ ..'
    _bind_special_fn "\\eof2." '__find_and_select_file_and_open__ ../..'
    _bind_special_fn "\\eof3." '__find_and_select_file_and_open__ ../../..'
    _bind_special_fn "\\eof4." '__find_and_select_file_and_open__ ../../../..'
    _bind_special_fn "\\eof5." '__find_and_select_file_and_open__ ../../../../..'
    _bind_special_fn "\\eof6." '__find_and_select_file_and_open__ ../../../../../..'
    _bind_special_fn "\\eof7." '__find_and_select_file_and_open__ ../../../../../../..'
    _bind_special_fn "\\eof8." '__find_and_select_file_and_open__ ../../../../../../../..'
    _bind_special_fn "\\eof9." '__find_and_select_file_and_open__ ../../../../../../../../../'
    _bind_special_fn "\\eof~"  '__find_and_select_file_and_open__ $HOME'


}
bind_fuzzy_functions

# }}}1
