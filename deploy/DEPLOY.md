# 🚀 Deploy em Produção - OLC Notificações

Guia completo para deploy do sistema usando AWS Free Tier.

## 📋 Pré-requisitos

- Instância EC2 t2.micro no AWS Free Tier
- Acesso SSH configurado
- Repositório Git configurado
- AWS CLI instalado (opcional)

## 🔧 Especificações do Servidor (AWS Free Tier)

- **CPU**: 1 vCPU (t2.micro)
- **RAM**: 1GB
- **Storage**: 30GB EBS gp2 (SSD)
- **Network**: IP público gratuito (primeiro ano)
- **OS**: Ubuntu 22.04 LTS
- **Região**: Qualquer região AWS

## 🚀 Processo de Deploy

### 1. Deploy inicial via Git

```bash
# Conectar na instância EC2
ssh -i chave.pem ubuntu@IP_PUBLICO_AWS

# Clonar repositório
git clone https://github.com/SEU-USUARIO/olc-notificacoes.git
cd olc-notificacoes

# Executar instalação
chmod +x deploy/*.sh
sudo ./deploy/install-aws.sh
```

### 2. Configuração inicial

```bash
# Setup automático
./deploy/aws-quickstart.sh
```

### 3. Deploy via Git (atualizações)

```bash
# Para atualizações futuras
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

### 4. Configurar webhook do Trello

```bash
# Pegar IP externo da instância
EXTERNAL_IP=$(curl -s ifconfig.me)

# Registrar webhook
curl -X POST "https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC AWS Production",
    "callbackURL": "http://'$EXTERNAL_IP':3000/trello-webhook",
    "idModel": "SEU_BOARD_ID_TRELLO"
  }'
```

## 🔒 Segurança

### Arquivos sensíveis protegidos

- `.env` → Permissão 600, owner olc-app
- Credenciais nunca commitadas
- Usuário dedicado para aplicação
- Security Groups configurados

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

# No servidor AWS
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
3. Verificar Security Groups AWS

## 📊 Monitoramento em Produção

- **CPU/RAM**: `htop` ou `pm2 monit`
- **Logs**: `/var/log/olc-notificacoes/`
- **Status**: `pm2 status`
- **Uptime**: `pm2 info olc-notificacoes`

---

## 🎯 Checklist Final

- [ ] Instância EC2 t2.micro criada
- [ ] Security Groups configurados (portas 22, 3000, 80, 443)
- [ ] Scripts de deploy executados
- [ ] Credenciais configuradas de forma segura
- [ ] PM2 configurado e rodando
- [ ] Webhook do Trello registrado
- [ ] Testes de notificação funcionando
- [ ] WhatsApp conectado e grupo criado
- [ ] Logs sendo gerados corretamente
- [ ] Security Groups configurados
- [ ] Backup configurado

**Sistema pronto para produção! 🎉**