#!/bin/bash

# Script para configuração segura das credenciais
# Execute este script APÓS o install-server.sh

set -e

echo "🔒 Configuração segura de credenciais - OLC Notificações"
echo ""

# Verificar se está rodando como root ou com sudo
if [[ $EUID -eq 0 ]]; then
   echo "❌ Não execute este script como root por segurança"
   echo "Execute como usuário normal que tenha acesso sudo"
   exit 1
fi

# Ir para diretório da aplicação
cd /opt/olc-notificacoes

echo "📝 Digite as credenciais (serão armazenadas de forma segura):"
echo ""

# Coleta segura de credenciais
read -p "📧 Email do usuário: " EMAIL_USER
read -s -p "🔑 Senha do email: " EMAIL_PASSWORD
echo ""
read -p "🌐 Host do email (ex: imap.gmail.com): " EMAIL_HOST
read -p "🔌 Porta do email (993): " EMAIL_PORT
EMAIL_PORT=${EMAIL_PORT:-993}

read -p "📱 Nome do grupo WhatsApp: " WHATSAPP_GROUP_NAME
WHATSAPP_GROUP_NAME=${WHATSAPP_GROUP_NAME:-"GRUPO DE NOTIFICAÇÕES"}

read -p "📧 Emails para monitorar (separados por vírgula): " TARGET_EMAILS
TARGET_EMAILS=${TARGET_EMAILS:-"atendimento.totvs@totvs.com.br"}

# Criar arquivo .env seguro
echo "💾 Salvando configurações..."
sudo tee /opt/olc-notificacoes/.env > /dev/null << EOF
# Configurações de Produção - OLC Notificações
NODE_ENV=production
PORT=3000

# WhatsApp
WHATSAPP_GROUP_NAME=$WHATSAPP_GROUP_NAME

# Email
EMAIL_USER=$EMAIL_USER
EMAIL_PASSWORD=$EMAIL_PASSWORD
EMAIL_HOST=$EMAIL_HOST
EMAIL_PORT=$EMAIL_PORT
EMAIL_TLS=true

# Emails para monitorar
TARGET_EMAILS=$TARGET_EMAILS

# Trello
TRELLO_BOARD_URL=https://trello.com/b/UWvlgBP4/unimed-de-monte-alto

# Logs
LOG_LEVEL=info
EOF

# Configurar permissões seguras
sudo chown olc-app:olc-app /opt/olc-notificacoes/.env
sudo chmod 600 /opt/olc-notificacoes/.env

echo ""
echo "✅ Credenciais configuradas com segurança!"
echo "🔒 Arquivo .env criado com permissões restritivas (600)"
echo "👤 Proprietário: olc-app"
echo ""
echo "📋 Próximos passos:"
echo "1. sudo -u olc-app pm2 start /opt/olc-notificacoes/ecosystem.config.js"
echo "2. sudo -u olc-app pm2 save"
echo "3. sudo pm2 startup"
echo ""
echo "⚠️ LEMBRE-SE:"
echo "- Configure o webhook do Trello com a URL pública"
echo "- O arquivo .env contém credenciais sensíveis"
echo "- NUNCA commite o arquivo .env no Git"