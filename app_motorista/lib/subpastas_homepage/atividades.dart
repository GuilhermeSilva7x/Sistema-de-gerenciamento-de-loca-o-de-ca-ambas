import 'package:app_motorista/paginas_principais/detalhesAtividade.dart';
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
                    onPressed: () {},
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

class CardsAtividades extends StatelessWidget {
  final Color cor;
  final String atividade;

  const CardsAtividades({
    super.key,
    required this.cor,
    required this.atividade,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Detalhesatividade(cor: cor, atividade: atividade),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: double.infinity,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OrdemDeServico(atividade: atividade, cor: cor),
                    Row(
                      children: [
                        const Icon(
                          Icons.watch_later_outlined,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "08:00",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Cliente: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const Expanded(
                          child: Text(
                            "João Silva",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 26),
                        const Text(
                          "Endereço: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rua das Flores, 123",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "Setor Sul, Goiânia - GO",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 16.0,
                top: 12.0,
                bottom: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Caçamba: ", style: TextStyle(color: Colors.grey)),
                      Text(
                        "025",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFF1E293B).withOpacity(0.7),
                    size: 18,
                  ),
                  const Spacer(),
                ],
              ),
            ),
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
