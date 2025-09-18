# 🚀 OLC Notificações

Sistema automatizado de notificações WhatsApp para monitoramento de Trello e emails.

## 📋 Funcionalidades

- ✅ **Notificações do Trello**: Receba alertas quando cards forem criados, movidos ou comentados
- ✅ **Monitor de Email**: Notificações automáticas para emails de remetentes específicos
- ✅ **Grupo WhatsApp**: Todas as notificações são enviadas para um grupo específico
- ✅ **Webhook HTTP**: Endpoint para receber eventos do Trello
- ✅ **Reconexão Automática**: Sistema robusto com reconexão automática

## 🎯 Casos de Uso

1. **Trello**: Monitorar o quadro [Unimed de Monte Alto](https://trello.com/b/UWvlgBP4/unimed-de-monte-alto)
2. **Email**: Alertas para emails configurados

## 🛠️ Instalação

### 1. Clonar e instalar dependências

```bash
# Clonar repositório
cd olc-notificacoes

# Instalar dependências
npm install
```

### 2. Configurar variáveis de ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar configurações
nano .env
```

**Configurações obrigatórias no `.env`:**

```env
# WhatsApp
WHATSAPP_GROUP_NAME=GRUPO DE NOTIFICAÇÕES

# Email (Gmail)
EMAIL_USER=seu-email@gmail.com
EMAIL_PASSWORD=sua-senha-de-app
EMAIL_HOST=imap.gmail.com

# Emails para monitorar
TARGET_EMAILS=exemplo@empresa.com.br

# Servidor
PORT=3000
```

### 3. Configurar senha de app do Gmail

Para Gmail, você precisa gerar uma **senha de app**:

1. Acesse [myaccount.google.com](https://myaccount.google.com)
2. Vá em **Segurança** → **Verificação em duas etapas**
3. Em **Senhas de app**, gere uma nova senha
4. Use essa senha no `EMAIL_PASSWORD`

## 🚀 Execução

### Modo desenvolvimento

```bash
npm run dev
```

### Modo produção

```bash
npm start
```

## 📱 Configuração do WhatsApp

1. Execute o sistema
2. Escaneie o QR Code com seu WhatsApp
3. Crie/acesse o grupo "GRUPO DE NOTIFICAÇÕES"
4. Pronto! 🎉

## 🔗 Configuração do Webhook Trello

### 1. Expor servidor localmente (ngrok)

```bash
# Instalar ngrok
npm install -g ngrok

# Expor porta 3000
ngrok http 3000
```

### 2. Registrar webhook no Trello

```bash
# Substituir YOUR_NGROK_URL pela URL do ngrok
curl -X POST https://api.trello.com/1/tokens/YOUR_TOKEN/webhooks/ \
  -H "Content-Type: application/json" \
  -d '{
    "description": "OLC Notificações",
    "callbackURL": "https://YOUR_NGROK_URL.ngrok.io/trello-webhook",
    "idModel": "UWvlgBP4"
  }'
```

**Como obter o token do Trello:**
1. Acesse: https://trello.com/1/appKey/generate
2. Clique em "Token" para gerar seu token pessoal

## 🧪 Testes

### Testar notificação manual

```bash
curl -X POST http://localhost:3000/test-notification \
  -H "Content-Type: application/json" \
  -d '{"message":"Sistema funcionando!"}'
```

### Verificar status

```bash
curl http://localhost:3000/
```

## 📊 Monitoramento

O sistema exibe logs detalhados:

```
✅ Bot do WhatsApp conectado e pronto!
🌐 Webhook do Trello rodando em http://localhost:3000
📨 Monitor de emails ativo!
📧 1 novo(s) email(s) recebido(s)
✅ Notificação enviada: Novo card "Tarefa XYZ"
```

## 🔧 Estrutura do Projeto

```
olc-notificacoes/
├── src/
│   ├── server.js           # Ponto de entrada principal
│   ├── whatsapp-bot.js     # Cliente WhatsApp
│   ├── trello-webhook.js   # Webhook para Trello
│   ├── email-monitor.js    # Monitor de emails
│   └── config.js           # Configurações
├── .env.example            # Exemplo de configuração
├── package.json
└── README.md
```

## ⚠️ Considerações Importantes

### Riscos do WhatsApp Web

- O `whatsapp-web.js` simula o WhatsApp Web
- **Risco baixo** para uso interno com poucos envios
- Evite spam ou envios em massa
- WhatsApp pode desconectar a sessão se detectar automação

### Alternativas Oficiais

Para uso comercial, considere:
- **Twilio WhatsApp API** (oficial, pago)
- **360dialog** (provedor oficial)
- **Zenvia** (provedor brasileiro)

## 🆘 Solução de Problemas

### WhatsApp não conecta

1. Verificar se já existe sessão ativa
2. Deletar pasta `.wwebjs_auth`
3. Escanear QR Code novamente

### Emails não são monitorados

1. Verificar credenciais Gmail
2. Confirmar senha de app (não senha comum)
3. Verificar conexão IMAP

### Webhook não recebe eventos

1. Verificar se ngrok está rodando
2. Confirmar URL do webhook no Trello
3. Testar endpoint manualmente

## 📈 Próximos Passos

- [ ] Interface web para gerenciar configurações
- [ ] Suporte a múltiplos grupos WhatsApp
- [ ] Dashboard de estatísticas
- [ ] Integração com Slack/Discord
- [ ] Filtros avançados para emails

## 📄 Licença

MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

💡 **Dúvidas?** Abra uma issue ou entre em contato!