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
