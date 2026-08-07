import 'package:app_motorista/subpastas_homepage/atividades.dart';
import 'package:app_motorista/subpastas_homepage/cabecalho.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:app_motorista/subpastas_homepage/resumo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_motorista/paginas_principais/login.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // 1. Obtém o perfil do motorista logado pelo e-mail
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

          if (motoristaDoc == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Motorista não cadastrado no painel administrativo.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final motoristaData = motoristaDoc.data() as Map<String, dynamic>;
          final motoristaNome = motoristaData['nome'] ?? 'Motorista';
          final motoristaId = motoristaDoc.id;
          final adminId = motoristaData['admin_id'] ?? '';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('empresas')
                .doc(adminId)
                .snapshots(),
            builder: (context, empresaSnapshot) {
              if (empresaSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final empresaData = empresaSnapshot.data?.data() as Map<String, dynamic>?;
              final planoStatus = empresaData?['plano_status'] ?? 'pendente';

              if (planoStatus != 'ativo') {
                return Container(
                  color: Colors.red[900],
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        "ACESSO SUSPENSO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "O plano de serviços de sua empresa encontra-se temporariamente suspenso.\n\nPor favor, entre em contato com a gerência administrativa para regularizar o acesso.",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[900],
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        child: const Text("SAIR DA CONTA", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                // 2. Obtém as locações vinculadas a este motorista em tempo real
                stream: motoristaId.isNotEmpty
                    ? FirebaseFirestore.instance
                        .collection('locacoes')
                        .where('motorista_id', isEqualTo: motoristaId)
                        .snapshots()
                    : const Stream.empty(),
                builder: (context, locacoesSnapshot) {
                  final locacoes = locacoesSnapshot.data?.docs ?? [];

                  return SingleChildScrollView(
                    child: SafeArea(
                      child: Column(
                        children: [
                          Cabecalho(nome: motoristaNome),
                          const SizedBox(height: 12),
                          Resumo(locacoes: locacoes),
                          Atividades(locacoes: locacoes),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Paginadenavegacao(index: 0),
    );
  }
}
