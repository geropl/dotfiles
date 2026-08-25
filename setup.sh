#!/bin/bash
set -ex

echo "Setting up dotfiles... 🔧"

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Cannot find dotfiles directory. Exiting. 🚪"
    exit 0
fi

pushd "$DOTFILES_DIR"

# bash
echo "Setting up bash..."
cat .bash_aliases >> ~/.bash_aliases
cat .bashrc >> ~/.bashrc

# git
echo "Setting up git..."
printf "\n[include]\npath = $DOTFILES_DIR/.gitconfig\n" >> ~/.gitconfig

popd


echo "Done setting up dotfiles ✅"
