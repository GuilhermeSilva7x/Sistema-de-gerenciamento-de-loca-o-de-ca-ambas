import 'package:flutter/material.dart';

class Abacliente extends StatelessWidget {
  final String clienteNome;
  final String endereco;
  final String cacambaNumero;
  final String cacambaVelhaNumero;
  final String atividade;

  const Abacliente({
    super.key,
    required this.clienteNome,
    required this.endereco,
    required this.cacambaNumero,
    this.cacambaVelhaNumero = '',
    this.atividade = '',
  });

  @override
  Widget build(BuildContext context) {
    final isTroca = atividade.toUpperCase() == 'TROCA';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text("Cliente:", style: TextStyle(fontSize: 16)),
            Text(
              clienteNome,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Divider(thickness: 2),
            const SizedBox(height: 4),
            const Text("Endereço de entrega", style: TextStyle(fontSize: 16)),
            Text(
              endereco,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Divider(thickness: 2),
            const SizedBox(height: 4),

            if (isTroca) ...[
              const Text("Caçamba a Entregar", style: TextStyle(fontSize: 16)),
              Text(
                "N° $cacambaNumero",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              const Divider(thickness: 2),
              const SizedBox(height: 4),
              const Text("Caçamba a Retirar (Trazer de volta)", style: TextStyle(fontSize: 16)),
              Text(
                "N° $cacambaVelhaNumero",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
              ),
            ] else ...[
              const Text("Caçamba Alocada", style: TextStyle(fontSize: 16)),
              Text(
                "N° $cacambaNumero",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
