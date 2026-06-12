import 'package:flutter/material.dart';

class Abacliente extends StatelessWidget {
  const Abacliente({super.key});

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 6),
            Text("Cliente:", style: TextStyle(fontSize: 16)),
            Text(
              "João Silva",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Divider(thickness: 2),
            SizedBox(height: 4),
            Text("Endereço de entrega", style: TextStyle(fontSize: 16)),
            Text(
              "Rua das Flores 123",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text("Setor sul, Goiânia - GO", style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Divider(thickness: 2),
            SizedBox(height: 4),

            Text("Caçamba Alocada", style: TextStyle(fontSize: 16)),
            Text(
              "N° 25",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
