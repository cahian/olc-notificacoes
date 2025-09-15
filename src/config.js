require('dotenv').config();

const config = {
    // Configurações do WhatsApp
    whatsapp: {
        groupName: process.env.WHATSAPP_GROUP_NAME || 'GRUPO DE NOTIFICAÇÕES'
    },

    // Configurações do servidor
    server: {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development'
    },

    // Configurações de email
    email: {
        user: process.env.EMAIL_USER,
        password: process.env.EMAIL_PASSWORD,
        host: process.env.EMAIL_HOST || 'imap.gmail.com',
        port: parseInt(process.env.EMAIL_PORT) || 993,
        tls: process.env.EMAIL_TLS !== 'false',
        authTimeout: 10000,
        connTimeout: 10000,
        targetEmails: process.env.TARGET_EMAILS 
            ? process.env.TARGET_EMAILS.split(',').map(email => email.trim())
            : ['atendimento.totvs@totvs.com.br']
    },

    // Configurações do Trello
    trello: {
        boardUrl: process.env.TRELLO_BOARD_URL || 'https://trello.com/b/UWvlgBP4/unimed-de-monte-alto'
    },

    // Configurações de log
    log: {
        level: process.env.LOG_LEVEL || 'info'
    }
};

// Validação de configurações obrigatórias
function validateConfig() {
    const errors = [];

    if (!config.email.user) {
        errors.push('EMAIL_USER é obrigatório');
    }

    if (!config.email.password) {
        errors.push('EMAIL_PASSWORD é obrigatório');
    }

    if (errors.length > 0) {
        console.error('❌ Erros de configuração:');
        errors.forEach(error => console.error(`  - ${error}`));
        console.error('\n💡 Dica: Copie o arquivo .env.example para .env e configure as variáveis necessárias');
        process.exit(1);
    }
}

module.exports = {
    config,
    validateConfig
};