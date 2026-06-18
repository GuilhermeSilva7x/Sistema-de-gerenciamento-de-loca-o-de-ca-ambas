import 'package:flutter/material.dart';

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Perfil",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 40),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "João Silva",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text("Motorista | ID: 1025"),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 35),
                SizedBox(width: 16),
                Text(
                  "Alterar Senha",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios_rounded),
              ],
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
