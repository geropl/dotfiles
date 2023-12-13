# Activate auto-jump
[[ -s /home/gitpod/.autojump/etc/profile.d/autojump.sh ]] && source /home/gitpod/.autojump/etc/profile.d/autojump.sh

function kl() {
  ~/.dotfiles/kl.sh "$@"
}
