#!/bin/bash

# Google Cloud Quick Start - OLC Notificações
# Deploy rápido e otimizado para e2-micro (1GB RAM)

set -e

echo "🌩️ Google Cloud Quick Start - OLC Notificações"
echo "=============================================="
echo ""

# Verificar se estamos no GCP
echo "🔍 Verificando ambiente..."
if curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/machine-type | grep -q "e2-micro"; then
    echo "✅ Google Cloud e2-micro detectado"
    GCP_INSTANCE=true
else
    echo "⚠️ Pode não ser uma instância e2-micro do GCP"
    GCP_INSTANCE=false
fi

# Verificar recursos críticos
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
echo "🧠 RAM disponível: ${TOTAL_RAM}MB"

if [ "$TOTAL_RAM" -lt "900" ]; then
    echo "🚨 ATENÇÃO: RAM muito baixa! Aplicando otimizações críticas..."
    CRITICAL_MODE=true
else
    CRITICAL_MODE=false
fi

# Verificar se é primeira instalação
if [ ! -f "/opt/olc-notificacoes/src/server.js" ]; then
    echo ""
    echo "📋 PRIMEIRA INSTALAÇÃO"
    echo "====================="
    echo ""

    # Verificar código fonte
    if [ ! -f "./src/server.js" ] && [ ! -d "~/olc-notificacoes" ]; then
        echo "❌ ERRO: Código fonte não encontrado!"
        echo ""
        echo "📥 OPÇÕES DE DEPLOY:"
        echo "1. Git (Recomendado):"
        echo "   git clone https://github.com/SEU-USUARIO/olc-notificacoes.git"
        echo "   cd olc-notificacoes"
        echo ""
        echo "2. Upload manual:"
        echo "   gcloud compute scp olc-notificacoes.tar.gz INSTANCE:~/"
        echo "   tar -xzf olc-notificacoes.tar.gz && cd olc-notificacoes"
        echo ""
        exit 1
    fi

    echo "🚀 Instalação completa para e2-micro..."
    ./deploy/install-gcp.sh

    echo ""
    echo "⚙️ CONFIGURAÇÃO INTERATIVA"
    echo "=========================="
    echo ""

    # Configurar credenciais
    echo "📧 Configure email (seja rápido, RAM limitada):"
    read -p "Email: " EMAIL_USER
    read -s -p "Senha: " EMAIL_PASSWORD
    echo
    read -p "Host IMAP: " EMAIL_HOST
    read -p "Porta: " EMAIL_PORT

    echo "📝 Outros parâmetros:"
    read -p "Grupo WhatsApp: " WHATSAPP_GROUP
    read -p "Emails para monitorar: " TARGET_EMAILS

    # Criar .env otimizado
    sudo tee /opt/olc-notificacoes/.env << EOF
# GCP e2-micro Production - RAM LIMITADA
NODE_ENV=production
PORT=3000
CLOUD_PROVIDER=gcp
INSTANCE_TYPE=e2-micro

# Otimizações críticas
NODE_OPTIONS=--max-old-space-size=400
MAX_MEMORY=400M

# WhatsApp
WHATSAPP_GROUP_NAME=$WHATSAPP_GROUP

# Email
EMAIL_USER=$EMAIL_USER
EMAIL_PASSWORD=$EMAIL_PASSWORD
EMAIL_HOST=$EMAIL_HOST
EMAIL_PORT=$EMAIL_PORT
EMAIL_TLS=true

# Monitoramento
TARGET_EMAILS=$TARGET_EMAILS

# Trello
TRELLO_BOARD_URL=https://trello.com/b/UWvlgBP4/unimed-de-monte-alto

# Logs mínimos (espaço limitado)
LOG_LEVEL=error
LOG_MAX_SIZE=5m
LOG_MAX_FILES=2
EOF

    sudo chown olc-app:olc-app /opt/olc-notificacoes/.env
    sudo chmod 600 /opt/olc-notificacoes/.env

    echo "✅ Configuração salva!"

else
    echo "🔄 INSTALAÇÃO EXISTENTE"
    echo "======================"
    echo "Verificando status..."
fi

# Limpeza preventiva se RAM crítica
if [ "$CRITICAL_MODE" = true ]; then
    echo ""
    echo "🧹 Modo crítico: limpando memória..."
    sudo sync && sudo sysctl vm.drop_caches=3
    sudo systemctl restart systemd-journald
fi

# Verificar e iniciar PM2
echo ""
echo "📊 Gerenciando serviço..."

if sudo -u olc-app pm2 status olc-notificacoes > /dev/null 2>&1; then
    echo "🔄 Serviço rodando, reiniciando..."
    sudo -u olc-app pm2 restart olc-notificacoes
else
    echo "🚀 Iniciando serviço..."
    cd /opt/olc-notificacoes

    # Verificar recursos antes de iniciar
    if [ "$CRITICAL_MODE" = true ]; then
        echo "⚠️ Modo crítico: aguardando recursos..."
        sleep 5
    fi

    sudo -u olc-app pm2 start ecosystem.config.js
    sudo -u olc-app pm2 save

    # Configurar auto-start
    if ! systemctl is-enabled pm2-olc-app > /dev/null 2>&1; then
        echo "⚡ Configurando auto-start..."
        sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u olc-app --hp /home/olc-app
    fi
fi

# Verificar GCP networking
echo ""
echo "🌐 Verificando conectividade..."

# Pegar IP externo via metadata GCP
if [ "$GCP_INSTANCE" = true ]; then
    EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    ZONE=$(curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/zone | cut -d/ -f4)
    echo "📍 Zona GCP: $ZONE"
else
    EXTERNAL_IP=$(curl -s ifconfig.me || echo "N/A")
fi

echo "🌍 IP Externo: $EXTERNAL_IP"

if [ "$EXTERNAL_IP" != "N/A" ]; then
    echo "🔗 App URL: http://$EXTERNAL_IP:3000"
    echo "🪝 Webhook: http://$EXTERNAL_IP:3000/trello-webhook"
fi

# Teste básico com timeout (RAM limitada)
echo ""
echo "🧪 Teste rápido..."
sleep 3

if timeout 10 curl -s localhost:3000 > /dev/null; then
    echo "✅ App respondendo"
else
    echo "❌ App não responde - verificando..."

    # Diagnóstico rápido
    echo "🔍 Diagnóstico:"
    echo "RAM: $(free -h | grep Mem)"
    echo "PM2: $(sudo -u olc-app pm2 status olc-notificacoes --no-ansi | tail -1)"

    # Logs mínimos
    echo "📝 Últimos logs:"
    sudo -u olc-app pm2 logs olc-notificacoes --lines 3 --nostream
fi

# Status crítico de recursos
echo ""
echo "📊 STATUS RECURSOS e2-micro:"
echo "============================"
FREE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
USED_RAM=$(free -m | awk 'NR==2{printf "%.0f", $3}')
echo "RAM livre: ${FREE_RAM}MB | Usada: ${USED_RAM}MB"

if [ "$FREE_RAM" -lt "100" ]; then
    echo "🚨 RAM CRÍTICA! Execute: emergency-cleanup"
fi

# Verificar firewall GCP
echo ""
echo "🔥 FIREWALL GCP:"
echo "==============="
echo "⚠️ CONFIGURE NO CONSOLE GCP:"
echo "1. VPC network > Firewall"
echo "2. Create Firewall Rule:"
echo "   Name: allow-olc-app"
echo "   Target tags: olc-app"
echo "   Source IP: 0.0.0.0/0"
echo "   Port: 3000"
echo "3. Compute Engine > VM > Edit"
echo "   Network tags: olc-app"

# Webhook automático
echo ""
echo "🪝 WEBHOOK TRELLO:"
echo "=================="
echo "Execute com suas credenciais:"
echo ""
echo "curl -X POST \"https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"description\": \"OLC GCP e2-micro\","
echo "    \"callbackURL\": \"http://$EXTERNAL_IP:3000/trello-webhook\","
echo "    \"idModel\": \"6663185e7551188483173907\""
echo "  }'"

# WhatsApp setup
echo ""
echo "📱 WHATSAPP:"
echo "============"
echo "1. pm2 logs olc-notificacoes"
echo "2. Procure QR Code"
echo "3. Escaneie com WhatsApp"

# Comandos de monitoramento
echo ""
echo "📊 MONITORAMENTO e2-micro:"
echo "========================="
echo "- gcp-monitor (status completo)"
echo "- emergency-cleanup (se RAM crítica)"
echo "- pm2 monit"
echo "- free -h (RAM)"
echo "- df -h (disco)"

echo ""
echo "🎉 GOOGLE CLOUD DEPLOY CONCLUÍDO!"
echo "================================="
echo ""
echo "✅ Sistema otimizado para e2-micro"
echo "✅ Swap 2GB configurado"
echo "✅ Node.js limitado (400MB)"
echo "✅ PM2 com auto-restart"
echo "✅ Logs mínimos"
echo ""
echo "🚨 PRÓXIMOS PASSOS CRÍTICOS:"
echo "1. Configure firewall no Console GCP"
echo "2. Adicione network tag 'olc-app'"
echo "3. Registre webhook Trello"
echo "4. Conecte WhatsApp"
echo "5. MONITORE RAM constantemente!"
echo ""
echo "💰 Custo: R$ 0,00 (GCP Free Tier)"
echo "⏱️ Validade: Permanente"
echo ""
echo "🆘 Se travar: emergency-cleanup"