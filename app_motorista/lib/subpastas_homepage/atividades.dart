import 'package:app_motorista/paginas_principais/paginaAtividades.dart';
import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Atividades extends StatelessWidget {
  final List<QueryDocumentSnapshot> locacoes;
  const Atividades({super.key, required this.locacoes});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    String normalizeDate(dynamic value) {
      if (value == null) return '';
      final str = value.toString().trim();
      if (str.isEmpty) return '';
      if (str.length >= 10 && str.substring(4, 5) == '-' && str.substring(7, 8) == '-') {
        return str.substring(0, 10);
      }
      if (str.length >= 10 && str.substring(2, 3) == '/' && str.substring(5, 6) == '/') {
        final parts = str.substring(0, 10).split('/');
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return str;
    }

    // Filtra as pendentes (não concluídas) para mostrar como próximas atividades
    final proximas = locacoes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'entrega_pendente';
      final isPending = status != 'concluida' && status != 'na_obra';

      if (!isPending) return false;

      // Não mostra atividades agendadas para datas futuras
      final dataEntregaNorm = normalizeDate(data['data_entrega']);
      if (dataEntregaNorm.isNotEmpty) {
        try {
          final parts = dataEntregaNorm.split('-');
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
          if (dataEntregaNorm.compareTo(todayStr) > 0) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Próximas atividades",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Paginaatividades(),
                      ),
                    );
                  },
                  child: const Text(
                    "Ver todas",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (proximas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "Nenhuma atividade pendente para hoje!",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              )
            else
              ...proximas.take(3).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final id = doc.id;
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

                final dataEntregaNorm = normalizeDate(data['data_entrega']);
                bool isAtrasada = false;
                if (dataEntregaNorm.isNotEmpty) {
                  try {
                    final parts = dataEntregaNorm.split('-');
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
                    if (dataEntregaNorm.compareTo(todayStr) < 0) {
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
                      dataEntrega: data['data_entrega'] ?? '',
                      horaEntrega: data['hora_entrega'] ?? '',
                      concluidoEm: data['concluido_em'] as Timestamp?,
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OrdemDeServico extends StatelessWidget {
  final String atividade;
  final Color cor;
  const OrdemDeServico({super.key, required this.atividade, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 24,
      width: 80,
      decoration: BoxDecoration(
        color: cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        atividade,
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
