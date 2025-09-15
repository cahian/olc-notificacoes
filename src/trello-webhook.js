const express = require('express');
const bodyParser = require('body-parser');

class TrelloWebhook {
    constructor(whatsappBot, groupName) {
        this.whatsappBot = whatsappBot;
        this.groupName = groupName;
        this.app = express();
        this.setupMiddleware();
        this.setupRoutes();
    }

    setupMiddleware() {
        this.app.use(bodyParser.json());
        this.app.use((req, res, next) => {
            console.log(`📥 ${new Date().toISOString()} - ${req.method} ${req.path}`);
            next();
        });
    }

    setupRoutes() {
        // Rota de teste
        this.app.get('/', (req, res) => {
            res.json({ 
                message: 'OLC Notificações - Webhook Trello ativo!',
                timestamp: new Date().toISOString() 
            });
        });

        // Webhook principal do Trello - GET para validação
        this.app.get('/trello-webhook', (req, res) => {
            res.status(200).send('OK');
        });

        // Webhook principal do Trello - POST para eventos
        this.app.post('/trello-webhook', (req, res) => {
            this.handleTrelloWebhook(req, res);
        });

        // Rota para teste manual
        this.app.post('/test-notification', (req, res) => {
            const { message } = req.body;
            if (message) {
                this.whatsappBot.sendMessageToGroup(this.groupName, `🧪 TESTE: ${message}`);
                res.json({ success: true, message: 'Notificação de teste enviada!' });
            } else {
                res.status(400).json({ error: 'Campo "message" é obrigatório' });
            }
        });
    }

    async handleTrelloWebhook(req, res) {
        try {
            const action = req.body.action;
            
            if (!action) {
                console.log('⚠️ Webhook sem action válida');
                return res.sendStatus(200);
            }

            // Novo card criado
            if (action.type === 'createCard') {
                await this.handleNewCard(action);
            }
            
            // Card movido para lista
            else if (action.type === 'updateCard' && action.data.listAfter) {
                await this.handleCardMoved(action);
            }
            
            // Comentário adicionado
            else if (action.type === 'commentCard') {
                await this.handleCardComment(action);
            }

            res.sendStatus(200);

        } catch (error) {
            console.error('❌ Erro no webhook do Trello:', error);
            res.sendStatus(500);
        }
    }

    async handleNewCard(action) {
        const card = action.data.card;
        const list = action.data.list;
        const board = action.data.board;
        const member = action.memberCreator;

        const message = `📌 *NOVO CARD CRIADO*
        
🏷️ *Card:* ${card.name}
📋 *Lista:* ${list.name}
🎯 *Quadro:* ${board.name}
👤 *Criado por:* ${member.fullName}
🔗 *Link:* https://trello.com/c/${card.shortLink}

⏰ ${new Date().toLocaleString('pt-BR')}`;

        await this.whatsappBot.sendMessageToGroup(this.groupName, message);
        console.log(`✅ Notificação enviada: Novo card "${card.name}"`);
    }

    async handleCardMoved(action) {
        const card = action.data.card;
        const listBefore = action.data.listBefore;
        const listAfter = action.data.listAfter;
        const member = action.memberCreator;

        const message = `🔄 *CARD MOVIDO*

🏷️ *Card:* ${card.name}
📤 *De:* ${listBefore.name}
📥 *Para:* ${listAfter.name}
👤 *Movido por:* ${member.fullName}
🔗 *Link:* https://trello.com/c/${card.shortLink}

⏰ ${new Date().toLocaleString('pt-BR')}`;

        await this.whatsappBot.sendMessageToGroup(this.groupName, message);
        console.log(`✅ Notificação enviada: Card "${card.name}" movido`);
    }

    async handleCardComment(action) {
        const card = action.data.card;
        const comment = action.data.text;
        const member = action.memberCreator;

        const message = `💬 *NOVO COMENTÁRIO*

🏷️ *Card:* ${card.name}
👤 *Comentário de:* ${member.fullName}
📝 *Texto:* ${comment.length > 100 ? comment.substring(0, 100) + '...' : comment}
🔗 *Link:* https://trello.com/c/${card.shortLink}

⏰ ${new Date().toLocaleString('pt-BR')}`;

        await this.whatsappBot.sendMessageToGroup(this.groupName, message);
        console.log(`✅ Notificação enviada: Comentário no card "${card.name}"`);
    }

    start(port = 3000) {
        this.server = this.app.listen(port, () => {
            console.log(`🌐 Webhook do Trello rodando em http://localhost:${port}`);
            console.log(`📋 URL do webhook: http://localhost:${port}/trello-webhook`);
            console.log(`🧪 URL de teste: http://localhost:${port}/test-notification`);
        });
        return this.server;
    }

    stop() {
        if (this.server) {
            this.server.close();
            console.log('🛑 Servidor webhook parado');
        }
    }
}

module.exports = TrelloWebhook;