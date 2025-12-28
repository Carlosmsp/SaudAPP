import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _metaAguaController = TextEditingController();
  final _metaSonoController = TextEditingController();
  final _metaAtividadeController = TextEditingController();
  final _metaCaloriasController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _sexo = 'M';
  bool _isLoading = true;

  String? _avatarUrl;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _metaAguaController.dispose();
    _metaSonoController.dispose();
    _metaAtividadeController.dispose();
    _metaCaloriasController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        _emailController.text = data['email'] ?? '';
        _pesoController.text = data['peso']?.toString() ?? '';
        _alturaController.text = data['altura']?.toString() ?? '';
        _sexo = data['sexo'] ?? 'M';

        _metaAguaController.text = data['meta_agua']?.toString() ?? '2000';
        _metaSonoController.text = data['meta_sono']?.toString() ?? '8';
        _metaAtividadeController.text =
            data['meta_atividade']?.toString() ?? '30';
        _metaCaloriasController.text =
            data['meta_calorias']?.toString() ?? '2200';

        _avatarUrl = data['avatar_url'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarAlteracoes() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // Atualizar dados na tabela de utilizadores
      await client
          .from('utilizadores')
          .update({
            'nome': _nomeController.text.trim(),
            'email': _emailController.text.trim(),
            'peso': double.tryParse(_pesoController.text),
            'altura': int.tryParse(_alturaController.text),
            'sexo': _sexo,
            'meta_agua': int.tryParse(_metaAguaController.text),
            'meta_sono': int.tryParse(_metaSonoController.text),
            'meta_atividade': int.tryParse(_metaAtividadeController.text),
            'meta_calorias': int.tryParse(_metaCaloriasController.text),
            'avatar_url': _avatarUrl,
          })
          .eq('id_utilizador', widget.userId);

      final novoEmail = _emailController.text.trim();
      final novaPassword = _passwordController.text.trim();
      final confirmarPassword = _confirmPasswordController.text.trim();

      // Validar password se o utilizador quiser alterar
      if (novaPassword.isNotEmpty || confirmarPassword.isNotEmpty) {
        if (novaPassword != confirmarPassword) {
          setState(() => _isLoading = false);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("As passwords não coincidem."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (novaPassword.length < 6) {
          setState(() => _isLoading = false);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "A nova password deve ter pelo menos 6 caracteres."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Atualizar email/password na autenticação do Supabase
      if (novoEmail.isNotEmpty || novaPassword.isNotEmpty) {
        await client.auth.updateUser(
          UserAttributes(
            email: novoEmail.isNotEmpty ? novoEmail : null,
            password: novaPassword.isNotEmpty ? novaPassword : null,
          ),
        );
      }

      if (!mounted) return;
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Dados guardados com sucesso!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );

    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      _avatarFile = file;
    });

    try {
      final client = Supabase.instance.client;
      final fileName =
          'avatar_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await file.readAsBytes();

      await client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);

      if (!mounted) return;
      setState(() {
        _avatarUrl = publicUrl;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar imagem de perfil: $e'),
          backgroundColor: Colors.red,
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              }
            },
            child: const Text("SAIR"),
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Perfil",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                _sexo == 'M' ? Colors.blue[100] : Colors.pink[100],
                            backgroundImage: _avatarImageProvider(),
                            child: (_avatarFile == null &&
                                    (_avatarUrl == null ||
                                        _avatarUrl!.isEmpty))
                                ? Icon(
                                    _sexo == 'M'
                                        ? Icons.person
                                        : Icons.person_outline,
                                    size: 80,
                                    color:
                                        _sexo == 'M' ? Colors.blue : Colors.pink,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    _campoTexto(_nomeController, "Nome"),
                    const SizedBox(height: 15),
                    _campoTexto(
                      _emailController,
                      "Email",
                      email: true,
                    ),
                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sexo",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _sexoButton(
                                  'M',
                                  'Masculino',
                                  Icons.male,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _sexoButton(
                                  'F',
                                  'Feminino',
                                  Icons.female,
                                  Colors.pink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _campoTexto(
                            _pesoController,
                            "Peso (kg)",
                            numerico: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _campoTexto(
                            _alturaController,
                            "Altura (cm)",
                            numerico: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "CONTA & SEGURANÇA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _campoTexto(
                      _passwordController,
                      "Nova password",
                      password: true,
                    ),
                    _campoTexto(
                      _confirmPasswordController,
                      "Confirmar password",
                      password: true,
                    ),
                    const SizedBox(height: 35),
                    const Text(
                      "MINHAS METAS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _campoMeta(
                            _metaAguaController,
                            "Meta de Água (ml)",
                            Icons.water_drop,
                            Colors.blue,
                          ),
                          _campoMeta(
                            _metaSonoController,
                            "Meta de Sono (h)",
                            Icons.bed,
                            Colors.indigo,
                          ),
                          _campoMeta(
                            _metaAtividadeController,
                            "Meta de Atividade (min)",
                            Icons.run_circle,
                            Colors.green,
                          ),
                          _campoMeta(
                            _metaCaloriasController,
                            "Meta de Calorias (kcal)",
                            Icons.restaurant,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    ElevatedButton(
                      onPressed: _guardarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "GUARDAR ALTERAÇÕES",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  ImageProvider? _avatarImageProvider() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  Widget _sexoButton(String valor, String label, IconData icon, Color cor) {
    final isSelected = _sexo == valor;
    return InkWell(
      onTap: () => setState(() => _sexo = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? cor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? cor : Colors.grey, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? cor : Colors.grey,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(
    TextEditingController controller,
    String label, {
    bool numerico = false,
    bool email = false,
    bool password = false,
  }) {
    TextInputType teclado;
    if (numerico) {
      teclado = TextInputType.number;
    } else if (email) {
      teclado = TextInputType.emailAddress;
    } else {
      teclado = TextInputType.text;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        obscureText: password,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _campoMeta(
    TextEditingController controller,
    String label,
    IconData icon,
    Color cor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: cor),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: cor, width: 2),
          ),
        ),
      ),
    );
  }
}
