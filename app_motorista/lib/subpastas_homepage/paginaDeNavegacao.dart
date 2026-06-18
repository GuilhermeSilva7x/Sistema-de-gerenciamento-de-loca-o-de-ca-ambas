import 'package:app_motorista/paginas_principais/configuracao.dart';
import 'package:app_motorista/paginas_principais/paginaAtividades.dart';
import 'package:app_motorista/paginas_principais/homepage.dart';
import 'package:app_motorista/paginas_principais/paginaHistorico.dart';
import 'package:flutter/material.dart';

class Paginadenavegacao extends StatelessWidget {
  final int index;
  const Paginadenavegacao({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: Colors.blue,
      type: BottomNavigationBarType.fixed,
      onTap: (value) {
        if (value != index) {
          if (value == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Homepage()),
            );
          } else if (value == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Paginaatividades()),
            );
          } else if (value == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Paginahistorico()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Configuracao()),
            );
          }
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: "Atividades",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.restore), label: "Histórico"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}
