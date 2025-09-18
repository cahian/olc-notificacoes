#!/bin/bash

# Simple Deploy - OLC Notificações
# Git pull e restart

set -e

echo "🔄 Deploy via Git"
echo ""

# Backup .env
cp .env .env.backup

# Pull atualizações
git pull origin main

# Instalar deps se package.json mudou
if git diff HEAD~1 --name-only | grep -q "package.json"; then
    echo "📦 Atualizando dependências..."
    npm install
fi

# Restaurar .env
cp .env.backup .env

# Restart
echo "🔄 Reiniciando..."
pm2 restart olc-notificacoes

echo "✅ Deploy concluído!"