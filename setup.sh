#!/bin/bash
set -ex

echo "Setting up dotfiles... 🔧"


if [[ ! -d "/home/gitpod/.dotfiles" ]]; then
    echo "Cannot find dotfiles directory. Exiting. 🚪"
    exit 0
fi

pushd "/home/gitpod/.dotfiles"

# bash
echo "Setting up bash..."
cat .bash_aliases >> ~/.bash_aliases
cat .bashrc >> ~/.bashrc

# git
echo "Setting up git..."
printf "\n[include]\npath = /home/gitpod/.dotfiles/.gitconfig\n" >> ~/.gitconfig

# linear MCP server
# TODO(gpl): Think about a) referencing a fixed commit hash for the script, and b) a fixed version instead of "latest"
RELEASE=$(curl -s https://api.github.com/repos/geropl/linear-mcp-go/releases/latest)
DOWNLOAD_URL=$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url')
curl -L -o ./linear-mcp-go $DOWNLOAD_URL
chmod +x ./linear-mcp-go

./linear-mcp-go setup --write-access $LINEAR_MCP_WRITE_ACCESS --auto-approve=allow-read-only || true
rm -f ./linear-mcp-go

# git MCP server
curl -sL https://raw.githubusercontent.com/geropl/git-mcp-go/refs/heads/main/scripts/register-cline.sh | bash -s -- $GITPOD_REPO_ROOT $GIT_MCP_WRITE_ACCESS || true

popd


echo "Done setting up dotfiles ✅"
