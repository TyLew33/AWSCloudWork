#!/usr/bin/env bash
set -e

echo "🔧 Setting up Ona workspace..."

git config --global --add safe.directory /workspaces/*

cat << 'EOF' >> ~/.bashrc

alias awho="aws sts get-caller-identity"
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"

EOF

echo "✅ Setup complete"
