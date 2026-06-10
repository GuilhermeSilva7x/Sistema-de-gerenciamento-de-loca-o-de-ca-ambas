import 'package:flutter/material.dart';

class Paginadenavegacao extends StatelessWidget {
  const Paginadenavegacao({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
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
