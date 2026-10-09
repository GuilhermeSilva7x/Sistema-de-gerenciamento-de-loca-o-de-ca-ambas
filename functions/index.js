const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const axios = require('axios');

admin.initializeApp();
const db = getFirestore();
const auth = getAuth();

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
        const { event, payment, subscription } = req.body;

        let customerId = null;
        let subscriptionId = null;
        let paymentValue = null;
        let paymentDesc = '';

        if (payment) {
            customerId = payment.customer;
            subscriptionId = payment.subscription;
            paymentValue = payment.value;
            paymentDesc = (payment.description || '').toLowerCase();
        } else if (subscription) {
            customerId = subscription.customer;
            subscriptionId = subscription.id;
            paymentValue = subscription.value;
            paymentDesc = (subscription.description || '').toLowerCase();
        }

        if (!customerId && !subscriptionId) {
            console.log('Sem dados de cliente ou assinatura no payload.');
            return res.status(200).send('OK (Sem dados relevantes)');
        }

        // Se tiver subscriptionId mas não tiver customerId, busca os detalhes da assinatura no Asaas
        if (!customerId && subscriptionId) {
            try {
                const subRes = await axios.get(`${ASAAS_API_URL}/subscriptions/${subscriptionId}`, {
                    headers: { access_token: ASAAS_API_KEY }
                });
                customerId = subRes.data?.customer;
            } catch (e) {
                console.error('Erro ao buscar assinatura no Asaas:', e.message);
            }
        }

        if (!customerId) {
            console.warn('Nenhum customerId encontrado para o evento:', event);
            return res.status(200).send('OK (Sem customerId)');
        }

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
            console.warn(`Nenhuma empresa encontrada com o email_admin: ${customerEmail}`);
            return res.status(200).send('Empresa não encontrada.');
        }

        const empresaDoc = empresasSnap.docs[0];
        const empresaId = empresaDoc.id;

        // 3. Define as ações com base no evento enviado pelo Asaas
        const eventosAtivacao = ['PAYMENT_CONFIRMED', 'PAYMENT_RECEIVED', 'PAYMENT_RESTORED'];
        const eventosBloqueio = [
            'PAYMENT_OVERDUE',
            'PAYMENT_DELETED',
            'PAYMENT_REFUNDED',
            'PAYMENT_CHARGEBACK_REQUESTED',
            'SUBSCRIPTION_DELETED',
            'SUBSCRIPTION_INACTIVATED'
        ];

        // Se for atualização de assinatura, verifica se o status dela ficou inativo ou deletado
        if (event === 'SUBSCRIPTION_UPDATED' && subscription) {
            if (subscription.status === 'INACTIVE' || subscription.deleted) {
                eventosBloqueio.push('SUBSCRIPTION_UPDATED');
            }
        }

        if (eventosAtivacao.includes(event)) {
            let limiteCacambas = 10; // Default Bronze
            const valor = paymentValue || 149.90;

            if (paymentDesc.includes('ouro') || valor >= 390.00) {
                limiteCacambas = 9999; // Ouro (R$ 399,90)
            } else if (paymentDesc.includes('prata') || valor >= 280.00) {
                limiteCacambas = 25; // Prata (R$ 289,90)
            } else {
                limiteCacambas = 10; // Bronze (R$ 149,90)
            }

            console.log(`Ativando plano da empresa ${empresaId}. Limite: ${limiteCacambas}. Valor: R$ ${valor}`);

            const newSubscriptionId = subscriptionId;
            const empresaData = empresaDoc.data();
            const oldSubscriptionId = empresaData.asaas_subscription_id;

            if (newSubscriptionId && oldSubscriptionId && oldSubscriptionId !== newSubscriptionId) {
                console.log(`Nova assinatura (${newSubscriptionId}) detectada. Cancelando anterior (${oldSubscriptionId}) no Asaas...`);
                try {
                    await axios.delete(`${ASAAS_API_URL}/subscriptions/${oldSubscriptionId}`, {
                        headers: { access_token: ASAAS_API_KEY }
                    });
                } catch (cancelError) {
                    console.error(`Erro ao cancelar assinatura antiga:`, cancelError.message);
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

// Endpoint para sincronização ativa do status da assinatura com a API do Asaas
exports.sincronizarAssinaturaAsaas = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(204).send('');
    }

    try {
        const email = (req.query.email || req.body?.email || '').trim().toLowerCase();
        const uid = (req.query.uid || req.body?.uid || '').trim();

        let empresaDoc = null;
        if (uid) {
            const doc = await db.collection('empresas').doc(uid).get();
            if (doc.exists) empresaDoc = doc;
        }
        if (!empresaDoc && email) {
            const snap = await db.collection('empresas').where('email_admin', '==', email).limit(1).get();
            if (!snap.empty) empresaDoc = snap.docs[0];
        }

        if (!empresaDoc) {
            return res.status(404).json({ error: 'Empresa não encontrada.' });
        }

        const empresaData = empresaDoc.data();
        const subId = empresaData.asaas_subscription_id;
        const customerId = empresaData.asaas_customer_id;

        if (!subId && !customerId) {
            return res.status(200).json({ status: empresaData.plano_status, synced: false, message: 'Sem assinatura Asaas vinculada.' });
        }

        let isAtivo = false;
        let novoLimite = empresaData.plano_limite || 10;

        if (subId) {
            try {
                const subRes = await axios.get(`${ASAAS_API_URL}/subscriptions/${subId}`, {
                    headers: { access_token: ASAAS_API_KEY }
                });
                const subData = subRes.data;
                console.log(`Consulta Asaas para assinatura ${subId}: status=${subData.status}, deleted=${subData.deleted}`);
                if (subData.status === 'ACTIVE' && !subData.deleted) {
                    isAtivo = true;
                }
            } catch (e) {
                console.warn('Erro ao consultar assinatura no Asaas:', e.message);
            }
        }

        const novoStatus = isAtivo ? 'ativo' : 'bloqueado';
        await empresaDoc.ref.update({
            plano_status: novoStatus,
            data_ultima_atualizacao: new Date().toISOString()
        });

        return res.status(200).json({
            success: true,
            status: novoStatus,
            plano_limite: novoLimite,
            subscription_id: subId
        });
    } catch (err) {
        console.error('Erro ao sincronizar Asaas:', err);
        return res.status(500).json({ error: err.message });
    }
});

// Trigger automática disparada quando um motorista é excluído do Firestore
exports.onMotoristaDelete = functions.firestore
    .document('motoristas/{motoristaId}')
    .onDelete(async (snap, context) => {
        const data = snap.data();
        if (!data) return null;

        const email = data.email ? data.email.trim().toLowerCase() : null;
        const authUid = data.auth_uid || null;

        console.log(`Trigger onMotoristaDelete acionada para motorista ID: ${snap.id}, email: ${email}, auth_uid: ${authUid}`);

        try {
            if (authUid) {
                try {
                    await auth.deleteUser(authUid);
                    console.log(`Usuário Auth deletado com sucesso pelo auth_uid: ${authUid}`);
                    return null;
                } catch (e) {
                    if (e.code !== 'auth/user-not-found') {
                        console.error(`Erro ao deletar Auth por auth_uid (${authUid}):`, e);
                    }
                }
            }

            if (email) {
                try {
                    const userRecord = await auth.getUserByEmail(email);
                    if (userRecord && userRecord.uid) {
                        await auth.deleteUser(userRecord.uid);
                        console.log(`Usuário Auth (${email}) deletado com sucesso pelo email: ${userRecord.uid}`);
                    }
                } catch (e) {
                    if (e.code !== 'auth/user-not-found') {
                        console.error(`Erro ao buscar/deletar usuário Auth por email (${email}):`, e);
                    }
                }
            }
        } catch (error) {
            console.error('Erro geral ao remover usuário no Firebase Auth:', error);
        }
        return null;
    });

// Endpoint HTTP com CORS para exclusão imediata de motorista no Firebase Auth
exports.excluirMotoristaAuth = functions.https.onRequest(async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        return res.status(204).send('');
    }

    try {
        const { email, auth_uid } = req.body || {};
        let deleted = false;

        if (auth_uid) {
            try {
                await auth.deleteUser(auth_uid);
                deleted = true;
                console.log(`Usuário Auth deletado via HTTP por auth_uid: ${auth_uid}`);
            } catch (e) {
                if (e.code !== 'auth/user-not-found') {
                    console.error('Erro HTTP ao deletar por auth_uid:', e);
                }
            }
        }

        if (!deleted && email) {
            try {
                const cleanEmail = email.trim().toLowerCase();
                const userRecord = await auth.getUserByEmail(cleanEmail);
                if (userRecord && userRecord.uid) {
                    await auth.deleteUser(userRecord.uid);
                    deleted = true;
                    console.log(`Usuário Auth deletado via HTTP por email: ${cleanEmail}`);
                }
            } catch (e) {
                if (e.code !== 'auth/user-not-found') {
                    console.error('Erro HTTP ao deletar por email:', e);
                }
            }
        }

        return res.status(200).json({ success: true, deleted });
    } catch (err) {
        console.error('Erro no endpoint excluirMotoristaAuth:', err);
        return res.status(500).json({ success: false, error: err.message });
    }
});
