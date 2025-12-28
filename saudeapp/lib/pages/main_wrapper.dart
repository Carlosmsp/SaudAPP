import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart'; // Import necessário

class MainWrapper extends StatefulWidget {
  final String nomeUsuario;
  final int userId;
  const MainWrapper({super.key, required this.nomeUsuario, required this.userId});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Lista de ecrãs principais que mantém o estado
    _pages = [
      DashboardPage(nomeUsuario: widget.nomeUsuario, userId: widget.userId),
      GoalsScreen(userId: widget.userId),
      const RemindersScreen(), // CORREÇÃO: Agora chama o ecrã real
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack impede que os ecrãs reiniciem ao trocar de aba
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Objetivos'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Lembretes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}