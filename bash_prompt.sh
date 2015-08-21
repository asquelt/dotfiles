# .bash_prompt

#set -x

# puppet managed file, for more info 'puppet-find-resources $filename'
# BEFORE YOU MAKE ANY CHANGES, READ https://stonka.non.3dart.com/wiki/wiki/Puppet#Zarz.C4.85dzanie_konfiguracjami

__git_ps1 () {
    true
}

__gitdir () {
    git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree --short HEAD 2>/dev/null
}

[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ] && source /usr/share/git-core/contrib/completion/git-prompt.sh
[ -f /etc/bash_completion.d/git-prompt ] && source /etc/bash_completion.d/git-prompt

getprocuid() {
    callerid=$(id -u)
    process=$1
    if [ -z "$process" ] || [ $process -eq 1 ] ; then
        echo 0
        return
    fi
    ownerid=$(cat /proc/$process/status|grep ^Uid|awk '{print $NF}')
    # procnam=$(cat /proc/$process/status|grep ^Name|awk '{print $NF}') # DEBUG
    # echo "D: $procnam ($ownerid)" >&2 # DEBUG
    if [ $ownerid -ne $callerid ] ; then
        echo $ownerid
        return
    else
        ppid=$(cat /proc/$process/status|grep ^PPid|awk '{print $NF}')
        ownerid=$(getprocuid $ppid)
        echo $ownerid
        return
    fi
}

root_ps1_init() {
    _d="/home/$PS1_MYNAME/.bashrc /home/$PS1_MYNAME/.bash_prompt"
    for _f in $_d ; do
        echo "Checking $_f in /root/.bashrc, please provide password if asked"
        res=$(sudo grep "$_f" /root/.bashrc)
        if [ $? -ne 0 ] ; then
            echo -en "Will add to /root/.bashrc:"
            echo -en "\n\n[ -f \"$_f\" ] && source $_f\n\n" | sudo tee -a /root/.bashrc
        else
            echo -en "Nothing to do, approperiate line already there:\n\n$res\n\n"
        fi
    done
}

# if PS1_MYNAME is not defined it means that this script has not been sourced, but instead PS1 has been inherited by sudo
# so we warn operator in PS1 that he should run root_ps1_init which adds ``. ~/$SUDO_USER/.bashrc'' to /root/.bashrc.
if [ "$LOGNAME" != "root" ] ; then
    PS1_MYNAME="$LOGNAME"
elif [ ! -z "$SUDO_USER" ] ; then
    PS1_MYNAME="$SUDO_USER"
else
    PS1_MYNAME="$(getent passwd $(getprocuid $$))"
fi

export PS1_MYNAME

# git PS1 features:
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
#export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
# # "verbose" for count of changes, auto for only < >
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_DESCRIBE_STYLE="branch"

#export no_processors=$(cat /proc/cpuinfo | grep ^processor|wc -l)

export PS1='\[\e[1;32m\]$(timer_show 2>/dev/null)\[\e[1;31m\]$(ps1_exitcodes 2>/dev/null)$([ -z "$PS1_MYNAME" ] && echo "*** Root PS1 is only partly initialized, please exit sudo session and run \"root_ps1_init\" to complete! *** ")\[\e[0m\]\[\e[0;1;30m\]${STY#*.}$((read uptime crap ; if [ ${uptime%.*} -lt 3600 ] ; then echo -ne "\[\e[1;36m\]BOOT\[\e[0;1;30m\] " ; fi ) </proc/uptime)$((read load crap ; export no_processors=$(cat /proc/cpuinfo | grep ^processor|wc -l) ; if [ ${load%.*} -gt $((no_processors*4)) ] ; then echo -ne "\[\e[1;31m\]HIGH " ; fi ; if [ ${load%.*} -gt $((no_processors*2)) ] ; then echo -ne "\[\e[1;31m\]LOAD" ; fi ; if [ ${load%.*} -gt $no_processors ] ; then echo -ne "\[\e[1;33m\]" ; fi ; echo -ne "<${load%.*}>") </proc/loadavg)$( if [ $UID -eq 0 ] ; then echo -ne "\[\e[0;31m\]" ; else echo -ne "\[\e[0;32m\]" ; fi )\u\[\e[0;1;30m\]@\[\e[0;35m\]\h$([ -r /home/$PS1_MYNAME/NICKNAME ] && (read nick ; echo -ne "\[\e[1;35m\]/\[\e[0;35m\]$nick") </home/$PS1_MYNAME/NICKNAME )\[\e[0;1;30m\](\[\e[0m\]\#\[\e[0;1;30m\]$(gitmagic echo "| " 2>/dev/null)\[$(gitmagic pre 2>/dev/null)\]$(gitmagic 2>/dev/null)\[$(gitmagic post 2>/dev/null)\])\[\e[0;35m\]\w\[\e[0;1;30m\]\\$\[\e[0m\] '

export PS2='\[\e[0;1;30m\]> \[\e[0m\]'

#export PS4="<$LINENO>+ "
export PS4="+ "

ps1_exitcode() {
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo -en "(EXIT:$ret) "
    fi
}

ps1_exitcodes() {
    STR=${PIPESTATUS[*]}
    sum=0
    for res in $STR ; do
        sum=$((res+sum))
    done
    if [ $sum -ne 0 ] ; then
        echo -en "(EXIT:$STR) "
    fi
}

gitmagic() {
    gitpre="\e[0;32m"
    gitpost="\e[0;1;30m"

    if [ ! -z "$(__gitdir)" ]; then
        if [ "$1" == "echo" ] ; then
            echo -en $2
        elif [ "$1" == "post" ] ; then
            echo -en "$gitpost"
        else
            gitprompt=$(__git_ps1 "%s")
            if [[ "$gitprompt" =~ "%" ]]; then # there are unadded files
                gitpre="\e[1;36m"
                gitmsg="add "
            elif [[ "$gitprompt" =~ "*" ]]; then # there are local changes
                gitpre="\e[1;33m"
                gitmsg="commit "
            elif [[ "$gitprompt" =~ "u+" ]]; then # you are ahead of origin
                gitpre="\e[1;31m"
                gitmsg="push "
            elif [[ "$gitprompt" =~ "u-" ]]; then # you are behind origin
                gitpre="\e[1;35m"
                gitmsg="pull "
            elif [[ "$gitprompt" =~ "\$" ]]; then # there are stashes
                gitpre="\e[1;30m"
            fi
            if [ "$1" == "pre" ] ; then
                echo -en "$gitpre"
            else
                gitcommits=$(printf "%02d" $(git log --format=%aN --since=$(date +%Y-%m-%dT00:00)|grep $LOGNAME|wc -l))
                if [ $gitcommits -gt 0 ] ; then
                    gitmsg="$gitcommits $gitmsg"
                fi
                echo -en "$gitmsg$gitprompt"
            fi
        fi
    fi
}

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  timer_show=$(($SECONDS - $timer))
  unset timer
}

function timer_show {
  if [ ! -z "$timer_show" ] && [ $timer_show -gt 0 ] ; then
    echo -en "(LAST:${timer_show}s) "
  fi
}

trap 'timer_start' DEBUG

if [ "$PROMPT_COMMAND" == "" ]; then
  PROMPT_COMMAND="timer_stop"
else
  # this must be last command ran before prompt (http://jakemccrary.com/blog/2015/05/03/put-the-last-commands-run-time-in-your-bash-prompt/)
  PROMPT_COMMAND="$PROMPT_COMMAND; timer_stop"
fi

export HISTSIZE=10000

function pxs() {  ps axuwwwf|egrep "^USER|$*"|grep -v "grep .*$*"; }

alias ds="dstat -tlampM $(lsb_release -r -s 2>/dev/null|grep -q '^5' && echo 'app' || echo 'top_cpu')"

VIMOPTS="set fenc=utf-8"

if alias whowasi >/dev/null 2>/dev/null ; then
    ORIGPWNAM=$(whowasi)
    [ -f /home/$ORIGPWNAM/.vimrc ] && VIMRC=/home/$ORIGPWNAM/.vimrc
    alias vim="ORIG_LOGNAME=\"$LOGNAME\" LOGNAME=\"$ORIGPWNAM\" MYVIMRC=\"$VIMRC\" vim -c \"$VIMOPTS\""
else
    alias vim="vim -c \"$VIMOPTS\""
fi

# mco - discovery timeout: 10s, job timeout: 20s
export MCOLLECTIVE_EXTRA_OPTS="--dt 10 -t 20"

# history control
HISTFILESIZE=50000
HISTSIZE=$HISTFILESIZE
HISTIGNORE=reboot*:halt*:shutdown*:pd\ *:rm\ -rf\ /*
HISTCONTROL=ignorespace
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
alias exit-without-history='kill -9 $$'

if [ ! -z "$PS1_MYNAME" ] && [ "$LOGNAME" != "$PS1_MYNAME" ] ; then
    [ ! -f ~/.bash_history_$PS1_MYNAME ] && [ -f ~/.bash_history ] && cat ~/.bash_history | egrep -v "($(echo "$HISTIGNORE"|sed -e 's/*/.*/g' -e 's/:/|/g'))" > ~/.bash_history_$PS1_MYNAME && echo "History file ~/.bash_history_$PS1_MYNAME initiated, please relogin!" && exit
    HISTFILE=~/.bash_history_$PS1_MYNAME
fi

