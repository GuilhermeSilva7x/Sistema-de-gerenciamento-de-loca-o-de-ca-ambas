import 'package:flutter/material.dart';

class Botaoconfirmacao extends StatelessWidget {
  const Botaoconfirmacao({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(color: Colors.green, width: 2),
        fixedSize: Size(3000, 50),
      ),
      onPressed: () {},
      child: Text(
        "CONFIRMAR SERVIÇO",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }
}
