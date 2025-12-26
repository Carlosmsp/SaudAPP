import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String nomeUsuario;

  // Construtor: Exige que se passe o nome do utilizador
  const DashboardPage({super.key, required this.nomeUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dashboard principal",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Olá, $nomeUsuario!",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Vamos cuidar da saúde?",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Image.asset('assets/images/logo.png', height: 50),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _botaoDashboard(Icons.water_drop, "ÁGUA", Colors.cyan),
                  _botaoDashboard(Icons.restaurant, "REFEIÇÕES", Colors.orange),
                  _botaoDashboard(Icons.bed, "DORMIR", Colors.indigoAccent),
                  _botaoDashboard(
                    Icons.directions_run,
                    "ATIVIDADE",
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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

  Widget _botaoDashboard(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
