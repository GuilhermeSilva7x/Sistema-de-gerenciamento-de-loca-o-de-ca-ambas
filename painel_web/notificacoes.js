// Sistema de Notificações, Modais e Alertas Modernos (SweetAlert2)
const Alerta = {
    // Toast rápido no canto superior direito
    toast: function (mensagem, tipo = 'success') {
        if (typeof Swal === 'undefined') {
            console.log(`[Toast ${tipo}]: ${mensagem}`);
            return;
        }
        const Toast = Swal.mixin({
            toast: true,
            position: 'top-end',
            showConfirmButton: false,
            timer: 3500,
            timerProgressBar: true,
            didOpen: (toast) => {
                toast.addEventListener('mouseenter', Swal.stopTimer);
                toast.addEventListener('mouseleave', Swal.resumeTimer);
            }
        });
        return Toast.fire({
            icon: tipo,
            title: mensagem
        });
    },

    // Alerta de Sucesso
    sucesso: function (mensagem, titulo = 'Sucesso!') {
        if (typeof Swal === 'undefined') {
            window.alert(`${titulo}\n\n${mensagem}`);
            return Promise.resolve();
        }
        return Swal.fire({
            icon: 'success',
            title: titulo,
            text: mensagem,
            confirmButtonText: 'OK',
            confirmButtonColor: '#10b981',
            customClass: {
                popup: 'swal2-custom-popup',
                confirmButton: 'swal2-btn-confirm'
            }
        });
    },

    // Alerta de Erro
    erro: function (mensagem, titulo = 'Ops, ocorreu um erro') {
        if (typeof Swal === 'undefined') {
            window.alert(`${titulo}\n\n${mensagem}`);
            return Promise.resolve();
        }
        return Swal.fire({
            icon: 'error',
            title: titulo,
            html: typeof mensagem === 'string' ? mensagem.replace(/\n/g, '<br>') : mensagem,
            confirmButtonText: 'Entendido',
            confirmButtonColor: '#ef4444',
            customClass: {
                popup: 'swal2-custom-popup',
                confirmButton: 'swal2-btn-danger'
            }
        });
    },

    // Alerta de Atenção / Validação
    aviso: function (mensagem, titulo = 'Atenção') {
        if (typeof Swal === 'undefined') {
            window.alert(`${titulo}\n\n${mensagem}`);
            return Promise.resolve();
        }
        return Swal.fire({
            icon: 'warning',
            title: titulo,
            html: typeof mensagem === 'string' ? mensagem.replace(/\n/g, '<br>') : mensagem,
            confirmButtonText: 'Ok, entendi',
            confirmButtonColor: '#f59e0b',
            customClass: {
                popup: 'swal2-custom-popup',
                confirmButton: 'swal2-btn-warning'
            }
        });
    },

    // Alerta de Informação
    info: function (mensagem, titulo = 'Informação') {
        if (typeof Swal === 'undefined') {
            window.alert(`${titulo}\n\n${mensagem}`);
            return Promise.resolve();
        }
        return Swal.fire({
            icon: 'info',
            title: titulo,
            html: typeof mensagem === 'string' ? mensagem.replace(/\n/g, '<br>') : mensagem,
            confirmButtonText: 'OK',
            confirmButtonColor: '#2563eb',
            customClass: {
                popup: 'swal2-custom-popup',
                confirmButton: 'swal2-btn-confirm'
            }
        });
    },

    // Modal de Confirmação interativo (retorna Promise<boolean>)
    confirmar: async function ({
        titulo = 'Tem certeza?',
        texto = 'Esta ação não poderá ser desfeita.',
        html = null,
        confirmText = 'Sim, confirmar',
        cancelText = 'Cancelar',
        icone = 'warning',
        perigo = true
    } = {}) {
        if (typeof Swal === 'undefined') {
            return window.confirm(`${titulo}\n\n${texto}`);
        }
        const result = await Swal.fire({
            title: titulo,
            text: html ? undefined : texto,
            html: html || undefined,
            icon: icone,
            showCancelButton: true,
            confirmButtonColor: perigo ? '#ef4444' : '#2563eb',
            cancelButtonColor: '#64748b',
            confirmButtonText: confirmText,
            cancelButtonText: cancelText,
            reverseButtons: true,
            focusCancel: perigo,
            customClass: {
                popup: 'swal2-custom-popup',
                confirmButton: perigo ? 'swal2-btn-danger' : 'swal2-btn-confirm',
                cancelButton: 'swal2-btn-cancel'
            }
        });
        return result.isConfirmed;
    },

    // Modal de Detalhes da Caçamba (substitui alert(info) da tela de Caçambas)
    detalhesCacamba: function (data, locacao = null) {
        if (typeof Swal === 'undefined') {
            return;
        }

        let statusText = 'Disponível';
        let statusBadgeBg = '#dcfce7';
        let statusColor = '#16a34a';

        if (data.status === 'em_uso' || data.status === 'na_obra') {
            statusText = 'Em Uso / Na Obra';
            statusBadgeBg = '#dbeafe';
            statusColor = '#2563eb';
        } else if (data.status === 'aguardando_retirada' || data.status === 'retirada_pendente') {
            statusText = 'Aguardando Retirada';
            statusBadgeBg = '#fee2e2';
            statusColor = '#dc2626';
        } else if (data.status === 'aguardando_troca' || data.status === 'troca_pendente') {
            statusText = 'Aguardando Troca';
            statusBadgeBg = '#fef3c7';
            statusColor = '#d97706';
        } else if (data.status === 'manutencao') {
            statusText = 'Em Manutenção';
            statusBadgeBg = '#fee2e2';
            statusColor = '#b91c1c';
        }

        let locacaoHtml = '';
        if (locacao) {
            const rua = locacao.endereco?.rua || '';
            const num = locacao.endereco?.numero || '';
            const bairro = locacao.endereco?.bairro || '';
            const dataEntrega = locacao.data_entrega ? locacao.data_entrega.split('-').reverse().join('/') : '-';
            const dataRetirada = locacao.data_retirada ? locacao.data_retirada.split('-').reverse().join('/') : '-';

            locacaoHtml = `
                <div style="margin-top: 15px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; text-align: left; font-size: 13px;">
                    <div style="font-weight: 700; color: #1e293b; margin-bottom: 8px; font-size: 14px;">Locação Ativa</div>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; color: #475569;">
                        <div><strong>OS:</strong> <span style="color: #2563eb; font-weight: 600;">${locacao.os_numero || '-'}</span></div>
                        <div><strong>Cliente:</strong> ${locacao.cliente_nome || '-'}</div>
                        <div style="grid-column: span 2;"><strong>Endereço:</strong> ${rua}, ${num} ${bairro ? `(${bairro})` : ''}</div>
                        <div><strong>Entrega:</strong> ${dataEntrega}</div>
                        <div><strong>Retirada:</strong> ${dataRetirada}</div>
                        <div><strong>Motorista:</strong> ${locacao.motorista_nome || '-'}</div>
                        <div><strong>Pagamento:</strong> <span style="font-weight: 600; color: ${locacao.pagamento_status === 'Pago' ? '#16a34a' : '#ea580c'};">${locacao.pagamento_status || 'Pendente'}</span></div>
                    </div>
                </div>
            `;
        } else {
            locacaoHtml = `
                <div style="margin-top: 15px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 10px; color: #166534; font-size: 13px; font-weight: 500;">
                    Caçamba disponível no pátio, pronta para nova locação.
                </div>
            `;
        }

        const html = `
            <div style="text-align: center; padding: 5px;">
                <div style="display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 700; background: ${statusBadgeBg}; color: ${statusColor}; margin-bottom: 15px;">
                    ${statusText}
                </div>
                <div style="display: flex; justify-content: center; gap: 20px; margin-bottom: 10px; font-size: 14px; color: #334155;">
                    <div><strong>Número:</strong> <span style="color: #0f172a; font-weight: bold;">${data.numero || '-'}</span></div>
                    <div><strong>Capacidade:</strong> <span style="color: #0f172a; font-weight: bold;">${data.tamanho || '-'} m³</span></div>
                </div>
                ${locacaoHtml}
            </div>
        `;

        return Swal.fire({
            title: `Caçamba Nº ${data.numero || ''}`,
            html: html,
            confirmButtonText: 'Fechar',
            confirmButtonColor: '#2563eb',
            customClass: {
                popup: 'swal2-custom-popup'
            }
        });
    }
};

// Override seguro do window.alert caso alguma chamada nativa ainda aconteça
window.alert = function (msg) {
    if (typeof Alerta !== 'undefined' && typeof Swal !== 'undefined') {
        const texto = String(msg || '');
        if (texto.toLowerCase().includes('sucesso') || texto.toLowerCase().includes('concluíd') || texto.toLowerCase().includes('atualizado com sucesso')) {
            Alerta.sucesso(texto);
        } else if (texto.toLowerCase().includes('erro') || texto.toLowerCase().includes('falha') || texto.toLowerCase().includes('negado')) {
            Alerta.erro(texto);
        } else {
            Alerta.aviso(texto);
        }
    } else {
        console.warn("[Alert]", msg);
    }
};

// ==========================================================================
// INICIALIZAÇÃO AUTOMÁTICA DO MENU MOBILE RESPONSIVO (DRAWER)
// ==========================================================================
(function initMenuMobile() {
    function setupMobileMenu() {
        const barraLateral = document.querySelector('.barra-lateral');
        const cabecalho = document.getElementById('cabecalho-principal') || document.querySelector('.cabecalho-principal');

        if (!barraLateral || !cabecalho) return;

        // Cria o Overlay escuro de fundo se não existir
        let overlay = document.getElementById('menuOverlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = 'menuOverlay';
            overlay.className = 'menu-overlay';
            document.body.appendChild(overlay);
        }

        // Cria o botão de menu hambúrguer no cabeçalho se não existir
        let btnMenu = document.getElementById('btnMenuMobile');
        if (!btnMenu) {
            btnMenu = document.createElement('button');
            btnMenu.id = 'btnMenuMobile';
            btnMenu.className = 'btn-menu-mobile';
            btnMenu.type = 'button';
            btnMenu.setAttribute('aria-label', 'Abrir Menu');
            btnMenu.innerHTML = `
                <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="3" y1="12" x2="21" y2="12"></line>
                    <line x1="3" y1="6" x2="21" y2="6"></line>
                    <line x1="3" y1="18" x2="21" y2="18"></line>
                </svg>
            `;

            // Insere como primeiro elemento do cabeçalho
            if (cabecalho.firstChild) {
                cabecalho.insertBefore(btnMenu, cabecalho.firstChild);
            } else {
                cabecalho.appendChild(btnMenu);
            }
        }

        function abrirMenu() {
            barraLateral.classList.add('aberta');
            overlay.classList.add('ativo');
            document.body.classList.add('menu-aberto-bloqueio');
        }

        function fecharMenu() {
            barraLateral.classList.remove('aberta');
            overlay.classList.remove('ativo');
            document.body.classList.remove('menu-aberto-bloqueio');
        }

        // Eventos
        btnMenu.onclick = function (e) {
            e.stopPropagation();
            if (barraLateral.classList.contains('aberta')) {
                fecharMenu();
            } else {
                abrirMenu();
            }
        };

        overlay.onclick = fecharMenu;

        // Fecha ao clicar em qualquer item do menu
        const linksMenu = barraLateral.querySelectorAll('.menu-lateral a');
        linksMenu.forEach(link => {
            link.addEventListener('click', () => {
                if (window.innerWidth <= 992) {
                    fecharMenu();
                }
            });
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', setupMobileMenu);
    } else {
        setupMobileMenu();
    }
})();

