#!/bin/bash

# AWS Quick Start - OLC Notificações
# Deploy rápido e otimizado para EC2 t2.micro (1GB RAM)

set -e

echo "☁️ AWS Quick Start - OLC Notificações"
echo "======================================"
echo ""

# Verificar se estamos na AWS
echo "🔍 Verificando ambiente..."
if curl -s --max-time 3 http://169.254.169.254/latest/meta-data/instance-type | grep -q "t2.micro"; then
    echo "✅ AWS EC2 t2.micro detectado"
    AWS_INSTANCE=true
    INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
    AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "📍 Instance: $INSTANCE_TYPE na $AVAILABILITY_ZONE"
else
    echo "⚠️ Pode não ser uma instância t2.micro AWS"
    AWS_INSTANCE=false
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
        echo "2. Upload via SCP:"
        echo "   scp -i chave.pem olc-notificacoes.tar.gz ubuntu@IP_AWS:~/"
        echo "   tar -xzf olc-notificacoes.tar.gz && cd olc-notificacoes"
        echo ""
        exit 1
    fi

    echo "🚀 Instalação completa para t2.micro..."
    ./deploy/install-aws.sh

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
# AWS t2.micro Production - RAM LIMITADA
NODE_ENV=production
PORT=3000
CLOUD_PROVIDER=aws
INSTANCE_TYPE=t2.micro

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

# Verificar networking AWS
echo ""
echo "🌐 Verificando conectividade..."

# Pegar informações da instância AWS
if [ "$AWS_INSTANCE" = true ]; then
    EXTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    echo "🌍 Região AWS: $REGION"
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
echo "📊 STATUS RECURSOS t2.micro:"
echo "============================"
FREE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
USED_RAM=$(free -m | awk 'NR==2{printf "%.0f", $3}')
echo "RAM livre: ${FREE_RAM}MB | Usada: ${USED_RAM}MB"

if [ "$FREE_RAM" -lt "100" ]; then
    echo "🚨 RAM CRÍTICA! Execute: emergency-cleanup"
fi

# Verificar Security Groups AWS
echo ""
echo "🔥 SECURITY GROUPS AWS:"
echo "======================="
echo "⚠️ CONFIGURE NO CONSOLE AWS:"
echo "1. EC2 > Security Groups"
echo "2. Selecione o Security Group da instância"
echo "3. Adicione regras de entrada:"
echo "   - SSH (22): 0.0.0.0/0"
echo "   - Custom TCP (3000): 0.0.0.0/0"
echo "   - HTTP (80): 0.0.0.0/0"
echo "   - HTTPS (443): 0.0.0.0/0"

# Webhook automático
echo ""
echo "🪝 WEBHOOK TRELLO:"
echo "=================="
echo "Execute com suas credenciais:"
echo ""
echo "curl -X POST \"https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"description\": \"OLC AWS t2.micro\","
echo "    \"callbackURL\": \"http://$EXTERNAL_IP:3000/trello-webhook\","
echo "    \"idModel\": \"SEU_BOARD_ID_TRELLO\""
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
echo "📊 MONITORAMENTO t2.micro:"
echo "=========================="
echo "- aws-monitor (status completo)"
echo "- emergency-cleanup (se RAM crítica)"
echo "- pm2 monit"
echo "- free -h (RAM)"
echo "- df -h (disco)"

echo ""
echo "🎉 AWS DEPLOY CONCLUÍDO!"
echo "========================"
echo ""
echo "✅ Sistema otimizado para t2.micro"
echo "✅ Swap 2GB configurado"
echo "✅ Node.js limitado (400MB)"
echo "✅ PM2 com auto-restart"
echo "✅ Logs mínimos"
echo ""
echo "🚨 PRÓXIMOS PASSOS CRÍTICOS:"
echo "1. Configure Security Groups no Console AWS"
echo "2. Registre webhook Trello"
echo "3. Conecte WhatsApp"
echo "4. MONITORE RAM constantemente!"
echo ""
echo "💰 Custo: Grátis primeiro ano (AWS Free Tier)"
echo "⏱️ 750 horas/mês gratuitas t2.micro"
echo ""
echo "🆘 Se travar: emergency-cleanup"