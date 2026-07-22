import 'package:app_motorista/paginas_principais/detalhesAtividade.dart';
import 'package:flutter/material.dart';

class CardsAtividades extends StatefulWidget {
  final String id;
  final bool concluido;
  final Color cor;
  final String atividade;
  final String clienteNome;
  final String endereco;
  final String cacambaNumero;
  final String cacambaId;
  final String hora;
  final String cacambaVelhaNumero;

  const CardsAtividades({
    super.key,
    required this.id,
    required this.cor,
    required this.atividade,
    required this.clienteNome,
    required this.endereco,
    required this.cacambaNumero,
    required this.cacambaId,
    required this.hora,
    this.cacambaVelhaNumero = '',
    this.concluido = false,
    this.atrasada = false,
  });

  final bool atrasada;

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
              id: widget.id,
              cor: corPrincipal,
              atividade: textoAtividade,
              concluido: estaConcluido,
              clienteNome: widget.clienteNome,
              endereco: widget.endereco,
              cacambaNumero: widget.cacambaNumero,
              cacambaId: widget.cacambaId,
              cacambaVelhaNumero: widget.cacambaVelhaNumero,
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
                    Row(
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
                            textoAtividade.toUpperCase(),
                            style: TextStyle(
                              color: corPrincipal,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (widget.atrasada && !estaConcluido) ...[
                          const SizedBox(width: 8),
                          Container(
                            alignment: Alignment.center,
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red[300]!, width: 1),
                            ),
                            child: const Text(
                              "⚠️ ATRASADA",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                          widget.hora,
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
                            widget.clienteNome,
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
                          child: Text(
                            widget.endereco,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: corDoTextoDados,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        widget.cacambaNumero,
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
