#!/bin/bash

# Script para corrigir erro do WhatsApp Web (Chromium dependencies)
# Execute se estiver recebendo erro: "libatk-1.0.so.0: cannot open shared object file"

set -e

echo "🔧 Corrigindo dependências do WhatsApp Web..."
echo ""

# Parar aplicação primeiro
echo "⏸️ Parando aplicação..."
sudo -u olc-app pm2 stop olc-notificacoes || echo "Aplicação já estava parada"

# Atualizar sistema
echo "📦 Atualizando lista de pacotes..."
sudo apt update

# Instalar dependências críticas do Chromium
echo "🔧 Instalando dependências do Chromium para WhatsApp..."
sudo apt install -y \
    libnss3 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libdrm2 \
    libxss1 \
    libgconf-2-4 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libcairo-gobject2 \
    libcairo2 \
    libgcc-s1 \
    libglib2.0-0 \
    libpango-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    ca-certificates \
    fonts-liberation \
    libappindicator1 \
    libgbm1 \
    libnspr4 \
    lsb-release \
    xdg-utils

# Limpar sessão WhatsApp anterior (pode estar corrompida)
echo "🧹 Limpando sessão WhatsApp anterior..."
cd /opt/olc-notificacoes
sudo rm -rf .wwebjs_auth .wwebjs_cache 2>/dev/null || true

# Limpar cache do npm e reinstalar whatsapp-web.js
echo "🔄 Reinstalando WhatsApp Web.js..."
sudo npm cache clean --force
sudo npm uninstall whatsapp-web.js
sudo npm install whatsapp-web.js --save

# Verificar se as bibliotecas estão disponíveis
echo "✅ Verificando dependências..."
if ldconfig -p | grep -q "libatk-1.0.so.0"; then
    echo "✅ libatk-1.0.so.0 encontrada"
else
    echo "❌ libatk-1.0.so.0 ainda não encontrada, tentando instalar libatk1.0-dev..."
    sudo apt install -y libatk1.0-dev
fi

# Reconfigurar permissões
sudo chown -R olc-app:olc-app /opt/olc-notificacoes

# Reiniciar aplicação
echo "▶️ Reiniciando aplicação..."
sudo -u olc-app pm2 restart olc-notificacoes

# Aguardar inicialização
echo "⏳ Aguardando inicialização (30s)..."
sleep 30

# Verificar status
echo "📊 Verificando status..."
sudo -u olc-app pm2 status olc-notificacoes

echo ""
echo "🔍 Verificando logs recentes..."
sudo -u olc-app pm2 logs olc-notificacoes --lines 10 --nostream

echo ""
echo "✅ Correção aplicada!"
echo ""
echo "📱 PRÓXIMOS PASSOS:"
echo "1. Monitore os logs: pm2 logs olc-notificacoes"
echo "2. Procure pelo QR Code nos logs"
echo "3. Escaneie com WhatsApp para conectar"
echo ""
echo "🚨 Se ainda der erro:"
echo "1. Verifique se há mais logs de erro"
echo "2. Tente reiniciar a instância EC2"
echo "3. Execute: sudo reboot"