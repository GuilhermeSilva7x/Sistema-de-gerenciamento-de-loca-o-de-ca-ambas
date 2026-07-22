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

    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    for (var doc in locacoes) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'entrega_pendente';
      final dataEntrega = data['data_entrega'] ?? '';

      if (status == 'concluida') {
        final dataRetirada = data['data_retirada'] ?? '';
        if (dataRetirada.toString().startsWith(todayStr)) {
          concluidas++;
        }
      } else if (status == 'na_obra') {
        final dataEntr = data['data_entrega'] ?? '';
        if (dataEntr.toString().startsWith(todayStr)) {
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
