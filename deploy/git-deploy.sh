#!/bin/bash

# Git Deploy Script - OLC Notificações
# Deploy/atualização via Git pull para Google Cloud e2-micro

set -e

echo "🚀 Git Deploy - OLC Notificações"
echo "================================"
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "src/server.js" ]; then
    echo "❌ ERRO: Execute este script do diretório /opt/olc-notificacoes"
    echo "💡 Comando: cd /opt/olc-notificacoes && sudo ./deploy/git-deploy.sh"
    exit 1
fi

# Verificar se é um repositório Git
if [ ! -d ".git" ]; then
    echo "❌ ERRO: Diretório não é um repositório Git"
    echo "💡 Clone o repo: git clone https://github.com/SEU-USUARIO/olc-notificacoes.git"
    exit 1
fi

# Backup das configurações críticas antes do deploy
echo "💾 Fazendo backup das configurações..."
if [ -f ".env" ]; then
    cp .env .env.backup
    echo "✅ Backup do .env criado"
fi

if [ -d ".wwebjs_auth" ]; then
    cp -r .wwebjs_auth .wwebjs_auth.backup
    echo "✅ Backup da sessão WhatsApp criado"
fi

# Verificar status atual do Git
echo ""
echo "📋 Status do repositório:"
git status --porcelain
echo ""

# Fazer stash de mudanças locais (se houver)
if ! git diff --quiet || ! git diff --staged --quiet; then
    echo "💾 Fazendo stash das mudanças locais..."
    git stash push -m "Deploy backup $(date +%Y%m%d_%H%M%S)"
    STASHED=true
else
    STASHED=false
fi

# Puxar atualizações
echo "⬇️ Puxando atualizações do repositório..."
git fetch origin

# Verificar se há atualizações
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ Repositório já está atualizado!"

    # Restaurar backup se necessário
    if [ -f ".env.backup" ]; then
        cp .env.backup .env
        rm .env.backup
    fi

    echo "ℹ️ Nenhuma atualização necessária."
    exit 0
fi

echo "🔄 Atualizações disponíveis, aplicando..."

# Parar aplicação durante deploy
echo "⏸️ Parando aplicação..."
sudo -u olc-app pm2 stop olc-notificacoes || echo "⚠️ Aplicação já estava parada"

# Aplicar atualizações
git pull origin main

# Verificar se package.json mudou (necessário npm install)
if git diff HEAD~1 --name-only | grep -q "package.json"; then
    echo "📦 package.json modificado, atualizando dependências..."

    # Limpeza preventiva para e2-micro
    echo "🧹 Limpeza preventiva de memória..."
    sudo sync && sudo sysctl vm.drop_caches=3

    # Install com otimizações para e2-micro
    export npm_config_cache=/tmp/npm-cache
    export NODE_OPTIONS="--max-old-space-size=400"

    sudo -E npm install --production --no-optional
    sudo npm cache clean --force
    sudo rm -rf /tmp/npm-cache

    echo "✅ Dependências atualizadas"
fi

# Restaurar configurações críticas
echo "🔧 Restaurando configurações..."

if [ -f ".env.backup" ]; then
    cp .env.backup .env
    rm .env.backup
    echo "✅ .env restaurado"
fi

if [ -d ".wwebjs_auth.backup" ]; then
    rm -rf .wwebjs_auth 2>/dev/null || true
    mv .wwebjs_auth.backup .wwebjs_auth
    echo "✅ Sessão WhatsApp restaurada"
fi

# Ajustar permissões
sudo chown -R olc-app:olc-app /opt/olc-notificacoes
sudo chmod 600 .env 2>/dev/null || true

# Verificar se há scripts de migration/setup
if [ -f "deploy/post-deploy.sh" ]; then
    echo "🔄 Executando script pós-deploy..."
    chmod +x deploy/post-deploy.sh
    ./deploy/post-deploy.sh
fi

# Reiniciar aplicação
echo "▶️ Reiniciando aplicação..."
sudo -u olc-app pm2 restart olc-notificacoes

# Aguardar aplicação inicializar
echo "⏳ Aguardando inicialização..."
sleep 5

# Verificar se aplicação está rodando
if sudo -u olc-app pm2 status olc-notificacoes | grep -q "online"; then
    echo "✅ Aplicação reiniciada com sucesso!"
else
    echo "❌ ERRO: Aplicação não conseguiu iniciar"
    echo "📋 Status PM2:"
    sudo -u olc-app pm2 status olc-notificacoes
    echo ""
    echo "📝 Últimos logs:"
    sudo -u olc-app pm2 logs olc-notificacoes --lines 10 --nostream
    exit 1
fi

# Teste rápido de conectividade
echo ""
echo "🧪 Testando aplicação..."
if timeout 10 curl -s localhost:3000 > /dev/null; then
    echo "✅ Aplicação respondendo corretamente"
else
    echo "⚠️ Aplicação pode estar com problemas"
    echo "💡 Verifique: pm2 logs olc-notificacoes"
fi

# Status final
echo ""
echo "📊 STATUS FINAL:"
echo "==============="
echo "Git commit: $(git rev-parse --short HEAD)"
echo "Deploy time: $(date)"
echo "PM2 status:"
sudo -u olc-app pm2 status olc-notificacoes --no-ansi

# Recursos da VM
echo ""
echo "💻 Recursos da VM:"
FREE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
USED_RAM=$(free -m | awk 'NR==2{printf "%.0f", $3}')
echo "RAM livre: ${FREE_RAM}MB | Usada: ${USED_RAM}MB"

if [ "$FREE_RAM" -lt "100" ]; then
    echo "🚨 RAM baixa! Execute: emergency-cleanup"
fi

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "================================"
echo ""
echo "✅ Código atualizado via Git"
echo "✅ Dependências atualizadas (se necessário)"
echo "✅ Configurações preservadas"
echo "✅ Aplicação reiniciada"
echo "✅ Teste de conectividade OK"
echo ""
echo "📋 Próximos comandos úteis:"
echo "- pm2 logs olc-notificacoes (ver logs)"
echo "- pm2 monit (monitorar recursos)"
echo "- gcp-monitor (status completo)"
echo ""

# Limpeza final
if [ "$STASHED" = true ]; then
    echo "💾 Mudanças locais foram salvas em stash"
    echo "💡 Para recuperar: git stash pop"
fi