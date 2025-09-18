# 🚀 Deploy Google Cloud Free Tier - OLC Notificações

Guia completo para deploy gratuito do sistema no Google Cloud Platform (GCP).

## 🎯 Por que Google Cloud Free Tier?

- **1 VM e2-micro**: 0.25-1 vCPU + 1GB RAM - GRÁTIS PARA SEMPRE
- **30GB Persistent Disk**: Armazenamento SSD
- **1GB egress/mês**: Transferência de dados grátis
- **Disponível em 3 regiões US**: Oregon, Iowa, South Carolina
- **Sem limite de tempo**: Always Free permanente

## ⚠️ Limitações do e2-micro

- **RAM**: Apenas 1GB (precisa otimização)
- **CPU**: Shared core (0.25-1 vCPU)
- **Egress**: 1GB/mês (suficiente para webhooks/notificações)
- **Região**: Apenas US (latência OK para webhooks)

## 🔧 Especificações da VM

- **Machine Type**: e2-micro (shared core, 1GB RAM)
- **Disk**: 30GB Standard Persistent Disk
- **OS**: Ubuntu 22.04 LTS
- **Region**: us-central1-a (Iowa - melhor latência para Brasil)
- **Network**: Default VPC com IP externo

## 🚀 Processo de Deploy

### 1. Criar VM no Google Cloud

1. Acesse [console.cloud.google.com](https://console.cloud.google.com)
2. Crie um projeto ou use existing
3. Vá para **Compute Engine > VM instances**
4. Clique **Create Instance**

**Configurações obrigatórias para Free Tier:**
- **Name**: olc-notificacoes
- **Region**: us-central1 (Iowa)
- **Zone**: us-central1-a
- **Machine type**: e2-micro (0.25-1 vCPU, 1GB memory)
- **Boot disk**: Ubuntu 22.04 LTS, 30GB Standard
- **Firewall**: Allow HTTP e HTTPS traffic

### 2. Configurar Firewall

No console GCP:
1. **VPC network > Firewall**
2. **Create Firewall Rule**:
   - **Name**: allow-olc-app
   - **Direction**: Ingress
   - **Targets**: Tags
   - **Target tags**: olc-app
   - **Source IP**: 0.0.0.0/0
   - **Protocols**: TCP
   - **Ports**: 3000

3. **Editar VM** e adicionar **Network tag**: olc-app

### 3. Primeiro acesso SSH

```bash
# Via browser (recomendado)
# No console GCP, clique SSH na VM

# Ou via gcloud CLI
gcloud compute ssh olc-notificacoes --zone=us-central1-a

# Atualizar sistema
sudo apt update && sudo apt upgrade -y
```

### 4. Preparar arquivos localmente

```bash
# Comprimir projeto (mais agressivo para 1GB RAM)
tar -czf olc-notificacoes.tar.gz \
  --exclude=node_modules \
  --exclude=.env \
  --exclude=.wwebjs_auth \
  --exclude=.git \
  --exclude=deploy/ORACLE-DEPLOY.md \
  --exclude=deploy/install-oracle.sh \
  --exclude=deploy/oracle-quickstart.sh \
  .
```

### 5. Upload e instalação

```bash
# Upload via SCP (através do gcloud)
gcloud compute scp olc-notificacoes.tar.gz olc-notificacoes:~/ --zone=us-central1-a

# SSH na VM
gcloud compute ssh olc-notificacoes --zone=us-central1-a

# Extrair e instalar
tar -xzf olc-notificacoes.tar.gz
cd olc-notificacoes
chmod +x deploy/*.sh
sudo ./deploy/install-gcp.sh
```

### 6. Configuração otimizada

```bash
# Script de setup para e2-micro
./deploy/gcp-quickstart.sh
```

### 7. Webhook Trello

```bash
# Pegar IP externo
EXTERNAL_IP=$(curl -s ifconfig.me)

curl -X POST "https://api.trello.com/1/webhooks/?key=SUA_CHAVE&token=SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC Google Cloud",
    "callbackURL": "http://'$EXTERNAL_IP':3000/trello-webhook",
    "idModel": "SEU_BOARD_ID_TRELLO"
  }'
```

## 🔧 Otimizações Críticas para e2-micro

### Configuração de Swap
```bash
# Swap de 2GB (essencial com 1GB RAM)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Node.js otimizado
```bash
# Usar Node.js 18 LTS (mais leve que 20)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Limitar memória do Node.js
export NODE_OPTIONS="--max-old-space-size=512"
```

### PM2 configuração mínima
```javascript
// ecosystem.config.js otimizado
module.exports = {
  apps: [{
    name: 'olc-notificacoes',
    script: './src/server.js',
    instances: 1,
    max_memory_restart: '400M',
    node_args: '--max-old-space-size=400',
    watch: false,
    autorestart: true
  }]
};
```

## 💰 Monitoramento de Custos

**Always Free (permanente):**
- ✅ 1 e2-micro VM
- ✅ 30GB persistent disk
- ✅ 1GB egress/mês
- ✅ IP externo estático (apenas 1)

**Para não ser cobrado:**
- Use apenas 1 e2-micro por vez
- Mantenha disco ≤ 30GB
- Monitore egress < 1GB/mês
- Pare VM quando não usar (opcional)

## 🚨 Troubleshooting GCP-específico

### RAM insuficiente
```bash
# Verificar uso de memória
free -h
htop

# Limpar cache se necessário
sudo sync && sudo sysctl vm.drop_caches=3

# Reiniciar aplicação
pm2 restart olc-notificacoes
```

### Aplicação crashando (OOM)
```bash
# Verificar logs de OOM
dmesg | grep -i "killed process"

# Ajustar limites PM2
pm2 restart olc-notificacoes --max-memory-restart 350M
```

### Conectividade
```bash
# Verificar firewall interno
sudo ufw status

# Verificar tags da VM no console GCP
# Verificar regras de firewall no VPC
```

## 📊 Vantagens GCP Free Tier

1. **Sem tempo limite**: Always Free permanente
2. **Regiões US**: Latência aceitável (150-200ms)
3. **Egress gratuito**: 1GB suficiente para webhooks
4. **Console amigável**: Interface web excelente
5. **gcloud CLI**: Ferramenta poderosa
6. **Networking**: VPC robusta e gratuita

## 🎯 Checklist de Deploy GCP

- [ ] Conta Google Cloud criada
- [ ] Projeto criado/selecionado
- [ ] VM e2-micro criada (us-central1-a)
- [ ] Regra de firewall configurada (porta 3000)
- [ ] Network tag 'olc-app' adicionada à VM
- [ ] SSH funcionando
- [ ] Aplicação deployada com otimizações
- [ ] Swap configurado (2GB)
- [ ] PM2 com limites de memória
- [ ] Webhook Trello registrado
- [ ] WhatsApp conectado
- [ ] Testes de notificação OK
- [ ] Monitoramento configurado

**Deploy gratuito no GCP concluído! 🎉**

---

## 💡 Dicas Avançadas

### Auto-shutdown para economizar
```bash
# Script para desligar VM automaticamente (opcional)
echo "0 2 * * * /sbin/shutdown -h now" | sudo crontab -
```

### Backup de configurações
```bash
# Backup para Google Cloud Storage (tem free tier também)
gsutil cp /opt/olc-notificacoes/.env gs://seu-bucket/backup/
```

### Monitoramento de recursos
```bash
# Script personalizado para e2-micro
watch -n 30 'free -h && df -h && pm2 status'
```

**Custo mensal: R$ 0,00** 💚