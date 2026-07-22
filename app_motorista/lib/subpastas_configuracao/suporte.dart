import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Suporte extends StatelessWidget {
  final String caminhao;
  final String? telefoneLogistica;
  final String motoristaNome;

  const Suporte({
    super.key,
    required this.caminhao,
    required this.telefoneLogistica,
    required this.motoristaNome,
  });

  Future<void> _falarComLogistica(BuildContext context) async {
    String fone = (telefoneLogistica ?? '').replaceAll(RegExp(r'[^\d]'), '');
    
    // Se não tiver o DDI do Brasil (55), mas tiver o DDD e número, insere 55
    if (fone.isNotEmpty && !fone.startsWith('55') && fone.length <= 11) {
      fone = '55$fone';
    }

    if (fone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("O número de WhatsApp da Logística não foi cadastrado no painel web."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    final text = Uri.encodeComponent("Olá, sou o motorista $motoristaNome e preciso de suporte com a logística das caçambas.");
    final url = Uri.parse("https://wa.me/$fone?text=$text");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir WhatsApp: $e. Telefone: $fone")),
        );
      }
    }
  }

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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _falarComLogistica(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Falar com a Logística",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
