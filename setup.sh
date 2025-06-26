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

# claude
echo "Setting up git..."
./setup-claude.sh


### linear MCP server
# TODO(gpl): Think about a) referencing a fixed commit hash for the script, and b) a fixed version instead of "latest"
RELEASE="$(curl -s https://api.github.com/repos/geropl/linear-mcp-go/releases/latest)"
DOWNLOAD_URL="$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url')"
curl -L -o ./linear-mcp-go "$DOWNLOAD_URL"
chmod +x ./linear-mcp-go

# Claude Code: Don't specify --project-path to register on user-scope
./linear-mcp-go setup --write-access="${LINEAR_MCP_WRITE_ACCESS:-false}" --auto-approve=allow-read-only --tool=cline,claude-code || true
rm -f ./linear-mcp-go


### git MCP server
RELEASE="$(curl -s https://api.github.com/repos/geropl/git-mcp-go/releases/latest)"
DOWNLOAD_URL="$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')"
curl -L -o ./git-mcp-go $DOWNLOAD_URL
chmod +x ./git-mcp-go

# Setup the mcp server (.gitpod.yml, dotfiles repo, etc.)
./git-mcp-go setup -r $GITPOD_REPO_ROOT --write-access="${GIT_MCP_WRITE_ACCESS:-false}" --auto-approve=allow-local-only || true
rm -f ./git-mcp-go


### GitHub MCP server
RELEASE="$(curl -s https://api.github.com/repos/geropl/github-mcp-go/releases/latest)"
DOWNLOAD_URL="$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux_amd64")) | .browser_download_url')"
curl -L -o ./github-mcp-go $DOWNLOAD_URL
chmod +x ./github-mcp-go

# Setup the mcp server (.gitpod.yml, dotfiles repo, etc.)
# Set FAKE TOKEN to replace it later
export GITHUB_PERSONAL_ACCESS_TOKEN="GITHUB_PERSONAL_ACCESS_TOKEN_REPLACE_ME"
./github-mcp-go setup --write-access="${GITHUB_MCP_WRITE_ACCESS:-false}" --auto-approve=allow-read-only || true
# Cleanup, as both binary and token are persisted in a directory / config file in /home/gitpod
rm -f ./github-mcp-go
unset GITHUB_PERSONAL_ACCESS_TOKEN

# Configure this hook to replace FAKE TOKEN
# Uses "gp credential-helper" once available to retrieve the GitHub token
cat github-mcp-go-token-hook >> ~/.bashrc


### gemini MCP server
RELEASE="$(curl -s https://api.github.com/repos/geropl/gemini-mcp-go/releases/latest)"
DOWNLOAD_URL="$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url')"
curl -L -o ./gemini-mcp-go "$DOWNLOAD_URL"
chmod +x ./gemini-mcp-go

./gemini-mcp-go setup --tool=claude-code || true
rm -f ./gemini-mcp-go


popd


echo "Done setting up dotfiles ✅"
