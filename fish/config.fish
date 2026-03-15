# Homebrew
set -l brew_bin /opt/homebrew/bin/brew

if test -x "$brew_bin"
	eval ($brew_bin shellenv)
end

# Starship
starship init fish | source

# asdf
if test -x "$brew_bin"
	set -l asdf_fish ($brew_bin --prefix)/share/asdf/asdf.fish
	if test -f "$asdf_fish"
		source "$asdf_fish"
	end
end

if test -d "$HOME/.local/bin"
	fish_add_path $HOME/.local/bin
end

# エイリアス
alias g="git"
