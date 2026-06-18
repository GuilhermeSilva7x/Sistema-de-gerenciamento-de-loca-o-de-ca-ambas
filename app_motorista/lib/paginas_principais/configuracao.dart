import 'package:app_motorista/subpastas_configuracao/perfil.dart';
import 'package:app_motorista/subpastas_configuracao/suporte.dart';
import 'package:app_motorista/subpastas_detalhesAtividades/botaoConfirmacao.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';

class Configuracao extends StatelessWidget {
  const Configuracao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CONFIGURAÇÕES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Perfil(),
            SizedBox(height: 20),
            Suporte(),
            SizedBox(height: 20),
            Botaoconfirmacao(texto: "SAIR DO APP", cor: Colors.red),
          ],
        ),
      ),
      bottomNavigationBar: Paginadenavegacao(index: 3),
    );
  }
}
