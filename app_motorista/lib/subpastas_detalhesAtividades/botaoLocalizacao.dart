import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class Botaolocalizacao extends StatelessWidget {
  const Botaolocalizacao({super.key});

  // 🚀 FUNÇÃO PARA ABRIR O GPS
  Future<void> _abrirNoGPS(String enderecoEntrega) async {
    // Codifica o endereço para o formato de URL (substitui espaços por %20, etc.)
    final String enderecoCodificado = Uri.encodeComponent(enderecoEntrega);

    // URL universal do Google Maps para navegação/busca
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$enderecoCodificado",
    );

    try {
      // Verifica se o celular consegue abrir esse link (se tem Maps instalado)
      if (await canLaunchUrl(googleMapsUrl)) {
        // Abre o aplicativo de mapas em modo externo
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o mapa.';
      }
    } catch (e) {
      print("Erro ao abrir o GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        fixedSize: Size(3000, 50),
      ),
      onPressed: () {
        _abrirNoGPS("Rua Santa Helena, 271 - Alvorada, Bom Jesus -GO");
      },
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
