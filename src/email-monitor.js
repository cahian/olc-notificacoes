const imaps = require('imap-simple');

class EmailMonitor {
    constructor(whatsappBot, groupName, emailConfig) {
        this.whatsappBot = whatsappBot;
        this.groupName = groupName;
        this.emailConfig = emailConfig;
        this.connection = null;
        this.isRunning = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
    }

    async start() {
        try {
            console.log('📨 Iniciando monitor de emails...');
            await this.connect();
            this.setupEventHandlers();
            this.isRunning = true;
            console.log('✅ Monitor de emails ativo!');
        } catch (error) {
            console.error('❌ Erro ao iniciar monitor de emails:', error);
            this.scheduleReconnect();
        }
    }

    async connect() {
        const config = {
            imap: {
                user: this.emailConfig.user,
                password: this.emailConfig.password,
                host: this.emailConfig.host || 'imap.gmail.com',
                port: this.emailConfig.port || 993,
                tls: this.emailConfig.tls !== false,
                authTimeout: this.emailConfig.authTimeout || 10000,
                connTimeout: this.emailConfig.connTimeout || 10000
            }
        };

        this.connection = await imaps.connect(config);
        await this.connection.openBox('INBOX');
        this.reconnectAttempts = 0;
        console.log('✅ Conectado ao servidor de email');
    }

    setupEventHandlers() {
        this.connection.on('mail', async (numNewMsgs) => {
            console.log(`📧 ${numNewMsgs} novo(s) email(s) recebido(s)`);
            await this.checkNewEmails();
        });

        this.connection.on('close', () => {
            console.log('⚠️ Conexão com email fechada');
            if (this.isRunning) {
                this.scheduleReconnect();
            }
        });

        this.connection.on('error', (error) => {
            console.error('❌ Erro na conexão de email:', error);
            if (this.isRunning) {
                this.scheduleReconnect();
            }
        });
    }

    async checkNewEmails() {
        try {
            const searchCriteria = ['UNSEEN'];
            const fetchOptions = {
                bodies: ['HEADER.FIELDS (FROM SUBJECT DATE)'],
                markSeen: true
            };

            const results = await this.connection.search(searchCriteria, fetchOptions);

            for (const result of results) {
                const header = result.parts[0].body;
                const from = header.from ? header.from[0] : '';
                const subject = header.subject ? header.subject[0] : 'Sem assunto';
                const date = header.date ? header.date[0] : '';

                console.log(`📧 Verificando email de: ${from}`);

                if (this.shouldNotifyEmail(from)) {
                    await this.sendEmailNotification(from, subject, date);
                }
            }
        } catch (error) {
            console.error('❌ Erro ao verificar emails:', error);
        }
    }

    shouldNotifyEmail(from) {
        const targetEmails = this.emailConfig.targetEmails || ['atendimento.totvs@totvs.com.br'];
        
        return targetEmails.some(email => 
            from.toLowerCase().includes(email.toLowerCase())
        );
    }

    async sendEmailNotification(from, subject, date) {
        try {
            const message = `📧 *NOVO EMAIL IMPORTANTE*

📨 *De:* ${from}
📝 *Assunto:* ${subject}
📅 *Data:* ${new Date(date).toLocaleString('pt-BR')}

⚠️ Email de remetente monitorado recebido!

⏰ ${new Date().toLocaleString('pt-BR')}`;

            await this.whatsappBot.sendMessageToGroup(this.groupName, message);
            console.log(`✅ Notificação enviada para email de: ${from}`);
        } catch (error) {
            console.error('❌ Erro ao enviar notificação de email:', error);
        }
    }

    scheduleReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('❌ Máximo de tentativas de reconexão atingido');
            return;
        }

        const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 60000); // Max 1 minuto
        this.reconnectAttempts++;

        console.log(`🔄 Tentando reconectar em ${delay/1000}s (tentativa ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

        setTimeout(async () => {
            try {
                if (this.connection) {
                    this.connection.end();
                }
                await this.connect();
                this.setupEventHandlers();
            } catch (error) {
                console.error('❌ Falha na reconexão:', error);
                this.scheduleReconnect();
            }
        }, delay);
    }

    async stop() {
        this.isRunning = false;
        if (this.connection) {
            this.connection.end();
            this.connection = null;
        }
        console.log('🛑 Monitor de emails parado');
    }

    // Método para testar manualmente
    async testEmailConnection() {
        try {
            console.log('🧪 Testando conexão de email...');
            await this.connect();
            console.log('✅ Conexão de email testada com sucesso!');
            this.connection.end();
            return true;
        } catch (error) {
            console.error('❌ Erro no teste de email:', error);
            return false;
        }
    }
}

module.exports = EmailMonitor;