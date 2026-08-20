const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// Carrega as chaves a partir de variáveis de ambiente locais (.env) para segurança
const MP_ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN;

exports.webhookMercadoPago = functions.https.onRequest(async (req, res) => {
    if (req.method !== 'POST') {
        return res.status(405).send('Método não permitido');
    }

    console.log('Notificação Webhook recebida:', JSON.stringify(req.body));

    try {
        // O Mercado Pago envia notificações de assinatura (preapproval) de duas formas:
        // 1. Através de "type": "subscription_preapproval"
        // 2. Ou através de "resource" com formato /v1/preapprovals/...
        const { type, data, resource } = req.body;

        let preapprovalId = null;

        if (type === 'subscription_preapproval' && data && data.id) {
            preapprovalId = data.id;
        } else if (resource && resource.includes('/preapprovals/')) {
            const parts = resource.split('/');
            preapprovalId = parts[parts.length - 1];
        } else if (req.body.id && req.body.topic === 'preapproval') {
            preapprovalId = req.body.id;
        }

        if (!preapprovalId) {
            console.log('Não foi possível extrair o ID da assinatura do corpo:', JSON.stringify(req.body));
            return res.status(200).send('Notificação recebida, mas sem ID de assinatura compatível.');
        }

        console.log(`Buscando detalhes da assinatura ID: ${preapprovalId}`);

        // Busca os dados atualizados da assinatura diretamente na API do Mercado Pago
        const response = await axios.get(`https://api.mercadopago.com/preapproval/${preapprovalId}`, {
            headers: {
                Authorization: `Bearer ${MP_ACCESS_TOKEN}`
            }
        });

        const subscription = response.data;
        console.log('Retorno detalhado da assinatura:', JSON.stringify(subscription));

        const uid = subscription.external_reference;
        const status = subscription.status; // 'authorized' = ativo, 'paused' = pausado, 'cancelled' = cancelado
        const planId = subscription.preapproval_plan_id; // ID do plano assinado

        if (!uid) {
            console.warn(`Nenhum external_reference (UID do admin) encontrado na assinatura ${preapprovalId}.`);
            return res.status(200).send('Nenhum external_reference encontrado.');
        }

        // Traduz o ID do plano do Mercado Pago para o limite de caçambas no Firestore
        // Dica: Configure com os IDs reais gerados no seu painel do Mercado Pago
        let limiteCacambas = 10; // Default Bronze
        
        if (planId === '2d1bb1263aaf46d4be3a78e791fff09f') { // Plano Bronze (149,90)
            limiteCacambas = 10;
        } else if (planId === '2a116e07fc474fdcaa8b49e34efef703') { // Plano Prata (289,90)
            limiteCacambas = 25;
        } else if (planId === 'c5a0ba882e6e401ba6e9b8a0042701ad') { // Plano Ouro (399,90)
            limiteCacambas = 9999;
        }

        // 'authorized' indica assinatura ativa e paga no Mercado Pago
        const novoStatus = (status === 'authorized') ? 'ativo' : 'bloqueado';

        console.log(`Atualizando empresa UID: ${uid} -> status: ${novoStatus}, limite: ${limiteCacambas}`);

        await db.collection('empresas').doc(uid).update({
            plano_status: novoStatus,
            plano_limite: limiteCacambas,
            subscription_id: preapprovalId,
            data_ultima_atualizacao: new Date().toISOString()
        });

        return res.status(200).send('Webhook processado e status atualizado com sucesso.');
    } catch (error) {
        console.error('Erro ao processar Webhook:', error.message);
        if (error.response && error.response.data) {
            console.error('Erro retornado pela API do MP:', JSON.stringify(error.response.data));
        }
        return res.status(500).send('Erro interno do servidor');
    }
});

// Integração de Faturamento e Assinaturas com o Asaas
const ASAAS_API_KEY = process.env.ASAAS_API_KEY;
const ASAAS_API_URL = process.env.ASAAS_API_URL || 'https://www.asaas.com/api/v3';

exports.webhookAsaas = functions.https.onRequest(async (req, res) => {
    // É uma boa prática responder 200 de forma rápida para o Asaas não achar que falhou
    if (req.method !== 'POST') {
        return res.status(405).send('Método não permitido');
    }

    console.log('Webhook Asaas recebido:', JSON.stringify(req.body));

    try {
        const { event, payment } = req.body;

        if (!payment || !payment.customer) {
            console.log('Sem dados de pagamento ou cliente no payload.');
            return res.status(200).send('OK (Sem dados relevantes)');
        }

        const customerId = payment.customer;

        // 1. Consulta os detalhes do cliente no Asaas para pegar o e-mail cadastrado
        console.log(`Buscando dados do cliente ${customerId} no Asaas...`);
        const customerResponse = await axios.get(`${ASAAS_API_URL}/customers/${customerId}`, {
            headers: {
                access_token: ASAAS_API_KEY
            }
        });

        const customer = customerResponse.data;
        const customerEmail = customer.email ? customer.email.trim().toLowerCase() : null;

        if (!customerEmail) {
            console.warn(`Cliente ${customerId} não possui e-mail cadastrado.`);
            return res.status(200).send('Cliente sem e-mail.');
        }

        console.log(`E-mail do cliente Asaas: ${customerEmail}`);

        // 2. Busca a empresa correspondente no Firestore usando o e-mail do administrador
        const empresasSnap = await db.collection('empresas')
            .where('email_admin', '==', customerEmail)
            .limit(1)
            .get();

        if (empresasSnap.empty) {
            // Se o e-mail de cadastro no Asaas for diferente do e-mail do admin no sistema, tenta buscar pelo e-mail comum de login secundário ou avisa
            console.warn(`Nenhuma empresa encontrada com o email_admin: ${customerEmail}`);
            return res.status(200).send('Empresa não encontrada.');
        }

        const empresaDoc = empresasSnap.docs[0];
        const empresaId = empresaDoc.id;

        // 3. Define as ações com base no evento enviado pelo Asaas
        // Eventos de ativação de pagamento
        const eventosAtivacao = ['PAYMENT_CONFIRMED', 'PAYMENT_RECEIVED'];
        // Eventos de bloqueio / inadimplência / cancelamento
        const eventosBloqueio = ['PAYMENT_OVERDUE', 'PAYMENT_DELETED', 'PAYMENT_REFUNDED', 'PAYMENT_CHARGEBACK_REQUESTED'];

        if (eventosAtivacao.includes(event)) {
            const valor = payment.value;
            const descricao = payment.description ? payment.description.toLowerCase() : '';
            let limiteCacambas = 10; // Default Bronze

            // Mapeia o limite de caçambas com base na descrição ou faixa de valor pago
            if (descricao.includes('ouro') || valor >= 390.00) {
                limiteCacambas = 9999; // Ouro (R$ 399,90)
            } else if (descricao.includes('prata') || valor >= 280.00) {
                limiteCacambas = 25; // Prata (R$ 289,90)
            } else {
                limiteCacambas = 10; // Bronze (R$ 149,90)
            }

            console.log(`Ativando plano da empresa ${empresaId}. Limite: ${limiteCacambas}. Valor pago: R$ ${valor}`);

            const newSubscriptionId = payment.subscription;
            const empresaData = empresaDoc.data();
            const oldSubscriptionId = empresaData.asaas_subscription_id;

            // Se o usuário já tinha uma assinatura ativa diferente da nova, cancela a antiga no Asaas automaticamente para evitar cobrança dupla
            if (newSubscriptionId && oldSubscriptionId && oldSubscriptionId !== newSubscriptionId) {
                console.log(`Nova assinatura (${newSubscriptionId}) detectada. Cancelando assinatura antiga (${oldSubscriptionId}) no Asaas...`);
                try {
                    await axios.delete(`${ASAAS_API_URL}/subscriptions/${oldSubscriptionId}`, {
                        headers: {
                            access_token: ASAAS_API_KEY
                        }
                    });
                    console.log(`Assinatura antiga ${oldSubscriptionId} cancelada com sucesso.`);
                } catch (cancelError) {
                    console.error(`Erro ao cancelar assinatura antiga ${oldSubscriptionId}:`, cancelError.message);
                }
            }

            await db.collection('empresas').doc(empresaId).update({
                plano_status: 'ativo',
                plano_limite: limiteCacambas,
                gateway: 'asaas',
                asaas_customer_id: customerId,
                asaas_subscription_id: newSubscriptionId || oldSubscriptionId || null,
                data_ultima_atualizacao: new Date().toISOString()
            });

        } else if (eventosBloqueio.includes(event)) {
            console.log(`Bloqueando plano da empresa ${empresaId} devido ao evento Asaas: ${event}`);

            await db.collection('empresas').doc(empresaId).update({
                plano_status: 'bloqueado',
                data_ultima_atualizacao: new Date().toISOString()
            });
        }

        return res.status(200).send('Webhook Asaas processado com sucesso.');

    } catch (error) {
        console.error('Erro ao processar Webhook Asaas:', error.message);
        if (error.response && error.response.data) {
            console.error('Erro retornado pela API do Asaas:', JSON.stringify(error.response.data));
        }
        return res.status(500).send('Erro interno do servidor');
    }
});
