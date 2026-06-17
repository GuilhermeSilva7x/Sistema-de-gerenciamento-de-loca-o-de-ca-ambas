import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';

class Paginahistorico extends StatelessWidget {
  const Paginahistorico({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(
          "Histórico",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "ENTREGA",
              cor: Colors.blue,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "TROCA",
              cor: Colors.orange,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "RETIRADA",
              cor: Colors.red,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "RETIRADA",
              cor: Colors.red,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "ENTREGA",
              cor: Colors.blue,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "ENTREGA",
              cor: Colors.blue,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "TROCA",
              cor: Colors.orange,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "RETIRADA",
              cor: Colors.red,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "RETIRADA",
              cor: Colors.red,
              concluido: true,
            ),
            SizedBox(height: 8),
            CardsAtividades(
              atividade: "ENTREGA",
              cor: Colors.blue,
              concluido: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Paginadenavegacao(index: 2),
    );
    ;
  }
}
