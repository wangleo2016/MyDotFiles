if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
alias python python3
alias sshdmit1 "ssh -i ~/Documents/vps/DMIT_rsa/id_rsa.pem root@154.3.34.55"
alias sshdmit2 "ssh -i ~/Documents/vps/DMIT_rsa1/id_rsa.pem root@154.12.179.61"
alias sshdmit3 "ssh -i ~/Documents/vps/DMIT_rsa2/id_rsa.pem root@191.223.220.36"
alias sshdmit4 "ssh -i ~/Documents/vps/DMIT_rsa3/id_rsa.pem root@191.223.209.84"


command -qv nvim && alias vim nvim

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# set java PATH
set -g JAVA_HOME /Users/leo/Documents/DevEnvironment/jdk/jdk17.0.4.1
set -gx PATH $JAVA_HOME/bin $PATH

switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
    case '*'
        source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end

# set proxy
if status is-interactive
    proxy_on
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /Users/leo/Documents/DevEnvironment/miniconda3/bin/conda
    eval /Users/leo/Documents/DevEnvironment/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/Users/leo/Documents/DevEnvironment/miniconda3/etc/fish/conf.d/conda.fish"
        . "/Users/leo/Documents/DevEnvironment/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/Users/leo/Documents/DevEnvironment/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

