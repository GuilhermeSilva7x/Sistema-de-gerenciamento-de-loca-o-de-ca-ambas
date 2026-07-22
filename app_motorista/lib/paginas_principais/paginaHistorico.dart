import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Paginahistorico extends StatelessWidget {
  const Paginahistorico({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text(
          "Histórico de Atividades",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Busca o perfil do motorista pelo email para obter o ID
        stream: FirebaseFirestore.instance
            .collection('motoristas')
            .where('email', isEqualTo: user?.email)
            .snapshots(),
        builder: (context, motoristaSnapshot) {
          if (motoristaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (motoristaSnapshot.hasError || !motoristaSnapshot.hasData || motoristaSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Motorista não cadastrado no painel administrativo.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final motoristaId = motoristaSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            // 2. Busca todas as locações do motorista
            stream: FirebaseFirestore.instance
                .collection('locacoes')
                .where('motorista_id', isEqualTo: motoristaId)
                .snapshots(),
            builder: (context, locacoesSnapshot) {
              if (locacoesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (locacoesSnapshot.hasError) {
                return Center(child: Text("Erro ao carregar histórico: ${locacoesSnapshot.error}"));
              }

              // Filtra apenas as atividades concluídas (entregas na obra ou retirada finalizada)
              final docs = (locacoesSnapshot.data?.docs ?? []).where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                return status == 'concluida' || status == 'na_obra';
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Nenhuma atividade concluída no histórico.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  
                   final String tipoServico = data['tipo_servico'] ??
                       (data['pagamento_forma'] == 'Sem Custo (Retirada)' ? 'retirada' : 'entrega');

                   Color cor = Colors.blue;
                   String atividadeTexto = "ENTREGA";
                   
                   if (tipoServico == 'troca') {
                     cor = Colors.orange;
                     atividadeTexto = "TROCA";
                   } else if (tipoServico == 'retirada') {
                     cor = Colors.red;
                     atividadeTexto = "RETIRADA";
                   }

                  final rua = data['endereco']?['rua'] ?? '';
                  final num = data['endereco']?['numero'] ?? '';
                  final bairro = data['endereco']?['bairro'] ?? '';

                  return Column(
                    children: [
                      CardsAtividades(
                        id: id,
                        atividade: atividadeTexto,
                        cor: cor,
                        concluido: true,
                        clienteNome: data['cliente_nome'] ?? '-',
                        endereco: "$rua, $num - $bairro",
                        cacambaNumero: data['cacamba_numero'] ?? '-',
                        cacambaId: data['cacamba_id'] ?? '',
                        hora: "Finalizado",
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Paginadenavegacao(index: 2),
    );
  }
}
