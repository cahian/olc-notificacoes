#!/bin/bash

# Simple Install - OLC Notificações
# Instalação mínima para AWS EC2 t2.micro

set -e

echo "🚀 Instalação simples - OLC Notificações"
echo ""

# Swap crítico para 1GB RAM
echo "💾 Configurando swap..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt update

# Node.js 18
echo "🟢 Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Dependências WhatsApp
echo "🔧 Dependências WhatsApp..."
sudo apt install -y libnss3 libatk1.0-0t64 libgtk-3-0t64 libgbm1 libasound2t64

# PM2
echo "⚡ Instalando PM2..."
sudo npm install -g pm2

# Instalar dependências do projeto
echo "📦 Instalando dependências..."
npm install

echo "✅ Instalação concluída!"