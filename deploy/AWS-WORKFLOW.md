# 🔄 Workflow AWS - Deploy Automático

Sistema de deploy baseado em Git para AWS EC2 Free Tier.

## 🎯 AWS Free Tier - O que você ganha

- ✅ **750 horas/mês** de EC2 t2.micro (12 meses)
- ✅ **30GB EBS** gp2 storage (12 meses)
- ✅ **15GB** data transfer out (12 meses)
- ✅ **IP elástico** gratuito (se usado)
- ✅ **Load Balancer** Application (750 horas)

## 🚀 Setup Inicial

### 1. Criar instância EC2
```bash
# No Console AWS:
# 1. EC2 > Launch Instance
# 2. Escolher: Ubuntu 22.04 LTS (Free tier eligible)
# 3. Instance type: t2.micro
# 4. Key pair: Criar/usar existente
# 5. Security groups: SSH (22), Custom TCP (3000)
```

### 2. Deploy inicial via Git
```bash
# SSH na instância
ssh -i chave.pem ubuntu@IP_PUBLICO_AWS

# Clonar repositório
git clone https://github.com/SEU-USUARIO/olc-notificacoes.git
cd olc-notificacoes

# Instalação inicial
sudo ./deploy/install-aws.sh

# Configuração automática
./deploy/aws-quickstart.sh
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
# SSH na instância
ssh -i chave.pem ubuntu@IP_PUBLICO_AWS

# Aplicar atualizações
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

## 📋 Security Groups AWS

**Regras de entrada obrigatórias:**

| Tipo | Protocolo | Porta | Origem |
|------|-----------|-------|--------|
| SSH | TCP | 22 | 0.0.0.0/0 |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 |
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTPS | TCP | 443 | 0.0.0.0/0 |

## 🛡️ Proteções Incluídas

### Backup Automático
```bash
# git-deploy.sh faz backup de:
.env → .env.backup
.wwebjs_auth → .wwebjs_auth.backup
```

### Monitoramento AWS
```bash
# Script específico para t2.micro
aws-monitor

# Ver metadata da instância
curl http://169.254.169.254/latest/meta-data/instance-type
curl http://169.254.169.254/latest/meta-data/public-ipv4
curl http://169.254.169.254/latest/meta-data/placement/availability-zone
```

### Otimizações para 1GB RAM
```bash
# Swap de 2GB configurado automaticamente
# Node.js limitado a 400MB
# PM2 com restart em 400MB
# Logs com rotação agressiva
```

## 🔧 Comandos Úteis AWS

### Status e Logs
```bash
# Status da aplicação
pm2 status

# Ver logs em tempo real
pm2 logs olc-notificacoes

# Monitorar recursos (crítico para t2.micro)
aws-monitor

# Limpeza de emergência
emergency-cleanup
```

### Informações da instância
```bash
# Tipo da instância
curl -s http://169.254.169.254/latest/meta-data/instance-type

# IP público
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

# Zona de disponibilidade
curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone

# Região
curl -s http://169.254.169.254/latest/meta-data/placement/region
```

### Manutenção EC2
```bash
# Reiniciar instância (via console AWS)
# Parar/iniciar instância (muda IP público)
# Criar snapshot do EBS
# Associar IP elástico (recomendado para produção)
```

## 🚨 Troubleshooting AWS

### RAM insuficiente (comum em t2.micro)
```bash
# Verificar uso
free -h
htop

# Limpeza agressiva
emergency-cleanup

# Verificar swap
swapon --show

# Reiniciar aplicação
sudo -u olc-app pm2 restart olc-notificacoes
```

### Security Groups
```bash
# Testar conectividade
telnet IP_PUBLICO 3000

# Verificar regras no console AWS
# EC2 > Security Groups > Inbound rules
```

### Storage (30GB free tier)
```bash
# Verificar espaço
df -h

# Limpeza de logs
sudo journalctl --vacuum-time=7d
sudo find /var/log -name "*.log" -type f -size +10M -delete
```

## 💰 Monitoramento de Custos

### Free Tier Usage
```bash
# No Console AWS:
# Billing > Free Tier
# CloudWatch > Billing
# Cost Explorer
```

### Limites importantes
- **750 horas/mês** t2.micro (não exceder)
- **30GB EBS** (monitorar uso)
- **15GB transfer** out (suficiente para webhooks)

### Dicas para não ser cobrado
- Use apenas **1 instância t2.micro**
- **Pare a instância** quando não usar
- **Delete snapshots** antigos
- **Monitore billing** semanalmente

## 🎯 Vantagens AWS vs Outros

| Aspecto | AWS Free Tier | GCP Free Tier | Oracle Free |
|---------|---------------|---------------|-------------|
| **Tempo** | 12 meses | Permanente | Permanente |
| **RAM** | 1GB | 1GB | 24GB |
| **CPU** | 1 vCPU | 0.25 vCPU | 4 vCPU |
| **Storage** | 30GB | 30GB | 200GB |
| **Transfer** | 15GB | 1GB | 10TB |
| **Suporte** | Excelente | Bom | Básico |

## 🔄 Workflow Completo AWS

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
# Instância AWS
cd /opt/olc-notificacoes
sudo ./deploy/git-deploy.sh
```

### 4. Verificação
```bash
# Testar aplicação
curl http://IP_PUBLICO:3000
pm2 logs olc-notificacoes --lines 20

# Monitorar recursos
aws-monitor
```

## 💡 Dicas Avançadas AWS

### IP Elástico (Recomendado)
```bash
# Console AWS > EC2 > Elastic IPs
# Allocate new address
# Associate with instance
# Evita mudança de IP após reboot
```

### Load Balancer (Free Tier)
```bash
# Application Load Balancer
# 750 horas gratuitas
# SSL/TLS termination
# Health checks
```

### CloudWatch (Monitoramento)
```bash
# Métricas gratuitas:
# CPU Utilization
# Network In/Out
# Disk Read/Write
# Status Check
```

### Backup automático
```bash
# EBS Snapshots
# Scheduled via Lambda
# Data Lifecycle Manager
```

## 🎉 Resultado Final

Com este workflow você terá:

- ✅ **Deploy gratuito** por 12 meses
- ✅ **Infraestrutura robusta** AWS
- ✅ **Monitoramento integrado** CloudWatch
- ✅ **Backup automático** de configurações
- ✅ **Escalabilidade** (quando sair do free tier)

**Desenvolveu → Commitou → Deploy na AWS!** ☁️