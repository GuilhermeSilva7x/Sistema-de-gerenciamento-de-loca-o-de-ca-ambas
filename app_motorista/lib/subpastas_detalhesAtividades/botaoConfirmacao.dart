import 'package:flutter/material.dart';

class Botaoconfirmacao extends StatelessWidget {
  final String texto;
  final Color cor;
  const Botaoconfirmacao({super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(color: cor, width: 2),
        fixedSize: Size(3000, 50),
      ),
      onPressed: () {},
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 17),
      ),
    );
  }
}
