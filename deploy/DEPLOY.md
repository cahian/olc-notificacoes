# 🚀 Deploy em Produção - OLC Notificações

Guia completo para deploy do sistema usando Google Cloud Platform (GCP).

## 📋 Pré-requisitos

- VM e2-micro no Google Cloud (Free Tier)
- Acesso SSH configurado
- Repositório Git configurado
- gcloud CLI instalado (opcional)

## 🔧 Especificações do Servidor (GCP Free Tier)

- **CPU**: 0.25-1 vCPU shared (e2-micro)
- **RAM**: 1GB
- **Storage**: 30GB Standard Persistent Disk
- **Network**: IP externo gratuito
- **OS**: Ubuntu 22.04 LTS
- **Região**: us-central1, us-west1, ou us-east1

## 🚀 Processo de Deploy

### 1. Deploy inicial via Git

```bash
# Conectar na VM GCP
gcloud compute ssh olc-notificacoes --zone=us-central1-a

# Clonar repositório
git clone https://github.com/SEU-USUARIO/olc-notificacoes.git
cd olc-notificacoes

# Executar instalação
chmod +x deploy/*.sh
sudo ./deploy/install-gcp.sh
```

### 2. Configuração inicial

```bash
# Setup automático
./deploy/gcp-quickstart.sh
```

### 3. Deploy via Git (atualizações)

```bash
# Para atualizações futuras
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

### 4. Configurar webhook do Trello

```bash
# Pegar IP externo da VM
EXTERNAL_IP=$(curl -s ifconfig.me)

# Registrar webhook
curl -X POST "https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC GCP Production",
    "callbackURL": "http://'$EXTERNAL_IP':3000/trello-webhook",
    "idModel": "SEU_BOARD_ID_TRELLO"
  }'
```

## 🔒 Segurança

### Arquivos sensíveis protegidos

- `.env` → Permissão 600, owner olc-app
- Credenciais nunca commitadas
- Usuário dedicado para aplicação
- Firewall configurado

### Monitoramento de logs

```bash
# Ver logs em tempo real
pm2 logs olc-notificacoes

# Status dos serviços
pm2 status

# Monitor detalhado
pm2 monit
```

## 🔧 Manutenção

### Atualizar aplicação

**Via Git (Recomendado)**
```bash
# Fazer mudanças locais
git add .
git commit -m "feat: nova funcionalidade"
git push origin main

# No servidor GCP
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

O script git-deploy.sh faz automaticamente:
- ✅ Backup de configurações (.env, WhatsApp)
- ✅ Pull das atualizações
- ✅ Atualização de dependências (se necessário)
- ✅ Restart da aplicação
- ✅ Teste de conectividade

### Backup

```bash
# Backup das configurações
sudo tar -czf backup-$(date +%Y%m%d).tar.gz \
  /opt/olc-notificacoes/.env \
  /opt/olc-notificacoes/ecosystem.config.js \
  /var/log/olc-notificacoes/
```

### Restart completo

```bash
sudo -u olc-app pm2 restart olc-notificacoes
```

## 🧪 Testes de Produção

### 1. Teste de conectividade

```bash
curl http://IP_SERVIDOR:3000/
```

### 2. Teste de notificação

```bash
curl -X POST http://IP_SERVIDOR:3000/test-notification \
  -H "Content-Type: application/json" \
  -d '{"message":"Teste de produção!"}'
```

### 3. Verificar logs

```bash
pm2 logs olc-notificacoes --lines 50
```

## 🚨 Troubleshooting

### Serviço não inicia

1. Verificar logs: `pm2 logs olc-notificacoes`
2. Verificar .env: `sudo cat /opt/olc-notificacoes/.env`
3. Verificar permissões: `ls -la /opt/olc-notificacoes/`

### WhatsApp não conecta

1. Limpar sessão: `sudo rm -rf /opt/olc-notificacoes/.wwebjs_auth`
2. Restart: `sudo -u olc-app pm2 restart olc-notificacoes`
3. Verificar QR nos logs: `pm2 logs olc-notificacoes`

### Emails não monitoram

1. Testar credenciais de email
2. Verificar portas: `sudo netstat -tlnp | grep 993`
3. Verificar firewall do provedor de email

## 📊 Monitoramento em Produção

- **CPU/RAM**: `htop` ou `pm2 monit`
- **Logs**: `/var/log/olc-notificacoes/`
- **Status**: `pm2 status`
- **Uptime**: `pm2 info olc-notificacoes`

---

## 🎯 Checklist Final

- [ ] Servidor Azure criado e configurado
- [ ] Scripts de deploy executados
- [ ] Credenciais configuradas de forma segura
- [ ] PM2 configurado e rodando
- [ ] Webhook do Trello registrado
- [ ] Testes de notificação funcionando
- [ ] WhatsApp conectado e grupo criado
- [ ] Logs sendo gerados corretamente
- [ ] Firewall configurado
- [ ] Backup configurado

**Sistema pronto para produção! 🎉**