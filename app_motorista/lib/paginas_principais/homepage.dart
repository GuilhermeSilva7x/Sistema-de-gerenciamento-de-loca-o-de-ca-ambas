import 'package:app_motorista/subpastas_homepage/cabecalho.dart';
import 'package:app_motorista/subpastas_homepage/resumo.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [Cabecalho(), SizedBox(height: 12), Resumo()]),
      ),
    );
  }
}
