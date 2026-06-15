import 'package:app_motorista/subpastas_homepage/atividades.dart';
import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';

class Paginaatividades extends StatelessWidget {
  const Paginaatividades({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Text(
          "Atividades do dia",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8),
            CardsAtividades(atividade: "ENTREGA", cor: Colors.blue),
            SizedBox(height: 8),
            CardsAtividades(atividade: "TROCA", cor: Colors.orange),
            SizedBox(height: 8),
            CardsAtividades(atividade: "RETIRADA", cor: Colors.red),
            SizedBox(height: 8),
            CardsAtividades(atividade: "RETIRADA", cor: Colors.red),
            SizedBox(height: 8),
            CardsAtividades(atividade: "ENTREGA", cor: Colors.blue),
            SizedBox(height: 8),
            CardsAtividades(atividade: "ENTREGA", cor: Colors.blue),
            SizedBox(height: 8),
            CardsAtividades(atividade: "TROCA", cor: Colors.orange),
            SizedBox(height: 8),
            CardsAtividades(atividade: "RETIRADA", cor: Colors.red),
            SizedBox(height: 8),
            CardsAtividades(atividade: "RETIRADA", cor: Colors.red),
            SizedBox(height: 8),
            CardsAtividades(atividade: "ENTREGA", cor: Colors.blue),
          ],
        ),
      ),
      bottomNavigationBar: Paginadenavegacao(index: 1),
    );
  }
}
