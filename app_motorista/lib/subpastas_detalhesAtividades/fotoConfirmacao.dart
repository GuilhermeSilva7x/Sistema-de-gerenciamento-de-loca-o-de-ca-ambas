import 'package:flutter/material.dart';

class Fotoconfirmacao extends StatelessWidget {
  final bool concluido;
  const Fotoconfirmacao({super.key, this.concluido = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Comprovação de entrega",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                concluido
                    ? Icon(Icons.photo, size: 100)
                    : Icon(Icons.camera_alt_outlined, size: 50),
                concluido
                    ? Text("")
                    : Text(
                        "Toque para tirar a foto da caçamba no local",
                        style: TextStyle(fontSize: 15),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
