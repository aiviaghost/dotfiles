source $HOME/.config/fish/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f $HOME/miniconda3/bin/conda
    eval $HOME/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    . "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
end
# <<< conda initialize <<<

# >>> coursier install directory >>>
fish_add_path --append $HOME/.local/share/coursier/bin
# <<< coursier install directory <<<
fish_add_path $HOME/.local/bin

# fish_add_path $HOME/.platformio/penv/bin

# >>> railway initialize >>>
test -f "$HOME/.railway/env.fish"; and source "$HOME/.railway/env.fish"
# <<< railway initialize <<<

fish_add_path $HOME/.wokwi/bin

starship init fish | source
