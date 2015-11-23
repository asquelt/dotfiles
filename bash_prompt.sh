# .bash_prompt

#set -x

# latest version of this file is available online: http://git.io/~asq/prompt

# if git completion is not available make sure that PS1 won't return any errors
__git_ps1 () {
    true
}

# fast check whether directory we're currently in is git repo
__gitdir () {
    git rev-parse --git-dir --is-inside-git-dir --is-bare-repository --is-inside-work-tree --short HEAD 2>/dev/null
}

# include git completion script
[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ] && source /usr/share/git-core/contrib/completion/git-prompt.sh
[ -f /etc/bash_completion.d/git-prompt ] && source /etc/bash_completion.d/git-prompt
[ -f /usr/local/etc/bash_completion.d/git-prompt.sh ] && source /usr/local/etc/bash_completion.d/git-prompt.sh

# check uid of parent process (useful to check who called su/sudo)
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

# get cpu count to calculate load average danger threshold
ps1_countcpu() {
    if syscpu=$(sysctl -n hw.ncpu 2>/dev/null) ; then
        echo $syscpu
    elif [ -f /proc/cpuinfo ] ; then
        cpu=0
        while read key nil ; do
            if [ "$key" == "processor" ] ; then
                ((cpu=cpu+1))
            fi
        done < /proc/cpuinfo
        echo $cpu
    else
        echo 0
    fi
}

# get uptime
ps1_uptime() {
    if sysupt=$(sysctl -n kern.boottime 2>/dev/null) ; then
        sysupt=${sysupt%,*}
        sysupt=${sysupt##* }
        echo $sysupt
    elif [ -f /proc/uptime ] ; then
        read upt < /proc/uptime
        echo ${upt%%.*}
    else
        echo 9999999
    fi
}

# get loadavg
ps1_loadavg() {
    if sysload=$(sysctl -n vm.loadavg 2>/dev/null) ; then
        sysload=${sysload%%,*}
        sysload=${sysload##* }
        echo $sysload
    elif [ -f /proc/loadavg ] ; then
        read load nil < /proc/loadavg
        load=${load%%.*}
        echo $load
    else
        echo -1
    fi
}

# install this script to root user dotfiles
root_ps1_init() {
    _d="$PS1_HOME/$PS1_MYNAME/.bashrc $PS1_HOME/$PS1_MYNAME/.bash_prompt"
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
    PS1_MYNAME="$(getent passwd $(getprocuid $$)|cut -f1 -d:)"
fi

if [ -d /Users ] ; then
    PS1_HOME=/Users
elif [ -d /home ] ; then
    PS1_HOME=/Users
else
    PS1_HOME=~
fi

export PS1_MYNAME PS1_HOME

# git PS1 features:
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
#export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
# # "verbose" for count of changes, auto for only < >
export GIT_PS1_SHOWUPSTREAM="verbose"
export GIT_PS1_DESCRIBE_STYLE="branch"

export no_processors=$(ps1_countcpu)

if bash --version | grep -qi apple ; then
    esc='\033'
else
    esc='\e'
fi

export reset="$esc[0m"
export black="$esc[1;30m"
export gray="$esc[0;1;30m"
export blue="$esc[1;34m"
export cyan="$esc[1;36m"
export green="$esc[1;32m"
export lime="$esc[0;32m"
export orange="$esc[1;33m"
export purple="$esc[1;35m"
export red="$esc[0;31m"
export redalert="$esc[1;31m"
export violet="$esc[0;35m"
export white="$esc[1;37m"
export yellow="$esc[1;33m"

PS1="" # reset prompt
PS1+="\[${reset}\]" # reset all colors
PS1+="\$([ ! -z \"\$ASCIINEMA_REC\" ] && echo \"\[${redalert}\]⬤ \")" # add a mark if we're recording this session
PS1+="\[${cyan}\]\$(ps1_setcol0 2>/dev/null)" # if previous command wrote no newline, reset it for readibility
PS1+="\[${green}\]\$(timer_show 2>/dev/null)" # show execution time of previous command if non-zero
PS1+="\[${redalert}\]\$(ps1_exitcodes 2>/dev/null)" # show exit of previous command if non-zero
PS1+="\$(if [ \$(ps1_uptime 2>/dev/null) -lt 3600 ] ; then echo -ne \"\[${cyan}\]BOOT\[${gray}\] \" ; fi )" # warn if recently rebooted (less than hour ago)
PS1+="\$([ -z \"\$PS1_MYNAME\" ] && echo \"\[${redalert}\]*** Root PS1 is only partly initialized, please exit sudo session and run 'root_ps1_init' to complete! *** \[${reset}\]\")" # warn about root_ps1_init not being run
PS1+="\[${gray}\]\${STY#*.}" # show stty number or name (screen)
PS1+="\$(load=\$(ps1_loadavg 2>/dev/null) ; if [ \${load%.*} -gt \$((no_processors*4)) ] ; then echo -ne \"\[${redalert}\]HIGH \" ; fi ; if [ \${load%.*} -gt \$((no_processors*2)) ] ; then echo -ne \"\[${redalert}\]LOAD\" ; fi ; if [ \${load%.*} -gt \$((no_processors*1)) ] ; then echo -ne \"\[${orange}\]\" ; fi ; echo -ne \"<\${load%.*}>\")" # display load, warn about high load (load > core count)
PS1+="\[${reset}\]" # reset all colors
PS1+="\$( if [ \$UID -eq 0 ] ; then echo -ne \"\[${red}\]\" ; else echo -ne \"\[${lime}\]\" ; fi )\u" # show username - if root highlight in red (\u = username)
PS1+="\[${gray}\]@\[${violet}\]\h\$([ -r $PS1_HOME/\$PS1_MYNAME/NICKNAME ] && (read nick ; echo -ne \"\[${purple}\]/\[${violet}\]\$nick\") <$PS1_HOME/\$PS1_MYNAME/NICKNAME )" # show hostname and nickname (role) if present (\h = hostname)
PS1+="\[${gray}\](\[${reset}\]\#\[${gray}\]" # show command number in history (\# = number in history)
PS1+="\$(gitmagic echo \"| \" 2>/dev/null)\[\$(gitmagic pre 2>/dev/null)\]\$(gitmagic 2>/dev/null)\[\$(gitmagic post 2>/dev/null)\])" # if this is git repo then add branch and commit hints
PS1+="\[${violet}\]\w\[${gray}\]\\$" # always end path with dollar ($) so we can easily copy it with mouse double click (\w = path relative to home)
PS1+="\[${reset}\]" # reset all colors
PS1+=" " # add space for readability

export PS1

export PS2="\[${gray}\]> \[${reset}\]"

#export PS4="<$LINENO>+ "
export PS4="+ "

ps1_setcol0() {
    # https://unix.stackexchange.com/questions/88296/get-vertical-cursor-position
    exec < /dev/tty
    oldstty=$(stty -g)
    stty raw -echo min 0
    # on my system, the following line can be replaced by the line below it
    echo -en "\033[6n" > /dev/tty
    # tput u7 > /dev/tty    # when TERM=xterm (and relatives)
    IFS=';' read -r -d R -a pos
    stty $oldstty
    # change from one-based to zero based so they work with: tput cup $row $col
    row=$((${pos[0]:2} - 1))    # strip off the esc-[
    col=$((${pos[1]} - 1))

    if [ $col -ne 0 ] ; then
        echo -en "\n(no n/l) "
    fi
}

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
    gitpre="${lime}"
    gitpost="${gray}"

    if [ ! -z "$(__gitdir)" ]; then
        if [ "$1" == "echo" ] ; then
            echo -en $2
        elif [ "$1" == "post" ] ; then
            echo -en "$gitpost"
        else
            gitprompt=$(__git_ps1 "%s")
            if [[ "$gitprompt" =~ "%" ]]; then # there are unadded files
                gitpre="${cyan}"
                gitmsg="add "
            elif [[ "$gitprompt" =~ "*" ]]; then # there are local changes
                gitpre="${orange}"
                gitmsg="commit "
            elif [[ "$gitprompt" =~ "u+" ]]; then # you are ahead of origin
                gitpre="${redalert}"
                gitmsg="push "
            elif [[ "$gitprompt" =~ "u-" ]]; then # you are behind origin
                gitpre="${purple}"
                gitmsg="pull "
            elif [[ "$gitprompt" =~ "\$" ]]; then # there are stashes
                gitpre="${black}"
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

function timer_convertsecs() {
   ((d=${1}/86400))
   ((h=(${1}%86400)/3600))
   ((m=(${1}%3600)/60))
   ((s=${1}%60))
   if [ $d -gt 0 ] ; then
      printf "%dd %dh %dm %ds" $d $h $m $s
   elif [ $h -gt 0 ] ; then
      printf "%dh %dm %ds" $h $m $s
   elif [ $m -gt 0 ] ; then
      printf "%dm %ds" $m $s
   else
      printf "%ds" $s
   fi
}

function timer_show {
  if [ ! -z "$timer_show" ] && [ $timer_show -gt 0 ] ; then
    echo -en "(LAST:$(timer_convertsecs $timer_show)) "
  fi
}

trap 'timer_start' DEBUG

if [ "$PROMPT_COMMAND" == "" ]; then
  PROMPT_COMMAND="timer_stop"
else
  # this must be last command ran before prompt (http://jakemccrary.com/blog/2015/05/03/put-the-last-commands-run-time-in-your-bash-prompt/)
  ORIG_PROMPT_COMMAND=${PROMPT_COMMAND/%; */}
  ORIG_PROMPT_COMMAND=${ORIG_PROMPT_COMMAND/%;/}
  PROMPT_COMMAND="$ORIG_PROMPT_COMMAND ; timer_stop"
fi

# history control
export HISTSIZE=10000
HISTFILESIZE=50000
HISTSIZE=$HISTFILESIZE
HISTIGNORE=reboot*:halt*:shutdown*:pd\ *:rm\ -rf\ /*
HISTCONTROL=ignorespace
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
alias exit-without-history='kill -9 $$'

VIMOPTS="set fenc=utf-8"

if [ ! -z "$PS1_MYNAME" ] && [ "$LOGNAME" != "$PS1_MYNAME" ] ; then
    [ ! -f ~/.bash_history_$PS1_MYNAME ] && [ -f ~/.bash_history ] && cat ~/.bash_history | egrep -v "($(echo "$HISTIGNORE"|sed -e 's/*/.*/g' -e 's/:/|/g'))" > ~/.bash_history_$PS1_MYNAME && echo "History file ~/.bash_history_$PS1_MYNAME initiated, please relogin!" && exit
    HISTFILE=~/.bash_history_$PS1_MYNAME

    [ -f $PS1_HOME/$PS1_MYNAME/.vimrc ] && VIMRC=$PS1_HOME/$PS1_MYNAME/.vimrc
    alias vim="ORIG_LOGNAME=\"$LOGNAME\" LOGNAME=\"$PS1_MYNAME\" MYVIMRC=\"$VIMRC\" vim -u \"$VIMRC\" -c \"$VIMOPTS\""
else
    alias vim="vim -c \"$VIMOPTS\""
fi

