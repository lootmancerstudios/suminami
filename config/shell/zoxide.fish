# SumiNami - Zoxide integration for Fish
# Smart cd with zoxide fallback

# Initialize zoxide
zoxide init fish | source

# Override cd to use zoxide when path doesn't exist
function cd --wraps=cd
    if test (count $argv) -eq 1; and test -n "$argv[1]"; and not test -d "$argv[1]"
        set -l dir (zoxide query $argv[1] 2>/dev/null)
        if test -n "$dir"
            builtin cd $dir
        else
            builtin cd $argv 2>/dev/null; or echo "cd: no such directory: $argv[1]" >&2
        end
    else
        builtin cd $argv
    end
end

# Interactive cd with fzf (optional - use 'cdi' for fuzzy selection)
function cdi
    set -l dir (zoxide query -i $argv)
    if test -n "$dir"
        builtin cd $dir
    end
end
