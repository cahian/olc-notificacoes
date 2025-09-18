# 🚀 Deploy Simples - OLC Notificações

Deploy mínimo para AWS EC2 t2.micro (Free Tier).

## 🎯 3 comandos para deploy completo

### **Deploy inicial:**
```bash
git clone https://github.com/SEU-USUARIO/olc-notificacoes.git
cd olc-notificacoes
./deploy/simple-install.sh && ./deploy/simple-start.sh
```

### **Atualizações:**
```bash
./deploy/simple-deploy.sh
```

## 📋 Pré-requisitos

- **EC2 t2.micro** (AWS Free Tier)
- **Ubuntu 22.04**
- **Security Groups**: Portas 22 (SSH) e 3000 (App)

## 🔧 O que cada script faz

### `simple-install.sh` (30 linhas)
- ✅ Configura swap (2GB)
- ✅ Instala Node.js 18
- ✅ Instala dependências WhatsApp
- ✅ Instala PM2
- ✅ Instala dependências do projeto

### `simple-start.sh` (20 linhas)
- ✅ Cria .env interativo
- ✅ Inicia PM2
- ✅ Configura auto-start

### `simple-deploy.sh` (10 linhas)
- ✅ Git pull
- ✅ Atualiza deps (se necessário)
- ✅ Restart PM2

## 🌐 Security Groups AWS

**Regras de entrada:**
- **SSH (22)**: 0.0.0.0/0
- **Custom TCP (3000)**: 0.0.0.0/0

## 🪝 Webhook Trello

```bash
# Pegar IP da instância
IP=$(curl -s ifconfig.me)

# Registrar webhook
curl -X POST "https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC AWS",
    "callbackURL": "http://'$IP':3000/trello-webhook",
    "idModel": "SEU_BOARD_ID_TRELLO"
  }'
```

## 📱 WhatsApp

```bash
# Ver logs para QR Code
pm2 logs olc-notificacoes

# Limpar sessão se necessário
rm -rf .wwebjs_auth && pm2 restart olc-notificacoes
```

## 🚨 Troubleshooting

### App não inicia
```bash
pm2 logs olc-notificacoes  # Ver erros
free -h                    # Verificar RAM
pm2 restart olc-notificacoes
```

### WhatsApp não conecta
```bash
# Instalar dependências faltantes
sudo apt install -y libnss3 libatk1.0-0 libgtk-3-0 libgbm1

# Limpar e reconectar
rm -rf .wwebjs_auth && pm2 restart olc-notificacoes
```

### RAM baixa (t2.micro = 1GB)
```bash
free -h          # Verificar uso
pm2 monit        # Monitorar processo
sudo reboot      # Último recurso
```

## 💰 AWS Free Tier

- **750 horas/mês** t2.micro (12 meses grátis)
- **30GB EBS** storage
- **15GB** data transfer

## 📊 Comandos úteis

```bash
pm2 status              # Status da app
pm2 logs olc-notificacoes  # Ver logs
pm2 monit               # Monitor recursos
curl localhost:3000     # Testar app
```

**Deploy simples, sem complicação! 🎉**