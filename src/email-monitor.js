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
        this.processedEmails = new Set(); // Cache de emails já processados
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
                bodies: ['HEADER.FIELDS (FROM TO CC BCC SUBJECT DATE MESSAGE-ID)', 'TEXT'],
                markSeen: true
            };

            const results = await this.connection.search(searchCriteria, fetchOptions);

            console.log(`📧 Encontrados ${results.length} emails não lidos`);

            for (const result of results) {
                const header = result.parts.find(part => part.which === 'HEADER.FIELDS (FROM TO CC BCC SUBJECT DATE MESSAGE-ID)');
                const body = result.parts.find(part => part.which === 'TEXT');

                if (!header) {
                    console.log('⚠️ Email sem header, pulando...');
                    continue;
                }

                const headerBody = header.body;
                const subject = headerBody.subject ? headerBody.subject[0] : 'Sem assunto';
                const date = headerBody.date ? headerBody.date[0] : '';
                const messageId = headerBody['message-id'] ? headerBody['message-id'][0] : '';
                const emailBody = body ? body.body : '';

                // Extrair endereços de email de todos os campos
                const from = this.extractEmailAddress(headerBody.from);
                const to = headerBody.to ? headerBody.to.map(e => this.extractEmailAddress([e])).join(', ') : '';
                const cc = headerBody.cc ? headerBody.cc.map(e => this.extractEmailAddress([e])).join(', ') : '';
                const bcc = headerBody.bcc ? headerBody.bcc.map(e => this.extractEmailAddress([e])).join(', ') : '';

                console.log(`\n📧 ========== EMAIL RECEBIDO ==========`);
                console.log(`📨 FROM: ${from}`);
                console.log(`👤 TO: ${to || '(vazio)'}`);
                console.log(`📋 CC: ${cc || '(vazio)'}`);
                console.log(`🔒 BCC: ${bcc || '(vazio)'}`);
                console.log(`📝 ASSUNTO: ${subject}`);
                console.log(`🆔 MESSAGE-ID: ${messageId}`);

                // Evitar processar emails duplicados
                if (messageId && this.processedEmails.has(messageId)) {
                    console.log(`⏭️ Email já processado (Message-ID: ${messageId}), pulando...`);
                    console.log(`========================================\n`);
                    continue;
                }

                if (this.shouldNotifyEmail(headerBody)) {
                    await this.sendEmailNotification(from, subject, date, emailBody);

                    // Marcar email como processado
                    if (messageId) {
                        this.processedEmails.add(messageId);

                        // Limitar cache a 1000 emails para evitar crescimento infinito
                        if (this.processedEmails.size > 1000) {
                            const firstItem = this.processedEmails.values().next().value;
                            this.processedEmails.delete(firstItem);
                        }
                    }
                } else {
                    console.log(`❌ Nenhum email monitorado encontrado em FROM/TO/CC/BCC`);
                }
                console.log(`========================================\n`);
            }
        } catch (error) {
            console.error('❌ Erro ao verificar emails:', error);
        }
    }

    extractEmailAddress(emailField) {
        if (!emailField || emailField.length === 0) return '';

        const firstEmail = emailField[0];

        // Se for objeto com address (formato padrão IMAP)
        if (typeof firstEmail === 'object' && firstEmail !== null) {
            if (firstEmail.address) {
                return firstEmail.address.toLowerCase();
            }
            // Fallback: converter objeto para string
            return String(firstEmail).toLowerCase();
        }

        // Se for string
        if (typeof firstEmail === 'string') {
            // Extrair email de formatos como "Name <email@domain.com>"
            const match = firstEmail.match(/<(.+?)>/) || firstEmail.match(/([^\s]+@[^\s]+)/);
            return match ? match[1].toLowerCase() : firstEmail.toLowerCase();
        }

        return String(firstEmail).toLowerCase();
    }

    isTargetEmail(emailAddress, targetEmails) {
        if (!emailAddress) return false;

        return targetEmails.some(targetEmail => {
            const target = targetEmail.toLowerCase().trim();
            const address = emailAddress.toLowerCase().trim();

            // Match exato ou contém
            return address === target || address.includes(target);
        });
    }

    shouldNotifyEmail(headerBody) {
        const targetEmails = this.emailConfig.targetEmails || ['exemplo@empresa.com.br'];

        // Verificar FROM, TO, CC, BCC
        const fields = ['from', 'to', 'cc', 'bcc'];

        for (const field of fields) {
            if (headerBody[field] && Array.isArray(headerBody[field])) {
                for (const emailEntry of headerBody[field]) {
                    const address = this.extractEmailAddress([emailEntry]);
                    if (this.isTargetEmail(address, targetEmails)) {
                        console.log(`✅ Email monitorado encontrado no campo ${field.toUpperCase()}: ${address}`);
                        return true;
                    }
                }
            }
        }

        return false;
    }

    extractTicketId(emailBody, subject) {
        // Tentar extrair ticket ID do corpo do email
        // Padrões possíveis:
        // 1. "solicitação de suporte 24596457"
        // 2. "solicitação de suporte [24596457]"
        // 3. Números de 8 dígitos no corpo

        const patterns = [
            /solicita[çc][ãa]o de suporte\s+\[?(\d{8})\]?/i,
            /ticket[:\s#]+(\d{8})/i,
            /chamado[:\s#]+(\d{8})/i,
            /protocolo[:\s#]+(\d{8})/i,
            /\[(\d{8})\]/,
            /\b(\d{8})\b/ // Qualquer número de 8 dígitos
        ];

        // Tentar no corpo do email primeiro
        for (const pattern of patterns) {
            const match = emailBody.match(pattern);
            if (match && match[1]) {
                console.log(`🎯 Ticket ID encontrado no corpo: ${match[1]}`);
                return match[1];
            }
        }

        // Tentar no assunto como fallback
        for (const pattern of patterns) {
            const match = subject.match(pattern);
            if (match && match[1]) {
                console.log(`🎯 Ticket ID encontrado no assunto: ${match[1]}`);
                return match[1];
            }
        }

        console.log('⚠️ Ticket ID não encontrado no email');
        return null;
    }

    async sendEmailNotification(from, subject, date, emailBody) {
        try {
            // Extrair ticket ID do email
            const ticketId = this.extractTicketId(emailBody, subject);

            let message = `📧 *NOVO EMAIL TOTVS*

📨 *De:* ${from}
📝 *Assunto:* ${subject}
📅 *Data:* ${new Date(date).toLocaleString('pt-BR', {timeZone: 'America/Sao_Paulo'})}`;

            // Adicionar informações do ticket se encontrado
            if (ticketId) {
                const ticketUrl = `https://suporte.totvs.com/portal/p/10098/customer-portal-dashboard/tickets/details/${ticketId}`;
                message += `

🎫 *Chamado:* #${ticketId}
🔗 *Link:* ${ticketUrl}`;
            }

            message += `

⏰ ${new Date().toLocaleString('pt-BR', {timeZone: 'America/Sao_Paulo'})}`;

            await this.whatsappBot.sendMessageToGroup(this.groupName, message);
            console.log(`✅ Notificação enviada para email de: ${from}${ticketId ? ` | Ticket: ${ticketId}` : ''}`);
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