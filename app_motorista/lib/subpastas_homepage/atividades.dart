import 'package:app_motorista/paginas_principais/paginaAtividades.dart';
import 'package:app_motorista/subpastas_homepage/cardsAtividades.dart';
import 'package:flutter/material.dart';

class Atividades extends StatelessWidget {
  const Atividades({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Próximas atividade",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Paginaatividades(),
                        ),
                      );
                    },
                    child: Text(
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
              SizedBox(height: 12),
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
