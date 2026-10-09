import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Fotoconfirmacao extends StatefulWidget {
  final bool concluido;
  const Fotoconfirmacao({super.key, this.concluido = false});

  @override
  State<Fotoconfirmacao> createState() => _FotoconfirmacaoState();
}

class _FotoconfirmacaoState extends State<Fotoconfirmacao> {
  Uint8List? fotoBytes;
  Future<void> tirarFoto() async {
    final ImagePicker buscador = ImagePicker();
    final XFile? fotoTirada = await buscador.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (fotoTirada != null) {
      final bytes = await fotoTirada.readAsBytes();
      setState(() {
        fotoBytes = bytes;
      });
    }
  }

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
          onTap: () async {
            await tirarFoto();
          },
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                fotoBytes != null
                    ? Image.memory(
                        fotoBytes!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : widget.concluido
                    ? const Icon(Icons.photo, size: 50, color: Colors.grey)
                    : const Icon(Icons.camera_alt_outlined, size: 50),

                const SizedBox(height: 8),
                fotoBytes != null || widget.concluido
                    ? const SizedBox.shrink()
                    : const Text(
                        "Toque para tirar a foto da caçamba no local",
                        style: TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
