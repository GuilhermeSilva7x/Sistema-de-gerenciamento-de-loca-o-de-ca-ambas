import 'package:app_motorista/subpastas_homepage/atividades.dart';
import 'package:app_motorista/subpastas_homepage/cabecalho.dart';
import 'package:app_motorista/subpastas_homepage/paginaDeNavegacao.dart';
import 'package:app_motorista/subpastas_homepage/resumo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          final motoristaNome = motoristaDoc != null
              ? (motoristaDoc.data() as Map<String, dynamic>)['nome'] ?? 'Motorista'
              : 'Motorista';
          final motoristaId = motoristaDoc?.id ?? '';

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
      ),
      bottomNavigationBar: const Paginadenavegacao(index: 0),
    );
  }
}
