# 🔄 Workflow Git - Deploy Automático

Sistema de deploy baseado em Git para facilitar atualizações contínuas.

## 🎯 Vantagens do Deploy via Git

- ✅ **Simples**: Apenas `git pull` para atualizar
- ✅ **Seguro**: Backup automático de configurações
- ✅ **Rápido**: Só baixa mudanças incrementais
- ✅ **Versionado**: Controle total de versões
- ✅ **Rollback**: Fácil retorno para versões anteriores

## 🚀 Setup Inicial

### 1. Criar VM no Google Cloud
```bash
# No console GCP, criar e2-micro (Free Tier)
# Configurar firewall para porta 3000
```

### 2. Deploy inicial via Git
```bash
# SSH na VM
gcloud compute ssh olc-notificacoes --zone=us-central1-a

# Clonar repositório
git clone https://github.com/SEU-USUARIO/olc-notificacoes.git
cd olc-notificacoes

# Instalação inicial
sudo ./deploy/install-gcp.sh

# Configuração automática
./deploy/gcp-quickstart.sh
```

## 🔄 Workflow de Atualizações

### Desenvolvimento Local
```bash
# Fazer mudanças no código
git add .
git commit -m "feat: nova funcionalidade"
git push origin main
```

### Deploy no Servidor
```bash
# SSH na VM
gcloud compute ssh olc-notificacoes --zone=us-central1-a

# Aplicar atualizações
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

**É só isso!** O script faz tudo automaticamente:
- ✅ Backup das configurações
- ✅ Pull das atualizações
- ✅ Atualização de dependências (se necessário)
- ✅ Restart da aplicação
- ✅ Testes de conectividade

## 📋 O que o git-deploy.sh faz

1. **Backup**: Salva `.env` e sessão WhatsApp
2. **Stash**: Preserva mudanças locais
3. **Pull**: Atualiza código do repositório
4. **Dependencies**: Atualiza `npm install` se `package.json` mudou
5. **Restore**: Restaura configurações críticas
6. **Restart**: Reinicia aplicação via PM2
7. **Test**: Verifica se aplicação está funcionando

## 🛡️ Proteções Incluídas

### Backup Automático
```bash
# Antes de cada deploy
.env → .env.backup
.wwebjs_auth → .wwebjs_auth.backup
```

### Rollback Rápido
```bash
# Se algo der errado
cd /opt/olc-notificacoes
git log --oneline  # ver commits
git reset --hard COMMIT_ANTERIOR
sudo -u olc-app pm2 restart olc-notificacoes
```

### Stash de Mudanças
```bash
# Mudanças locais são preservadas
git stash list
git stash pop  # recuperar se necessário
```

## 🔧 Comandos Úteis

### Status e Logs
```bash
# Status da aplicação
pm2 status

# Ver logs em tempo real
pm2 logs olc-notificacoes

# Monitorar recursos
gcp-monitor

# Status do Git
git status
git log --oneline -10
```

### Manutenção
```bash
# Limpeza de memória (e2-micro)
emergency-cleanup

# Reiniciar aplicação
sudo -u olc-app pm2 restart olc-notificacoes

# Atualizar apenas dependências
cd /opt/olc-notificacoes
sudo npm install --production
```

## 🚨 Troubleshooting

### Deploy falhou
```bash
# Ver logs do deploy
cat /var/log/olc-notificacoes/error.log

# Verificar status Git
git status
git diff

# Forçar reset se necessário
git reset --hard origin/main
```

### Aplicação não inicia
```bash
# Verificar PM2
pm2 status
pm2 logs olc-notificacoes

# Verificar recursos
free -h
df -h

# Restart manual
sudo -u olc-app pm2 restart olc-notificacoes
```

### Configurações perdidas
```bash
# Restaurar backup
cp .env.backup .env
cp -r .wwebjs_auth.backup .wwebjs_auth

# Ajustar permissões
sudo chown olc-app:olc-app .env .wwebjs_auth
sudo chmod 600 .env
```

## 🎯 Workflow Completo de Desenvolvimento

### 1. Desenvolvimento
```bash
# Local
git checkout -b nova-feature
# ... desenvolvimento ...
git add .
git commit -m "feat: implementar nova feature"
git push origin nova-feature
```

### 2. Merge
```bash
# GitHub/GitLab
# Criar Pull Request
# Review + Merge para main
```

### 3. Deploy
```bash
# Servidor
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

### 4. Verificação
```bash
# Testar aplicação
curl localhost:3000
pm2 logs olc-notificacoes --lines 20
```

## 💡 Dicas Avançadas

### Deploy Automático via Webhook
```bash
# Configurar webhook no GitHub para deploy automático
# quando há push na branch main
```

### Staging Environment
```bash
# Criar branch staging para testes
git checkout -b staging
# Deploy de staging em outra VM
```

### Backup Automático
```bash
# Cron job para backup diário
0 2 * * * cd /opt/olc-notificacoes && tar -czf backup-$(date +\%Y\%m\%d).tar.gz .env .wwebjs_auth
```

## 📊 Vantagens vs Upload Manual

| Aspecto | Git Deploy | Upload Manual |
|---------|------------|---------------|
| **Velocidade** | ⚡ Segundos | 🐌 Minutos |
| **Segurança** | 🛡️ Backup automático | ⚠️ Manual |
| **Rollback** | ✅ 1 comando | ❌ Complexo |
| **Versionamento** | ✅ Completo | ❌ Limitado |
| **Facilidade** | ✅ 1 script | ❌ Múltiplos passos |

## 🎉 Resultado Final

Com este workflow você terá:

- ✅ **Deploy em 30 segundos** com 1 comando
- ✅ **Zero downtime** para pequenas mudanças
- ✅ **Backup automático** de configurações críticas
- ✅ **Rollback instantâneo** se algo der errado
- ✅ **Logs detalhados** de cada deploy
- ✅ **Compatível com e2-micro** (1GB RAM)

**Desenvolveu → Commitou → Deploy!** 🚀