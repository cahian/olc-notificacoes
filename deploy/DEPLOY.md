# 🚀 Deploy em Produção - OLC Notificações

Guia completo para deploy do sistema em servidor Azure Ubuntu.

## 📋 Pré-requisitos

- Servidor Ubuntu 20.04+ na Azure
- Acesso SSH configurado
- Usuário com privilégios sudo
- Chave SSH configurada

## 🔧 Especificações Mínimas do Servidor

- **CPU**: 2 vCPU (Standard_B2s)
- **RAM**: 1GB mínimo, 2GB recomendado
- **Storage**: 20GB SSD
- **Network**: Porta 3000 aberta
- **OS**: Ubuntu 20.04 LTS

## 🚀 Processo de Deploy

### 1. Preparar arquivos localmente

```bash
# Comprimir projeto (excluindo node_modules e .env)
tar -czf olc-notificacoes.tar.gz \
  --exclude=node_modules \
  --exclude=.env \
  --exclude=.wwebjs_auth \
  --exclude=.git \
  .
```

### 2. Upload para servidor

```bash
# Copiar arquivos via SCP
scp olc-notificacoes.tar.gz user@IP_SERVIDOR:~/

# Conectar no servidor
ssh user@IP_SERVIDOR
```

### 3. Extração e instalação

```bash
# Extrair arquivos
tar -xzf olc-notificacoes.tar.gz
mv olc-notificacoes ~/

# Executar instalação
cd ~/olc-notificacoes
chmod +x deploy/*.sh
sudo ./deploy/install-server.sh
```

### 4. Configuração segura de credenciais

```bash
# Configurar credenciais de forma segura
./deploy/setup-credentials.sh
```

**⚠️ NUNCA digite credenciais diretamente no terminal ou scripts!**

### 5. Inicialização do serviço

```bash
# Iniciar aplicação
sudo -u olc-app pm2 start /opt/olc-notificacoes/ecosystem.config.js

# Salvar configuração do PM2
sudo -u olc-app pm2 save

# Configurar inicialização automática
sudo pm2 startup
```

### 6. Configurar webhook do Trello

Com o servidor público, registre o webhook:

```bash
curl -X POST "https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC Notificações - Produção",
    "callbackURL": "http://IP_SERVIDOR:3000/trello-webhook",
    "idModel": "6663185e7551188483173907"
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

**Opção 1: Upload manual (Recomendado)**
```bash
# 1. Local - comprimir mudanças
tar -czf olc-update.tar.gz --exclude=node_modules --exclude=.env src/ package.json

# 2. Upload para servidor
scp olc-update.tar.gz user@SERVIDOR_IP:~/

# 3. No servidor - executar update
ssh user@SERVIDOR_IP
chmod +x /opt/olc-notificacoes/deploy/update-production.sh
sudo /opt/olc-notificacoes/deploy/update-production.sh
```

**Opção 2: Via Git (se repositório configurado)**
```bash
cd /opt/olc-notificacoes
git pull origin main
npm install --production
sudo -u olc-app pm2 reload olc-notificacoes
```

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