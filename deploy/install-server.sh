#!/bin/bash

# Script de instalação do OLC Notificações para servidor Ubuntu/Azure
# Autor: Sistema OLC Notificações

set -e

echo "🚀 Iniciando instalação do OLC Notificações..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 20.x
echo "🟢 Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar PM2 globalmente
echo "⚡ Instalando PM2..."
sudo npm install -g pm2

# Instalar Git se não estiver instalado
echo "📝 Instalando dependências do sistema..."
sudo apt install -y git curl wget unzip

# Criar usuário de aplicação
echo "👤 Configurando usuário de aplicação..."
sudo useradd -r -s /bin/bash -d /opt/olc-notificacoes olc-app || true

# Criar diretório de aplicação
echo "📁 Criando diretório de aplicação..."
sudo mkdir -p /opt/olc-notificacoes
cd /opt/olc-notificacoes

# Copiar arquivos da aplicação (assumindo que já estão no servidor)
echo "📋 Copiando arquivos da aplicação..."
sudo cp -r ~/olc-notificacoes/* . 2>/dev/null || echo "⚠️ Arquivos não encontrados, faça upload manualmente"

# Instalar dependências
echo "📦 Instalando dependências..."
sudo npm install --production

# Criar arquivo .env vazio com template
echo "⚙️ Criando template de configuração..."
sudo tee .env.production << EOF
# Configurações de Produção - OLC Notificações
NODE_ENV=production
PORT=3000

# WhatsApp
WHATSAPP_GROUP_NAME=GRUPO DE NOTIFICAÇÕES

# Email - CONFIGURE SUAS CREDENCIAIS REAIS
EMAIL_USER=seu-email@dominio.com
EMAIL_PASSWORD=sua-senha-segura
EMAIL_HOST=imap.dominio.com
EMAIL_PORT=993
EMAIL_TLS=true

# Emails para monitorar
TARGET_EMAILS=exemplo@empresa.com.br

# Trello
TRELLO_BOARD_URL=https://trello.com/b/UWvlgBP4/unimed-de-monte-alto

# Logs
LOG_LEVEL=info
EOF

# Configurar PM2
echo "🔧 Configurando PM2..."
sudo tee ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'olc-notificacoes',
    script: './src/server.js',
    cwd: '/opt/olc-notificacoes',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env_file: '/opt/olc-notificacoes/.env',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    error_file: '/var/log/olc-notificacoes/error.log',
    out_file: '/var/log/olc-notificacoes/out.log',
    log_file: '/var/log/olc-notificacoes/combined.log'
  }]
};
EOF

# Criar diretório de logs
echo "📄 Configurando logs..."
sudo mkdir -p /var/log/olc-notificacoes
sudo chown olc-app:olc-app /var/log/olc-notificacoes

# Configurar permissões
sudo chown -R olc-app:olc-app /opt/olc-notificacoes
sudo chmod 600 /opt/olc-notificacoes/.env.production

# Configurar firewall
echo "🔥 Configurando firewall..."
sudo ufw allow 3000/tcp
sudo ufw allow ssh
sudo ufw --force enable

echo "✅ Instalação concluída!"
echo ""
echo "🔒 IMPORTANTE - SEGURANÇA:"
echo "1. Configure as credenciais reais em: /opt/olc-notificacoes/.env.production"
echo "2. Copie o arquivo para .env: sudo cp .env.production .env"
echo "3. As credenciais NÃO devem ser commitadas no Git"
echo ""
echo "📋 Para iniciar:"
echo "1. sudo -u olc-app pm2 start /opt/olc-notificacoes/ecosystem.config.js"
echo "2. sudo -u olc-app pm2 save"
echo "3. sudo pm2 startup"
echo ""
echo "📊 Monitoramento:"
echo "- pm2 logs olc-notificacoes"
echo "- pm2 status"
echo "- pm2 monit"