#!/usr/bin/env bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_SUFFIX="_backup"

declare -Ar config_files=(
    ["bash_profile"]=~/.bash_profile
    ["bashrc"]=~/.bashrc
    ["gdbinit"]=~/.gdbinit
    ["gitconfig"]=~/.gitconfig
    ["rc.lua"]=~/.config/awesome/rc.lua
    ["tmux.conf"]=~/.tmux.conf
    ["vimrc"]=~/.vim/vimrc
    ["Xresources"]=~/.Xresources
    ["alacritty.toml"]=~/.config/alacritty/alacritty.toml )

confirm() {
    echo "$@ (Y/n)"
    read -sn 1 choice
    [[ "$choice" != "n" && "$choice" != "N" ]]
}

_copy()
{
    confirm "Copy '$1' to '$2'?" && cp -v -b --suffix="${BACKUP_SUFFIX}" "${THISDIR}/$1" "$2"
}

clone_or_update() {
    local plugindir=$(basename "$1" .git)
    [[ -d "$plugindir" ]] && git -C "$plugindir" pull || git clone "$1"
}

deploy_vim_plugins() {
    local vimplugindir="$HOME/.vim/pack/plugins/start"
    local plugins=(
        "https://github.com/dense-analysis/ale"
        "https://github.com/preservim/nerdtree"
        "https://github.com/ervandew/supertab"
        "https://github.com/preservim/tagbar"
        "https://github.com/tomtom/tlib_vim"
        "https://github.com/tpope/vim-fugitive"
        "https://github.com/MarcWeber/vim-addon-mw-utils"
        "https://github.com/vim-airline/vim-airline"
        "https://github.com/garbas/vim-snipmate"
        "https://github.com/honza/vim-snippets"
    )
    local colorsdir="$HOME/.vim/pack/colors/opt"
    local colorscheme="https://github.com/joshdick/onedark.vim.git"

    mkdir -p "$vimplugindir"

    pushd "$vimplugindir"
    for plugin in ${plugins[*]}
    do
        clone_or_update "$plugin"
    done
    popd

    mkdir -p "$colorsdir"
    pushd "$colorsdir"
    clone_or_update "$colorscheme"
    popd
}

deploy_alacritty() {
    local alacrittydir="$HOME/.config/alacritty/"

    mkdir -p "$alacrittydir"
    pushd "$alacrittydir"
    clone_or_update "https://github.com/alacritty/alacritty-theme.git"
    popd
}

make_directories() {
    mkdir -p ~/.vim/swap
    mkdir -p ~/.config/awesome
    mkdir -p ~/.config/alacritty
}

file_status() {
    if [ ! -e "$2" ]; then
        echo "$1:"
    else
        cmp -s "$1" "$2" && echo -e "\033[32;1m$1\033[0m:" || echo -e "\033[31;1m$1\033[0m:"
    fi
}

show_diff() {
    if [ -e "$2" ]; then
        diff -u --color "$1" "$2"
    fi
}

case "$1" in
    "run")
        make_directories

        for f in ${!config_files[@]}
        do
            _copy "$f" "${config_files[$f]}"
        done

        confirm "Clone Vim plugins?" && deploy_vim_plugins
        confirm "Clone Alacritty themes?" && deploy_alacritty
        ;;

    "diff")
        for f in ${!config_files[@]}
        do
            show_diff "$f" "${config_files[$f]}"
        done
        ;;

    *)
        for f in ${!config_files[@]}
        do
            file_status "$f" "${config_files[$f]}"
        done

        echo -e "\nUsage:"
        echo    "  $0 <run> - copy files in place"
        ;;
esac
