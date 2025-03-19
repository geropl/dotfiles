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

### linear MCP server
# TODO(gpl): Think about a) referencing a fixed commit hash for the script, and b) a fixed version instead of "latest"
RELEASE="$(curl -s https://api.github.com/repos/geropl/linear-mcp-go/releases/latest)"
DOWNLOAD_URL="$(echo $RELEASE | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url')"
curl -L -o ./linear-mcp-go "$DOWNLOAD_URL"
chmod +x ./linear-mcp-go

./linear-mcp-go setup --write-access="${LINEAR_MCP_WRITE_ACCESS:-false}" --auto-approve=allow-read-only || true
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
# Use "gp credential-helper" once available to retrieve the GitHub token
cat << EOF >> ~/.bashrc

### BLOCK START - github-mcp-go credential hook
# "gp credential-helper" hook

# Search for all files under ~/.vscode-server/data/User/globalStorage/ for GITHUB_PERSONAL_ACCESS_TOKEN_REPLACE_ME
# If there are findings, iterate all files and replace the token
FINDINGS=$(grep -nrl "GITHUB_PERSONAL_ACCESS_TOKEN_REPLACE_ME" ~/.vscode-server/data/User/globalStorage 2>/dev/null)
if [ -n "$FINDINGS" ]; then
    # store state of pipefail so we can restore later
    set -o | grep pipefail | grep on
    PIPEFAIL_ON=$?
    
    set -o pipefail # we need this on
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(printf '%s\n' host=github.com | gp credential-helper get | sort | head -2 | tail -1 | sed 's;password=;;')"
    if [ "$?" -eq 0 ]; then
        while IFS= read -r FILE; do
            sed -i 's/GITHUB_PERSONAL_ACCESS_TOKEN_REPLACE_ME/'"$GITHUB_PERSONAL_ACCESS_TOKEN"'/g' "$FILE"
        done <<< "$FINDINGS"

        unset GITHUB_PERSONAL_ACCESS_TOKEN
    else
        echo "GitHub MCP server: Failed to get GITHUB_PERSONAL_ACCESS_TOKEN from gp credential-helper"
    fi


    # if pipefail was off, disable it
    if [ "$PIPEFAIL_ON" -ne 0 ]; then
        set +o pipefail
    fi
fi
### BLOCK END - github-mcp-go credential hook

EOF

popd


echo "Done setting up dotfiles ✅"
