#!/usr/bin/env bash
set -e

echo "🔧 Setting up Ona workspace..."

# Allow Git operations in devcontainer
git config --global --add safe.directory /workspaces/*

# Enable AWS CLI autocomplete (bash)
if ! grep -q "aws_completer" ~/.bashrc; then
  echo 'complete -C "$(which aws_completer)" aws' >> ~/.bashrc
fi

# Add aliases
cat << 'EOF' >> ~/.bashrc

# ---- Aliases ----
alias awho="aws sts get-caller-identity"
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"

EOF

echo "✅ Setup complete"

