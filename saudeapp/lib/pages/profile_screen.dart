import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers biométricos
  final _nomeController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();

  // Controllers de Metas
  final _metaAguaController = TextEditingController();
  final _metaSonoController = TextEditingController();
  final _metaAtividadeController = TextEditingController();
  final _metaCaloriasController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Boa prática: Sempre fazer dispose dos controllers para evitar fugas de memória
  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _metaAguaController.dispose();
    _metaSonoController.dispose();
    _metaAtividadeController.dispose();
    _metaCaloriasController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final data = await Supabase.instance.client
          .from('utilizadores')
          .select()
          .eq('id_utilizador', widget.userId)
          .single();

      if (!mounted) return;

      setState(() {
        _nomeController.text = data['nome'] ?? '';
        _pesoController.text = data['peso']?.toString() ?? '';
        _alturaController.text = data['altura']?.toString() ?? '';
        
        _metaAguaController.text = data['meta_agua']?.toString() ?? '2000';
        _metaSonoController.text = data['meta_sono']?.toString() ?? '8';
        _metaAtividadeController.text = data['meta_atividade']?.toString() ?? '30';
        _metaCaloriasController.text = data['meta_calorias']?.toString() ?? '2200';
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarAlteracoes() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('utilizadores').update({
        'nome': _nomeController.text,
        'peso': double.tryParse(_pesoController.text),
        'altura': int.tryParse(_alturaController.text),
        'meta_agua': int.tryParse(_metaAguaController.text),
        'meta_sono': int.tryParse(_metaSonoController.text),
        'meta_atividade': int.tryParse(_metaAtividadeController.text),
        'meta_calorias': int.tryParse(_metaCaloriasController.text),
      }).eq('id_utilizador', widget.userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil e Metas atualizados!"),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao guardar dados."), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Terminar Sessão"),
        content: const Text("Tens a certeza que queres sair da tua conta?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Perfil", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false, 
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _confirmarLogout(context),
            ),
          ],
        ),
        
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.cyan,
                      backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Luis'),
                    ),
                    const SizedBox(height: 25),

                    _campoTexto(_nomeController, "Nome"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _campoTexto(_pesoController, "Peso (kg)", numerico: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _campoTexto(_alturaController, "Altura (cm)", numerico: true)),
                      ],
                    ),

                    const SizedBox(height: 35),
                    const Text("MINHAS METAS", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          _campoMeta(_metaAguaController, "Meta de Água (ml)", Icons.water_drop, Colors.blue),
                          _campoMeta(_metaSonoController, "Meta de Sono (h)", Icons.bed, Colors.indigo),
                          _campoMeta(_metaAtividadeController, "Meta de Atividade (min)", Icons.run_circle, Colors.green),
                          _campoMeta(_metaCaloriasController, "Meta de Calorias (kcal)", Icons.restaurant, Colors.orange),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),
                    
                    ElevatedButton(
                      onPressed: _guardarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text("GUARDAR ALTERAÇÕES", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _campoTexto(TextEditingController controller, String label, {bool numerico = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyan, width: 2)),
        ),
      ),
    );
  }

  Widget _campoMeta(TextEditingController controller, String label, IconData icon, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: cor),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: cor, width: 2)),
        ),
      ),
    );
  }
}