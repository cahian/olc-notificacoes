#!/bin/bash

# Simple Start - OLC Notificações
# Configuração básica e início

set -e

echo "⚙️ Configuração e início"
echo ""

# Configurar .env se não existir
if [ ! -f ".env" ]; then
    echo "📧 Configure suas credenciais:"
    read -p "Email: " EMAIL_USER
    read -s -p "Senha: " EMAIL_PASSWORD
    echo
    read -p "Host IMAP: " EMAIL_HOST
    read -p "WhatsApp grupo: " WHATSAPP_GROUP

    cat > .env << EOF
NODE_ENV=production
PORT=3000

WHATSAPP_GROUP_NAME=$WHATSAPP_GROUP

EMAIL_USER=$EMAIL_USER
EMAIL_PASSWORD=$EMAIL_PASSWORD
EMAIL_HOST=$EMAIL_HOST
EMAIL_PORT=993
EMAIL_TLS=true

TARGET_EMAILS=exemplo@empresa.com.br
TRELLO_BOARD_URL=https://trello.com/b/UWvlgBP4/unimed-de-monte-alto
LOG_LEVEL=info
EOF
    echo "✅ .env criado"
fi

# Iniciar com PM2
echo "🚀 Iniciando aplicação..."
pm2 start src/server.js --name olc-notificacoes --max-memory-restart 400M
pm2 save
pm2 startup

echo "✅ Aplicação rodando!"
echo "📱 Verifique logs: pm2 logs olc-notificacoes"