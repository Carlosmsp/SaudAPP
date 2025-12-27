import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Podes manter ou apagar. Neste ficheiro já não estamos a usar diretamente, mas no projeto continua a funcionar!
import 'water_screen.dart';

class DashboardPage extends StatefulWidget {
  final String nomeUsuario;
  final int userId;

  const DashboardPage({
    super.key,
    required this.nomeUsuario,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Retirei a função beberAgua() daqui porque agora vamos gerir isso dentro da própria página "WaterScreen"

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
                      "Olá, ${widget.nomeUsuario.split(' ').first}!",
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
                  _botaoDashboard(
                    icon: Icons.water_drop,
                    label: "ÁGUA",
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WaterScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  _botaoDashboard(
                    icon: Icons.restaurant,
                    label: "REFEIÇÕES",
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _botaoDashboard(
                    icon: Icons.bed,
                    label: "DORMIR",
                    color: Colors.indigoAccent,
                    onTap: () {},
                  ),
                  _botaoDashboard(
                    icon: Icons.directions_run,
                    label: "ATIVIDADE",
                    color: Colors.green,
                    onTap: () {},
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

  Widget _botaoDashboard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              // CORREÇÃO DO AVISO AQUI (withValues em vez de withOpacity):
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
      ),
    );
  }
}
