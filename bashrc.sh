# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f ~/.bash_prompt ] ; then
    source ~/.bash_prompt
fi

if [ -f ${HOME}/.gpg-agent-info ] && killall -0 gpg-agent >/dev/null 2>/dev/null ; then
    source "${HOME}/.gpg-agent-info"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
fi

# from ki
export LESS="-X -F -R"

pwgen_base64() {
          openssl rand -base64 ${1:-33}
}

pwgen() {
  [ "$2" != "1" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
    tr -cd "$CHAR" </dev/urandom|head -c ${1:-16}
    echo
}

pwgen_sms_safe() {
  [ "$2" != "1" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
    tr -cd "$CHAR" </dev/urandom|tr -d 'lLiIoO01'|head -c ${1:-16}
    echo
}

pwgen_pronanceable() {
    apg -m ${1:-8} -n ${2:-1}
}

netto() {
    [ -z "$1" ] && exit
    perl -e "printf(\"%d\n\",$1/1.23)"
}

plus19() {
    [ -z "$1" ] && exit
    perl -e "printf(\"%d\n\",$1/0.81)"
}

function pxs() {  ps axuwwwf|grep "$*"|grep -v "grep .*$*"; }

# http://tomclegg.net/seahorse-workaround
if [ -z "$SSH_CLIENT" ] ; then
    if [ -f ${HOME}/.gpg-agent-info ] && killall -0 gpg-agent >/dev/null 2>/dev/null ; then
        source "${HOME}/.gpg-agent-info"
        export GPG_AGENT_INFO
        export SSH_AUTH_SOCK
    elif [ -n "$SSH_AUTH_SOCK" \
        -a "${SSH_AUTH_SOCK::13}" = "/tmp/keyring-" \
        -a ! -L "$SSH_AUTH_SOCK" ]
    then
        OLD_AUTH_SOCK="$SSH_AUTH_SOCK"
        eval `ssh-agent`
        mv "$OLD_AUTH_SOCK" "$OLD_AUTH_SOCK"~
        ln -sfn "$SSH_AUTH_SOCK" "$OLD_AUTH_SOCK"
        SSH_AUTH_SOCK="$OLD_AUTH_SOCK"
    fi
fi

ykval() {
    #while read i ; do https_proxy= GET -eS "https://ykval/wsapi/verify.php?id=1&otp=$i" ; done
    while read i ; do
        echo "ID: $(echo -n "$i"|head -c12)"
        https_proxy= wget -O- -q --debug --no-check-certificate "https://ykval/wsapi/verify.php?id=1&otp=$i"
    done
}

_sshsessions() {
    COMPREPLY=($(\ls ~/.ssh/mux-*|awk -F/ '{print $NF}'|sed -e 's/^mux-//' -e "s/$LOGNAME@//" -e 's/:22$//'|egrep -o "^${COMP_WORDS[COMP_CWORD]}[^[:space:]]*"|xargs))
    return 0
}

ssh_check_active() {
    sshsessions
    for i in "${COMPREPLY[@]}" ; do
        echo -n "$i: "
        ssh -O check $i
    done
}

_sshhosts() {
    if [ -f ~/.ssh/known_hosts ] ; then
        res+=$(grep -v "^ *#" ~/.ssh/known_hosts|grep "^[a-z].*,[0-9]*\."|grep -v "^dev[0-9]"|cut -f1 -d,)
    fi
    if [ -f ~/.ssh/config ] ; then
        res+=$(grep -v "^ *#" ~/.ssh/config|grep -i ^host|awk '{print $NF}'|grep -v "^\*")
    fi
    COMPREPLY=($(echo "$res"|sort -u|egrep -o "^${COMP_WORDS[COMP_CWORD]}[^[:space:]]*"|xargs))
    return 0
}

_updatetitle() {
    case $TERM in
        screen*)
            echo -en "\ek$*\e\\"
            ;;
        xterm*)
            echo -en "\033]0;$*\007"
            ;;
    esac
    case $COLORTERM in
        xfce*)
            echo -en "\033]0;$*\007"
            ;;
    esac
}

ssh() {
    ssh=$(which ssh 2>/dev/null)
    _updatetitle "$* (rsync)"
    rsync -ah .bashrc .vimrc .vim .bash_prompt bash_prompt-$LOGNAME .dircolors .gitconfig gitconfig-$LOGNAME .screenrc .psqlrc ${@: -1}:$HOME 2>/dev/null
    _updatetitle "$* (ssh)"
    $ssh $*
    _updatetitle "-bash"
}

sudo() {
    sudo=$(which sudo 2>/dev/null)
    [ -z "$sudo" ] && sudo=/usr/bin/sudo
    if [ "$*" == "su -" ] ; then
        $sudo -i
    else
        $sudo $*
    fi
}

setupgithub() {
    git config user.name asquelt
    git config user.email asq@asq.art.pl
    echo "GIT author set to asquelt <asq@asq.art.pl>"
}

githubsetup() {
    setupgithub
}

courseware_status() {
    [ -f $HOME/.courseware.json ] && cat $HOME/.courseware.json
    [ ! -f $HOME/.courseware.json ] && echo "Courseware is not configured on this machine. ($0:$LINENO)"
}

termcolor() {
    _c=''
    _t=~/.config/xfce4/terminal/terminalrc
    [ "x$1" == "xlight" ] && _c=light
    [ "x$1" == "xdark" ] && _c=dark
    if [ -z "$_c" ] ; then
        read -p "XFCE4 Terminal Color scheme [light/dark]? " -n 1 _c
        [ "x$_c" == "xl" -o "x$_c" == "xL" ] && _c=light
        [ "x$_c" == "xd" -o "x$_c" == "xD" ] && _c=dark
        echo -e "\e[1D$_c"
    fi
    _cc="
[Configuration]
Term=xterm-color
FontName=Monospace 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=80x24
MiscInheritGeometry=FALSE
MiscMenubarDefault=TRUE
MiscMouseAutohide=FALSE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscScrollAlternateScreen=TRUE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.920000
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ShortcutsNoMenukey=TRUE
ShortcutsNoMnemonics=TRUE"
    if [ "x$2" == "xvary" ] ; then
        _cc="$_cc
ColorBackgroundVary=TRUE"
    fi
    if [ "x$_c" == "xdark" ] ; then
        cat <<. >$_t
$_cc
ColorCursor=#0f0f49499999
ColorForeground=#838394949696
ColorBackground=#00002b2b3636
ColorPalette1=#070736364242
ColorPalette2=#dcdc32322f2f
ColorPalette3=#858599990000
ColorPalette4=#b5b589890000
ColorPalette5=#26268b8bd2d2
ColorPalette6=#d3d336368282
ColorPalette7=#2a2aa1a19898
ColorPalette8=#eeeee8e8d5d5
ColorPalette9=#00002b2b3636
ColorPalette10=#cbcb4b4b1616
ColorPalette11=#58586e6e7575
ColorPalette12=#65657b7b8383
ColorPalette13=#838394949696
ColorPalette14=#6c6c7171c4c4
ColorPalette15=#9393a1a1a1a1
ColorPalette16=#fdfdf6f6e3e3
ColorPalette=#000000000000;#aaaa44444444;#4444aaaa4444;#aaaa77774444;#66666666aaaa;#aaaa4444aaaa;#4444aaaaaaaa;#aaaaaaaaaaaa;#555555555555;#ffffa147a147;#a147ffffa147;#ffffffffa147;#a147a147ffff;#ffffa147ffff;#a147ffffffff;#ffffffffffff
.
    elif [ "x$_c" == "xlight" ] ; then
        cat <<. >$_t
$_cc
ColorCursor=#586e75
ColorForeground=#657b83
ColorBackground=#fdfdf934ec36
ColorPalette1=#070736364242
ColorPalette2=#dcdc32322f2f
ColorPalette3=#858599990000
ColorPalette4=#b5b589890000
ColorPalette5=#26268b8bd2d2
ColorPalette6=#d3d336368282
ColorPalette7=#2a2aa1a19898
ColorPalette8=#eeeee8e8d5d5
ColorPalette9=#00002b2b3636
ColorPalette10=#cbcb4b4b1616
ColorPalette11=#58586e6e7575
ColorPalette12=#65657b7b8383
ColorPalette13=#838394949696
ColorPalette14=#6c6c7171c4c4
ColorPalette15=#9393a1a1a1a1
ColorPalette16=#fdfdf6f6e3e3
ColorPalette=#3ff970cd828f;#dcdc32322f2f;#858599990000;#b5b589890000;#26268b8bd2d2;#d3d336368282;#2a2aa1a19898;#070736364242;#1a1c66b5828f;#cbcb4b4b1616;#9393a1a1a1a1;#838394949696;#65657b7b8383;#6c6c7171c4c4;#58586e6e7575;#00002b2b3636
TabActivityColor=#dc322f
.
    else
        xfce4-terminal --color-table
    fi
}

rmate() {
    _u=https://raw.githubusercontent.com/aurora/rmate/master/rmate
    _t=~/rmate
    if [ -f $_t ] ; then
        bash $_t -w -f -v $*
    elif which wget >/dev/null 2>/dev/null ; then
        wget $_u -O $_t -q
        rmate $*
    else
        echo "No wget found, please download $_u to $_t"
    fi
}

ratom() {
    rmate $*
}

varnishncsa_hitmiss() {
    varnishncsa -F "%{Host}i %h/%{X-Remote-Addr}i %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-agent}i\" %{Varnish:hitmiss}x(%{VCL_Log:objhits}x)" $@
}

gitio() {
    url="foo=bar"
    code="foo=baz"
    [ ! -z "$1" ] && url="url=$1"
    [ ! -z "$2" ] && code="code=$2"
    curl -i http://git.io -F "$url" -F "$code"
}

psql() {
    psql=$(which psql 2>/dev/null)
    LESS="-iMSx4 -FX" PAGER=less $psql $*
}

alias sshquit="ssh -O exit"
alias sshremove="ssh-keygen -f "$HOME/.ssh/known_hosts" -R"
alias ssh-copy-id="/usr/bin/ssh-copy-id -oControlPath=/dev/null -oControlPersist=no -oControlMaster=no"

complete -F _sshsessions sshquit
complete -F _sshhosts    ssh
complete -F _sshhosts    sshremove
complete -F _sshhosts    sshinit

#eval `dircolors -b ~/.dircolors`
alias ls='ls --color=always'
alias grep='grep --color'
alias egrep='egrep --color'

alias flash_reinstall='sudo http_proxy=http://proxy:3128 apt-get install --reinstall flashplugin-installer'

alias oowriter=libreoffice

alias snoop_files='sysdig -p "%12user.name %6proc.pid %12proc.name %3fd.num %fd.typechar %fd.name" evt.type=open'

# end from ki

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

export GOPATH=$HOME/golang
export PATH=$GOPATH:$GOPATH/bin:$PATH

function pxs() {  ps axuwwwf|egrep "^USER|$*"|grep -v "grep .*$*"|less -X -E -R; }

alias ds="dstat -tlampM $(lsb_release -r -s 2>/dev/null|grep -q '^5' && echo 'app' || echo 'top_cpu')"

# mco - discovery timeout: 10s, job timeout: 20s
export MCOLLECTIVE_EXTRA_OPTS="--dt 10 -t 20"

