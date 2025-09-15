#!/bin/bash

# Script de atualização para produção
# Use este script para atualizar o sistema sem Git

set -e

echo "🔄 Atualizando OLC Notificações em produção..."

# Verificar se o arquivo de update existe
if [ ! -f ~/olc-update.tar.gz ]; then
    echo "❌ Arquivo olc-update.tar.gz não encontrado em ~/"
    echo "💡 Primeiro, faça upload do arquivo de atualização:"
    echo "   1. Local: tar -czf olc-update.tar.gz --exclude=node_modules --exclude=.env src/ package.json"
    echo "   2. Upload: scp olc-update.tar.gz user@servidor:~/"
    exit 1
fi

# Ir para diretório da aplicação
cd /opt/olc-notificacoes

# Parar aplicação
echo "⏸️ Parando aplicação..."
sudo -u olc-app pm2 stop olc-notificacoes

# Backup da versão atual
echo "💾 Fazendo backup da versão atual..."
sudo tar -czf ~/backup-$(date +%Y%m%d-%H%M%S).tar.gz src/ package.json

# Extrair nova versão
echo "📦 Aplicando atualização..."
sudo tar -xzf ~/olc-update.tar.gz

# Instalar dependências
echo "📚 Atualizando dependências..."
sudo npm install --production

# Ajustar permissões
sudo chown -R olc-app:olc-app /opt/olc-notificacoes

# Reiniciar aplicação
echo "🚀 Reiniciando aplicação..."
sudo -u olc-app pm2 start olc-notificacoes

# Verificar status
echo "📊 Verificando status..."
sleep 3
sudo -u olc-app pm2 status

# Limpar arquivo de update
rm ~/olc-update.tar.gz

echo "✅ Atualização concluída!"
echo "📋 Para verificar logs: pm2 logs olc-notificacoes"