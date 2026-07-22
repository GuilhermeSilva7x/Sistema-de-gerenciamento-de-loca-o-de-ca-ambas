import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Paginaatividades extends StatelessWidget {
  const Paginaatividades({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text(
          "Atividades do dia",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Busca o perfil do motorista pelo email cadastrado
        stream: FirebaseFirestore.instance
            .collection('motoristas')
            .where('email', isEqualTo: user?.email)
            .snapshots(),
        builder: (context, motoristaSnapshot) {
          if (motoristaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (motoristaSnapshot.hasError) {
            return Center(child: Text("Erro ao carregar perfil: ${motoristaSnapshot.error}"));
          }

          if (!motoristaSnapshot.hasData || motoristaSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Motorista não cadastrado no painel administrativo com este e-mail.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final motoristaId = motoristaSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            // Lista todas as locações associadas a este motorista
            stream: FirebaseFirestore.instance
                .collection('locacoes')
                .where('motorista_id', isEqualTo: motoristaId)
                .snapshots(),
            builder: (context, locacoesSnapshot) {
              if (locacoesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (locacoesSnapshot.hasError) {
                return Center(child: Text("Erro ao carregar atividades: ${locacoesSnapshot.error}"));
              }

              final todayStr = DateTime.now().toIso8601String().split('T')[0];
              final allDocs = locacoesSnapshot.data?.docs ?? [];
              final activeDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                final isPending = status == 'entrega_pendente' ||
                       status == 'troca_pendente' ||
                       status == 'retirada_pendente' ||
                       status == 'aguardando_troca' ||
                       status == 'aguardando_retirada';

                if (!isPending) return false;

                // Não mostra atividades agendadas para datas futuras
                final dataEntrega = data['data_entrega'] ?? '';
                if (dataEntrega.isNotEmpty) {
                  try {
                    final parts = dataEntrega.split('-');
                    if (parts.length == 3) {
                      final year = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final day = int.parse(parts[2]);
                      final scheduledDate = DateTime(year, month, day);
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      if (scheduledDate.isAfter(today)) {
                        return false;
                      }
                    }
                  } catch (e) {
                    if (dataEntrega.compareTo(todayStr) > 0) {
                      return false;
                    }
                  }
                }
                return true;
              }).toList();

              if (activeDocs.isEmpty) {
                return const Center(
                  child: Text(
                    "Nenhuma atividade pendente para hoje.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Cria uma lista mutável e ordena por hora_entrega de forma crescente (Time-Ascending)
              final sortedDocs = List<QueryDocumentSnapshot>.from(activeDocs);
              sortedDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aHora = aData['hora_entrega'] ?? '08:00';
                final bHora = bData['hora_entrega'] ?? '08:00';
                return aHora.compareTo(bHora);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  final data = sortedDocs[index].data() as Map<String, dynamic>;
                  final id = sortedDocs[index].id;
                  
                  final String status = data['status'] ?? 'entrega_pendente';

                  Color cor = Colors.blue;
                  String atividadeTexto = "ENTREGA";
                  
                  if (status == 'troca_pendente' || status == 'aguardando_troca') {
                    cor = Colors.orange;
                    atividadeTexto = "TROCA";
                  } else if (status == 'retirada_pendente' || status == 'aguardando_retirada') {
                    cor = Colors.red;
                    atividadeTexto = "RETIRADA";
                  }

                  final rua = data['endereco']?['rua'] ?? '';
                  final num = data['endereco']?['numero'] ?? '';
                  final bairro = data['endereco']?['bairro'] ?? '';
                  final hora = data['hora_entrega'] ?? '08:00';
                  
                  final String dataEntrega = data['data_entrega'] ?? '';
                  bool isAtrasada = false;
                  if (dataEntrega.isNotEmpty) {
                    try {
                      final parts = dataEntrega.split('-');
                      if (parts.length == 3) {
                        final year = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final day = int.parse(parts[2]);
                        final scheduledDate = DateTime(year, month, day);
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        isAtrasada = scheduledDate.isBefore(today);
                      }
                    } catch (e) {
                      if (dataEntrega.compareTo(todayStr) < 0) {
                        isAtrasada = true;
                      }
                    }
                  }

                  return Column(
                    children: [
                      CardsAtividades(
                        id: id,
                        atividade: atividadeTexto,
                        cor: cor,
                        concluido: status == 'concluida' || status == 'na_obra',
                        clienteNome: data['cliente_nome'] ?? '-',
                        endereco: "$rua, $num - $bairro",
                        cacambaNumero: data['cacamba_numero'] ?? '-',
                        cacambaId: data['cacamba_id'] ?? '',
                        cacambaVelhaNumero: data['cacamba_velha_numero'] ?? '',
                        hora: hora,
                        atrasada: isAtrasada,
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
      bottomNavigationBar: const Paginadenavegacao(index: 1),
    );
  }
}
