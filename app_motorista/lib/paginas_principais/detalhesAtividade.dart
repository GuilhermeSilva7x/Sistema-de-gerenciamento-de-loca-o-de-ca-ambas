import 'package:app_motorista/subpastas_detalhesAtividades/abaCliente.dart';
import 'package:app_motorista/subpastas_homepage/atividades.dart';
import 'package:flutter/material.dart';

class Detalhesatividade extends StatelessWidget {
  final String atividade;
  final Color cor;
  const Detalhesatividade({
    super.key,
    required this.cor,
    required this.atividade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ordem de Serviço",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            OrdemDeServico(atividade: atividade, cor: cor),
            SizedBox(height: 20),
            Abacliente(),
            SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(),
              onPressed: () {},
              child: Text("Abrir no GPS (MAPS/WAZE)"),
            ),
          ],
        ),
      ),
    );
  }
}
