import 'package:flutter/material.dart';

class Botaolocalizacao extends StatelessWidget {
  const Botaolocalizacao({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        fixedSize: Size(3000, 50),
      ),
      onPressed: () {},
      child: Text(
        "Abrir no GPS (MAPS)",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }
}
