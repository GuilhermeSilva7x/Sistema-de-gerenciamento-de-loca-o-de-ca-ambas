import 'package:flutter/material.dart';

class Suporte extends StatelessWidget {
  final String caminhao;
  final String motoristaNome;

  const Suporte({
    super.key,
    required this.caminhao,
    required this.motoristaNome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SUPORTE E VEÍCULO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                const Text("Caminhão Atual"),
                const Spacer(),
                Text(
                  caminhao,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
