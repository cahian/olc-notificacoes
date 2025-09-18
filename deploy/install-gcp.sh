#!/bin/bash

# Script de instalação do OLC Notificações para Google Cloud e2-micro
# Autor: Sistema OLC Notificações
# Otimizado para VM e2-micro (1GB RAM) - Free Tier

set -e

echo "🌩️ Iniciando instalação no Google Cloud e2-micro..."

# Verificar recursos disponíveis
echo "🔍 Verificando recursos da VM..."
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
TOTAL_DISK=$(df -h / | awk 'NR==2{print $2}')
echo "✅ RAM total: ${TOTAL_RAM}MB"
echo "✅ Disk total: $TOTAL_DISK"

if [ "$TOTAL_RAM" -lt "800" ]; then
    echo "⚠️ RAM muito baixa ($TOTAL_RAM MB) - aplicando otimizações críticas"
    LOW_MEMORY=true
else
    echo "✅ RAM adequada para e2-micro"
    LOW_MEMORY=false
fi

# Configurar swap PRIMEIRO (crítico para e2-micro)
echo "💾 Configurando swap de 2GB (crítico para e2-micro)..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "✅ Swap configurado"
else
    echo "ℹ️ Swap já existe"
fi

# Otimizar uso de memória do sistema
echo "⚡ Otimizando sistema para baixa memória..."
sudo tee -a /etc/sysctl.conf << EOF

# Otimizações para e2-micro (1GB RAM)
vm.swappiness=60
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.overcommit_memory=1
vm.panic_on_oom=0
EOF

sudo sysctl -p

# Atualizar sistema (com cautela na memória)
echo "📦 Atualizando sistema..."
sudo apt update
# Não fazer upgrade completo para economizar tempo e recursos
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Instalar Node.js 18 LTS (mais leve que 20.x)
echo "🟢 Instalando Node.js 18 LTS (otimizado para e2-micro)..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verificar instalação
echo "✅ Node.js: $(node --version)"
echo "✅ NPM: $(npm --version)"

# Configurar limits do Node.js para baixa memória
echo "🎯 Configurando Node.js para e2-micro..."
echo 'export NODE_OPTIONS="--max-old-space-size=400"' | sudo tee -a /etc/environment
export NODE_OPTIONS="--max-old-space-size=400"

# Instalar PM2 com configuração otimizada
echo "⚡ Instalando PM2..."
sudo npm install -g pm2 --production

# Instalar apenas dependências essenciais
echo "📝 Instalando dependências mínimas..."
sudo apt install -y git curl wget ufw

# Limpar cache do apt para liberar espaço
sudo apt autoremove -y
sudo apt autoclean

# Configurar usuário de aplicação
echo "👤 Configurando usuário de aplicação..."
sudo useradd -r -s /bin/bash -d /opt/olc-notificacoes olc-app 2>/dev/null || true

# Configurar firewall
echo "🔥 Configurando firewall..."
sudo ufw allow ssh
sudo ufw allow 3000/tcp
sudo ufw --force enable

# Criar diretório de aplicação
echo "📁 Criando diretório de aplicação..."
sudo mkdir -p /opt/olc-notificacoes
cd /opt/olc-notificacoes

# Verificar se já foi clonado via Git ou copiar arquivos
echo "📋 Configurando arquivos da aplicação..."
if [ -d ".git" ]; then
    echo "✅ Repositório Git detectado - usando código atual"
elif [ -d ~/olc-notificacoes ]; then
    sudo cp -r ~/olc-notificacoes/* .
    echo "✅ Arquivos copiados do diretório home"
else
    echo "⚠️ Código fonte não encontrado!"
    echo "ℹ️ Opções:"
    echo "1. Clone via Git: git clone https://github.com/SEU-USUARIO/olc-notificacoes.git"
    echo "2. Ou extraia arquivos: tar -xzf olc-notificacoes.tar.gz"
    exit 1
fi

# Instalar dependências com otimizações
echo "📦 Instalando dependências com otimizações..."
export npm_config_cache=/tmp/npm-cache
sudo -E npm install --production --no-optional --prefer-offline

# Limpar cache npm para liberar espaço
sudo npm cache clean --force
sudo rm -rf /tmp/npm-cache

# Criar arquivo .env otimizado para GCP
echo "⚙️ Criando template de configuração GCP..."
sudo tee .env.gcp << EOF
# Google Cloud e2-micro Production
NODE_ENV=production
PORT=3000
CLOUD_PROVIDER=gcp
INSTANCE_TYPE=e2-micro

# Node.js otimizations
NODE_OPTIONS=--max-old-space-size=400

# WhatsApp
WHATSAPP_GROUP_NAME=GRUPO DE NOTIFICAÇÕES OLC

# Email - CONFIGURE SUAS CREDENCIAIS
EMAIL_USER=seu-email@dominio.com
EMAIL_PASSWORD=sua-senha-segura
EMAIL_HOST=imap.dominio.com
EMAIL_PORT=993
EMAIL_TLS=true

# Monitoramento
TARGET_EMAILS=atendimento.totvs@totvs.com.br

# Trello
TRELLO_BOARD_URL=https://trello.com/b/UWvlgBP4/unimed-de-monte-alto

# Logs otimizados (espaço limitado)
LOG_LEVEL=info
LOG_MAX_SIZE=5m
LOG_MAX_FILES=3
EOF

# Configurar PM2 otimizado para e2-micro
echo "🔧 Configurando PM2 para e2-micro..."
sudo tee ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'olc-notificacoes',
    script: './src/server.js',
    cwd: '/opt/olc-notificacoes',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '400M',
    env_file: '/opt/olc-notificacoes/.env',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    error_file: '/var/log/olc-notificacoes/error.log',
    out_file: '/var/log/olc-notificacoes/out.log',
    log_file: '/var/log/olc-notificacoes/combined.log',
    merge_logs: true,
    max_restarts: 5,
    min_uptime: '10s',
    kill_timeout: 3000,
    // Crítico para e2-micro: limitar memória
    node_args: '--max-old-space-size=400'
  }]
};
EOF

# Criar diretório de logs otimizado
echo "📄 Configurando logs otimizados..."
sudo mkdir -p /var/log/olc-notificacoes
sudo chown olc-app:olc-app /var/log/olc-notificacoes

# Configurar logrotate agressivo (espaço limitado)
sudo tee /etc/logrotate.d/olc-notificacoes << EOF
/var/log/olc-notificacoes/*.log {
    hourly
    rotate 24
    compress
    delaycompress
    missingok
    notifempty
    create 644 olc-app olc-app
    copytruncate
    maxsize 10M
}
EOF

# Configurar permissões
echo "🔐 Configurando permissões..."
sudo chown -R olc-app:olc-app /opt/olc-notificacoes
sudo chmod 600 /opt/olc-notificacoes/.env.gcp

# Script de monitoramento específico para e2-micro
echo "📊 Criando monitoramento para e2-micro..."
sudo tee /usr/local/bin/gcp-monitor << 'EOF'
#!/bin/bash
echo "=== OLC Notificações - Google Cloud e2-micro ==="
echo "Data: $(date)"
echo ""
echo "=== Recursos (crítico para e2-micro) ==="
echo "CPU: $(cat /proc/loadavg)"
echo "RAM: $(free -h | grep Mem)"
echo "Swap: $(free -h | grep Swap)"
echo "Disk: $(df -h / | tail -1)"
echo ""
echo "=== PM2 Status ==="
sudo -u olc-app pm2 status
echo ""
echo "=== Processo Node.js ==="
ps aux | grep node | grep -v grep | awk '{print "PID: "$2" CPU: "$3"% RAM: "$4"% MEM: "$6"KB"}'
echo ""
echo "=== Últimos logs ==="
sudo -u olc-app pm2 logs olc-notificacoes --lines 3 --nostream
EOF

sudo chmod +x /usr/local/bin/gcp-monitor

# Script de limpeza de emergência
sudo tee /usr/local/bin/emergency-cleanup << 'EOF'
#!/bin/bash
echo "🚨 Limpeza de emergência para e2-micro..."
sudo apt autoclean
sudo npm cache clean --force 2>/dev/null || true
sudo journalctl --vacuum-time=1d
sudo find /var/log -name "*.log" -type f -size +10M -delete
sudo sync && sudo sysctl vm.drop_caches=3
echo "✅ Limpeza concluída"
EOF

sudo chmod +x /usr/local/bin/emergency-cleanup

echo "✅ Instalação Google Cloud e2-micro concluída!"
echo ""
echo "🌩️ GOOGLE CLOUD ESPECÍFICO:"
echo "- VM e2-micro (1GB RAM) detectada"
echo "- Swap de 2GB configurado (crítico)"
echo "- Node.js limitado a 400MB"
echo "- PM2 com restart automático em 400MB"
echo "- Logs com rotação agressiva"
echo ""
echo "🔒 CONFIGURAÇÃO NECESSÁRIA:"
echo "1. Configure credenciais: /opt/olc-notificacoes/.env.gcp"
echo "2. Copie para .env: sudo cp .env.gcp .env"
echo "3. Configure regra de firewall no Console GCP:"
echo "   VPC network > Firewall > Create Firewall Rule"
echo "   Name: allow-olc-app, Target tags: olc-app, Port: 3000"
echo "4. Adicione tag 'olc-app' à VM no console"
echo ""
echo "📋 Para iniciar:"
echo "1. sudo -u olc-app pm2 start /opt/olc-notificacoes/ecosystem.config.js"
echo "2. sudo -u olc-app pm2 save"
echo "3. sudo env PATH=\$PATH:/usr/bin pm2 startup systemd -u olc-app --hp /home/olc-app"
echo ""
echo "📊 Monitoramento e2-micro:"
echo "- gcp-monitor (recursos críticos)"
echo "- emergency-cleanup (se ficar sem memória)"
echo "- pm2 monit"
echo ""
echo "🌐 IP externo: $(curl -s ifconfig.me || echo 'Execute: curl ifconfig.me')"
echo "🪝 Webhook URL: http://\$(curl -s ifconfig.me):3000/trello-webhook"
echo ""
echo "⚠️ CRÍTICO: Com 1GB RAM, monitore sempre o uso de memória!"