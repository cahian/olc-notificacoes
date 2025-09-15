const { config, validateConfig } = require('./config');
const WhatsAppBot = require('./whatsapp-bot');
const TrelloWebhook = require('./trello-webhook');
const EmailMonitor = require('./email-monitor');

class NotificationServer {
    constructor() {
        this.whatsappBot = null;
        this.trelloWebhook = null;
        this.emailMonitor = null;
        this.server = null;
    }

    async start() {
        try {
            console.log('🚀 Iniciando OLC Notificações...\n');

            // Validar configurações
            validateConfig();

            // Inicializar WhatsApp Bot
            console.log('📱 Inicializando bot do WhatsApp...');
            this.whatsappBot = new WhatsAppBot();
            await this.whatsappBot.initialize();

            // Aguardar WhatsApp estar pronto antes de iniciar outros serviços
            await this.waitForWhatsAppReady();

            // Inicializar Webhook do Trello
            console.log('\n📋 Inicializando webhook do Trello...');
            this.trelloWebhook = new TrelloWebhook(
                this.whatsappBot, 
                config.whatsapp.groupName
            );
            this.server = this.trelloWebhook.start(config.server.port);

            // Inicializar Monitor de Email
            console.log('\n📧 Inicializando monitor de emails...');
            this.emailMonitor = new EmailMonitor(
                this.whatsappBot,
                config.whatsapp.groupName,
                config.email
            );
            await this.emailMonitor.start();

            // Configurar handlers de encerramento
            this.setupGracefulShutdown();

            console.log('\n✅ Todos os serviços iniciados com sucesso!');
            console.log('📊 Status dos serviços:');
            console.log(`  📱 WhatsApp Bot: ${this.whatsappBot.isReady ? '✅ Conectado' : '⚠️ Aguardando'}`);
            console.log(`  🌐 Webhook Trello: ✅ Rodando na porta ${config.server.port}`);
            console.log(`  📨 Monitor Email: ${this.emailMonitor.isRunning ? '✅ Ativo' : '❌ Inativo'}`);
            console.log(`  👥 Grupo WhatsApp: "${config.whatsapp.groupName}"`);
            console.log(`  📧 Emails monitorados: ${config.email.targetEmails.join(', ')}`);

            console.log('\n📋 URLs importantes:');
            console.log(`  🔗 Webhook Trello: http://localhost:${config.server.port}/trello-webhook`);
            console.log(`  🧪 Teste manual: http://localhost:${config.server.port}/test-notification`);

            console.log('\n💡 Para testar, execute:');
            console.log(`curl -X POST http://localhost:${config.server.port}/test-notification -H "Content-Type: application/json" -d '{"message":"Sistema funcionando!"}'`);

        } catch (error) {
            console.error('❌ Erro ao iniciar servidor:', error);
            await this.stop();
            process.exit(1);
        }
    }

    async waitForWhatsAppReady() {
        return new Promise((resolve) => {
            if (this.whatsappBot.isReady) {
                resolve();
                return;
            }

            const checkReady = () => {
                if (this.whatsappBot.isReady) {
                    console.log('✅ WhatsApp conectado! Prosseguindo com outros serviços...');
                    resolve();
                } else {
                    setTimeout(checkReady, 1000);
                }
            };
            
            checkReady();
        });
    }

    setupGracefulShutdown() {
        const shutdown = async (signal) => {
            console.log(`\n⚠️ Recebido sinal ${signal}. Encerrando serviços...`);
            await this.stop();
            process.exit(0);
        };

        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));
        process.on('uncaughtException', (error) => {
            console.error('❌ Erro não capturado:', error);
            shutdown('uncaughtException');
        });
        process.on('unhandledRejection', (reason, promise) => {
            console.error('❌ Promise rejeitada não tratada:', reason);
            shutdown('unhandledRejection');
        });
    }

    async stop() {
        console.log('🛑 Parando serviços...');

        if (this.emailMonitor) {
            await this.emailMonitor.stop();
        }

        if (this.trelloWebhook) {
            this.trelloWebhook.stop();
        }

        if (this.whatsappBot) {
            await this.whatsappBot.destroy();
        }

        console.log('✅ Todos os serviços foram encerrados');
    }
}

// Iniciar servidor se este arquivo for executado diretamente
if (require.main === module) {
    const server = new NotificationServer();
    server.start();
}

module.exports = NotificationServer;