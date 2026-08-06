import 'package:app_motorista/subpastas_configuracao/perfil.dart';
import 'package:app_motorista/subpastas_configuracao/suporte.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_motorista/paginas_principais/login.dart';

class Configuracao extends StatelessWidget {
  const Configuracao({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CONFIGURAÇÕES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Escuta o perfil do motorista logado
        stream: FirebaseFirestore.instance
            .collection('motoristas')
            .where('email', isEqualTo: user?.email)
            .snapshots(),
        builder: (context, motoristaSnapshot) {
          if (motoristaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final motoristaDoc = motoristaSnapshot.hasData && motoristaSnapshot.data!.docs.isNotEmpty
              ? motoristaSnapshot.data!.docs.first
              : null;
          final motoristaNome = motoristaDoc != null
              ? (motoristaDoc.data() as Map<String, dynamic>)['nome'] ?? 'Motorista'
              : 'Motorista';
          final caminhaoPlaca = motoristaDoc != null
              ? (motoristaDoc.data() as Map<String, dynamic>)['caminhao'] ?? 'Não vinculado'
              : 'Não vinculado';

          return StreamBuilder<DocumentSnapshot>(
            // 2. Escuta as configurações globais (para o WhatsApp da logística)
            stream: FirebaseFirestore.instance
                .collection('config')
                .doc('geral')
                .snapshots(),
            builder: (context, configSnapshot) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Perfil(nome: motoristaNome),
                    const SizedBox(height: 20),
                      Suporte(
                        caminhao: caminhaoPlaca,
                        motoristaNome: motoristaNome,
                      ),
                    const SizedBox(height: 30),
                    // Botão Sair da Conta 100% Funcional
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text(
                          "SAIR DO APP",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Paginadenavegacao(index: 3),
    );
  }
}
