import 'package:app_motorista/paginas_principais/detalhesAtividade.dart';
import 'package:flutter/material.dart';

class CardsAtividades extends StatefulWidget {
  final bool concluido;
  final Color cor;
  final String atividade;

  const CardsAtividades({
    super.key,
    required this.cor,
    required this.atividade,
    this.concluido = false,
  });

  @override
  State<CardsAtividades> createState() => _CardsAtividadesState();
}

class _CardsAtividadesState extends State<CardsAtividades> {
  @override
  Widget build(BuildContext context) {
    final bool estaConcluido = widget.concluido;

    final Color corPrincipal = estaConcluido ? Colors.green : widget.cor;
    final String textoAtividade = widget.atividade;

    final Color corDoTextoDados = estaConcluido
        ? Colors.grey[600]!
        : const Color(0xFF1E293B);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detalhesatividade(
              cor: corPrincipal,
              atividade: textoAtividade,
              concluido: estaConcluido,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: corPrincipal.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: double.infinity,
              decoration: BoxDecoration(
                color: corPrincipal,
                borderRadius: const BorderRadius.only(
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
                    Container(
                      alignment: Alignment.center,
                      height: 24,
                      width: 95,
                      decoration: BoxDecoration(
                        color: corPrincipal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        textoAtividade,
                        style: TextStyle(
                          color: corPrincipal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.watch_later_outlined,
                          size: 20,
                          color: corDoTextoDados,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "08:00",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: corDoTextoDados,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Cliente: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Expanded(
                          child: Text(
                            "João Silva",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: corDoTextoDados,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rua das Flores, 123",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: corDoTextoDados,
                                ),
                              ),
                              Text(
                                "Setor Sul, Goiânia - GO",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: corDoTextoDados,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Caçamba: ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "025",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corDoTextoDados,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  estaConcluido
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 28,
                        )
                      : Icon(
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
