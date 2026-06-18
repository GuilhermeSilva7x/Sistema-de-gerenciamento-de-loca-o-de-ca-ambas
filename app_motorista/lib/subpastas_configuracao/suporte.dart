import 'package:flutter/material.dart';

class Suporte extends StatelessWidget {
  const Suporte({super.key});

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
            Text(
              "SUPORTE E VEÍCULO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined),
                SizedBox(width: 12),
                Text("Caminhão Atual"),
                Spacer(),
                Text("ABC-1234"),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    "Falar com a Logística",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
