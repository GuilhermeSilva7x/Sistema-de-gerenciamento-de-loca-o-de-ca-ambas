import 'package:flutter/material.dart';

class Resumo extends StatelessWidget {
  const Resumo({super.key});

  @override
  Widget build(BuildContext context) {
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
              Text(
                "Resumo do dia",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CardsResumoDoDia(
                    icone: Icons.assignment_rounded,
                    numero: 2,
                    nome: "Entregas",
                    corIcone: Colors.blue,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.swap_horiz_rounded,
                    numero: 1,
                    nome: "Trocas",
                    corIcone: Colors.orange,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.download_rounded,
                    numero: 1,
                    nome: "Retiradas",
                    corIcone: Colors.green,
                  ),
                  CardsResumoDoDia(
                    icone: Icons.check_circle_rounded,
                    numero: 4,
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
