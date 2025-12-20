# SumiNami - Zoxide integration for Bash
# Smart cd with zoxide fallback

# Initialize zoxide
eval "$(zoxide init bash)"

# Override cd to use zoxide when path doesn't exist
cd() {
    if [ "$#" -eq 1 ] && [ -n "$1" ] && ! [ -d "$1" ]; then
        local dir
        dir=$(zoxide query "$1" 2>/dev/null)
        if [ -n "$dir" ]; then
            builtin cd "$dir"
        else
            builtin cd "$@" 2>/dev/null || echo "cd: no such directory: $1" >&2
        fi
    else
        builtin cd "$@"
    fi
}

# Interactive cd with fzf (optional - use 'cdi' for fuzzy selection)
cdi() {
    local dir
    dir=$(zoxide query -i "$@")
    if [ -n "$dir" ]; then
        builtin cd "$dir"
    fi
}
