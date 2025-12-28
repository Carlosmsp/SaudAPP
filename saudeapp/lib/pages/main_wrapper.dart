import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';

class MainWrapper extends StatefulWidget {
  final String nomeUsuario;
  final int userId;
  const MainWrapper({
    super.key,
    required this.nomeUsuario,
    required this.userId,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(
          nomeUsuario: widget.nomeUsuario,
          userId: widget.userId,
        );
      case 1:
        return GoalsScreen(
          userId: widget.userId,
          key: ValueKey(_selectedIndex),
        );
      case 2:
        return RemindersScreen(userId: widget.userId);
      case 3:
        return ProfileScreen(userId: widget.userId);
      default:
        return DashboardPage(
          nomeUsuario: widget.nomeUsuario,
          userId: widget.userId,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Objetivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Lembretes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
