if command -v claude &> /dev/null; then
    echo "✨ Claude Code is already installed"
else
    echo "⚠️  Skipping claude code setup, binary not found"
    return 0
    # if ! command -v npm &> /dev/null; then
    #     echo "⚠️  Skipping claude code install, npm not found"
    #     return 0
    # else
    #     echo "🚀 Installing Claude Code..."
    #     npm install -g @anthropic-ai/claude-code
    # fi
fi

DEST="$HOME/.claude.json"
if [ ! -f "$DEST" ]; then
    echo "📋 Copying personal Claude Code config from '/root/custom-claude.json'..."
    sudo cp "$HOME/custom-claude.json" "$DEST" || {
        echo "ℹ️  No personal Claude Code config found at '/root/custom-claude.json', skipping copy"
        return 0
    }
fi

sudo chown "$(id -u):$(id -g)" "$DEST"

echo "⚙️  Setting up Claude settings..."
mkdir -p ~/.claude
if [ ! -f ~/.claude/settings.json ]; then
    cat > ~/.claude/settings.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Edit(**)",
      "Bash(ls:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "Bash(find:*)",
      "Bash(go:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git pull:*)",
      "Bash(git log:*)",
      "Bash(npm test:*)",
      "Bash(npm run test:*)",
      "Bash(npm run vitest:*)",
      "Bash(npx vitest:*)",
      "Bash(yarn test:*)",
      "Bash(yarn lint:*)",
      "Bash(yarn tsc:*)",
      "WebFetch(domain:www.gitpod.io)",
      "WebFetch(domain:docs.gitpod.io)"
    ],
    "deny": []
  }
}
EOF
    echo "✅ Created ~/.claude/settings.json"
else
    echo "ℹ️  ~/.claude/settings.json already exists, skipping creation"
fi
