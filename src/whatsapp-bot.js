const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');

class WhatsAppBot {
    constructor() {
        this.client = new Client({
            authStrategy: new LocalAuth({ clientId: "olc-notificacoes" }),
            puppeteer: {
                headless: true,
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-accelerated-2d-canvas',
                    '--no-first-run',
                    '--no-zygote',
                    '--single-process',
                    '--disable-gpu'
                ]
            }
        });

        this.isReady = false;
        this.setupEventHandlers();
    }

    setupEventHandlers() {
        this.client.on('qr', (qr) => {
            console.log('📱 Escaneie o QR Code abaixo com seu WhatsApp:');
            qrcode.generate(qr, { small: true });
        });

        this.client.on('ready', () => {
            console.log('✅ Bot do WhatsApp conectado e pronto!');
            this.isReady = true;
        });

        this.client.on('auth_failure', (msg) => {
            console.error('❌ Falha na autenticação:', msg);
        });

        this.client.on('disconnected', (reason) => {
            console.log('⚠️ Bot desconectado:', reason);
            this.isReady = false;
        });
    }

    async initialize() {
        try {
            await this.client.initialize();
        } catch (error) {
            console.error('❌ Erro ao inicializar bot:', error);
        }
    }

    async sendMessageToGroup(groupName, message) {
        if (!this.isReady) {
            console.log('⚠️ Bot ainda não está pronto. Mensagem não enviada.');
            return false;
        }

        try {
            const chats = await this.client.getChats();
            const group = chats.find(chat => 
                chat.isGroup && 
                chat.name.toLowerCase().includes(groupName.toLowerCase())
            );

            if (group) {
                await this.client.sendMessage(group.id._serialized, message);
                console.log(`✅ Mensagem enviada para o grupo: ${group.name}`);
                return true;
            } else {
                console.log(`❌ Grupo não encontrado: ${groupName}`);
                console.log('📋 Grupos disponíveis:');
                chats.filter(chat => chat.isGroup).forEach(group => {
                    console.log(`  - ${group.name}`);
                });
                return false;
            }
        } catch (error) {
            console.error('❌ Erro ao enviar mensagem:', error);
            return false;
        }
    }

    async destroy() {
        if (this.client) {
            await this.client.destroy();
        }
    }
}

module.exports = WhatsAppBot;