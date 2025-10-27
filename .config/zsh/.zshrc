# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added a config file for you to customize HyDE before loading zshrc
# Edit $ZDOTDIR/.user.zsh to customize HyDE before loading zshrc

#  Plugins 
# oh-my-zsh plugins are loaded  in $ZDOTDIR/.user.zsh file, see the file for more information

#  Aliases 
# Override aliases here in '$ZDOTDIR/.zshrc' (already set in .zshenv)

# # Helpful aliases
# alias c='clear'                                                        # clear terminal
# alias l='eza -lh --icons=auto'                                         # long list
# alias ls='eza -1 --icons=auto'                                         # short list
# alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
# alias ld='eza -lhD --icons=auto'                                       # long list dirs
# alias lt='eza --icons=auto --tree'                                     # list folder as tree
# alias un='$aurhelper -Rns'                                             # uninstall package
# alias up='$aurhelper -Syu'                                             # update system/package/aur
# alias pl='$aurhelper -Qs'                                              # list installed package
# alias pa='$aurhelper -Ss'                                              # list available package
# alias pc='$aurhelper -Sc'                                              # remove unused cache
# alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
# alias vc='code'                                                        # gui code editor
# alias fastfetch='fastfetch --logo-type kitty'

# # Directory navigation shortcuts
# alias ..='cd ..'
# alias ...='cd ../..'
# alias .3='cd ../../..'
# alias .4='cd ../../../..'
# alias .5='cd ../../../../..'

# # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
# alias mkdir='mkdir -p'

#  This is your file 
# Add your configurations here
# export EDITOR=nvim
export EDITOR=code

# unset -f command_not_found_handler # Uncomment to prevent searching for commands not found in package manager

# Initialize zoxide
eval "$(zoxide init zsh)"
alias ccd='claude --dangerously-skip-permissions'
alias codedir='code "$PWD"'

. "$HOME/.local/share/../bin/env"

# Terminal Buddy - AI terminal assistant integration
function rose-command() {
    local text="$BUFFER"

    # History search mode (:::)
    if [[ $text == :::* ]]; then
        local filter="${text#:::}"
        filter="${filter# }" # Remove leading space

        # Get history commands
        local history_commands
        if command -v node >/dev/null 2>&1; then
            local rose_history_script="$(dirname "$(readlink -f "$(which rose 2>/dev/null || which tb 2>/dev/null)")")/rose-history.js"

            if [[ -f "$rose_history_script" ]]; then
                if [[ -n "$filter" ]]; then
                    history_commands=$(ROSE_HISTORY_MODE=interactive node "$rose_history_script" "$filter" 2>/dev/null)
                else
                    history_commands=$(ROSE_HISTORY_MODE=interactive node "$rose_history_script" 2>/dev/null)
                fi

                if [[ -n "$history_commands" ]]; then
                    # Use fzf if available, otherwise use numbered list
                    if command -v fzf >/dev/null 2>&1; then
                        local selected=$(echo "$history_commands" | fzf --height=40% --reverse --prompt="Select command: " | cut -f1)
                        if [[ -n "$selected" ]]; then
                            BUFFER="$selected"
                            CURSOR=$#BUFFER
                        else
                            BUFFER=""
                        fi
                    else
                        # Simple numbered selection
                        echo
                        echo "$history_commands" | nl -w2 -s'. '
                        echo
                        echo -n "Select command number (or Enter to cancel): "
                        read selection
                        if [[ "$selection" =~ ^[0-9]+$ ]]; then
                            local selected=$(echo "$history_commands" | sed -n "${selection}p" | cut -f1)
                            if [[ -n "$selected" ]]; then
                                BUFFER="$selected"
                                CURSOR=$#BUFFER
                            else
                                BUFFER=""
                            fi
                        else
                            BUFFER=""
                        fi
                    fi
                else
                    echo "No history found for this directory"
                    BUFFER=""
                fi
            else
                echo "History script not found"
                BUFFER=""
            fi
        else
            echo "Node.js not found"
            BUFFER=""
        fi
        zle reset-prompt
        return
    fi

    # AI command generation mode (::)
    if [[ $text == ::* ]]; then
        text="${text#::}"
        text="${text# }" # Remove leading space

        # Show thinking indicator
        BUFFER="Thinking..."
        CURSOR=$#BUFFER
        zle redisplay

        # Call Rose
        local command=$(rose "$text" 2>&1)

        if [[ -n "$command" ]]; then
            BUFFER="$command"
            CURSOR=$#BUFFER
            zle redisplay
        else
            BUFFER=""
            zle redisplay
        fi
    else
        zle accept-line
    fi
}
zle -N rose-command
bindkey '^M' rose-command  # Bind to Enter key
