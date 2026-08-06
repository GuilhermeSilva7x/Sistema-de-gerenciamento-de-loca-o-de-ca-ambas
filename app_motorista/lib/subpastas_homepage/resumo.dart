import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Resumo extends StatelessWidget {
  final List<QueryDocumentSnapshot> locacoes;
  const Resumo({super.key, required this.locacoes});

  @override
  Widget build(BuildContext context) {
    int entregas = 0;
    int trocas = 0;
    int retiradas = 0;
    int concluidas = 0;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

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

    for (var doc in locacoes) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'entrega_pendente';
      final dataEntrega = data['data_entrega'] ?? '';

      if (status == 'concluida') {
        final dataRetirada = normalizeDate(data['data_retirada']);
        if (dataRetirada == todayStr || dataRetirada == yesterdayStr || dataRetirada == tomorrowStr) {
          concluidas++;
        }
      } else if (status == 'na_obra' || status == 'em_uso') {
        final dataEntr = normalizeDate(data['data_entrega']);
        if (dataEntr == todayStr || dataEntr == yesterdayStr || dataEntr == tomorrowStr) {
          concluidas++;
        }
      } else {
        // Pula atividades agendadas para o futuro
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
                continue;
              }
            }
          } catch (e) {
            if (dataEntrega.compareTo(todayStr) > 0) {
              continue;
            }
          }
        }

        if (status == 'entrega_pendente') {
          entregas++;
        } else if (status == 'troca_pendente' || status == 'aguardando_troca') {
          trocas++;
        } else if (status == 'retirada_pendente' || status == 'aguardando_retirada') {
          retiradas++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumo do dia",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CardsResumoDoDia(
                    icone: Icons.assignment_rounded,
                    numero: entregas,
                    nome: "Entregas",
                    corIcone: Colors.blue,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.swap_horiz_rounded,
                    numero: trocas,
                    nome: "Trocas",
                    corIcone: Colors.orange,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.download_rounded,
                    numero: retiradas,
                    nome: "Retiradas",
                    corIcone: Colors.green,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.check_circle_rounded,
                    numero: concluidas,
                    nome: "Concluídas",
                    corIcone: Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardsResumoDoDia extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final int numero;
  final String nome;
  const CardsResumoDoDia({
    super.key,
    required this.icone,
    required this.numero,
    required this.nome,
    required this.corIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        height: 85,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icone, color: corIcone),
            Text(
              "$numero",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(nome),
          ],
        ),
      ),
    );
  }
}
