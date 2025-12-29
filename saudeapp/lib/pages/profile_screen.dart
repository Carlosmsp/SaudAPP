import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _sexo = 'M';
  String? _fotoUrl;
  bool _isLoading = true;

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
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final data = await Supabase.instance.client
          .from('utilizadores')
          .select()
          .eq('id_utilizador', widget.userId)
          .single();
      final user = Supabase.instance.client.auth.currentUser;

      if (!mounted) return;

      setState(() {
        _nomeController.text = data['nome'] ?? '';
        _emailController.text = user?.email ?? '';
        _pesoController.text = data['peso']?.toString() ?? '';
        _alturaController.text = data['altura']?.toString() ?? '';
        _sexo = data['sexo'] ?? 'M';
        _fotoUrl = data['foto_perfil_url'];
        _metaAguaController.text = data['meta_agua']?.toString() ?? '2000';
        _metaSonoController.text = data['meta_sono']?.toString() ?? '8';
        _metaAtividadeController.text =
            data['meta_atividade']?.toString() ?? '30';
        _metaCaloriasController.text =
            data['meta_calorias']?.toString() ?? '2200';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final bytes = await File(image.path).readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName =
          '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await Supabase.instance.client.storage
          .from('profile-photos')
          .uploadBinary(filePath, bytes);
      final publicUrl = Supabase.instance.client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      await Supabase.instance.client
          .from('utilizadores')
          .update({'foto_perfil_url': publicUrl})
          .eq('id_utilizador', widget.userId);

      if (mounted) {
        setState(() => _fotoUrl = publicUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Foto atualizada!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _alterarEmail() async {
    final controller = TextEditingController(text: _emailController.text);
    final senhaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Alterar Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Novo Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Atual",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: controller.text.trim()),
                );
                if (mounted) {
                  setState(
                    () => _emailController.text = controller.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "✅ Email atualizado! Verifica o novo email.",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("ALTERAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _alterarPassword() async {
    final senhaAtualController = TextEditingController();
    final senhaNovaController = TextEditingController();
    final senhaConfirmarController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Alterar Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: senhaAtualController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Atual",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: senhaNovaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nova Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: senhaConfirmarController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmar Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              if (senhaNovaController.text != senhaConfirmarController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Passwords não coincidem!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: senhaNovaController.text),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Password atualizada!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("ALTERAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarAlteracoes() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('utilizadores')
          .update({
            'nome': _nomeController.text.trim(),
            'peso': double.tryParse(_pesoController.text),
            'altura': int.tryParse(_alturaController.text),
            'sexo': _sexo,
            'meta_agua': int.tryParse(_metaAguaController.text),
            'meta_sono': int.tryParse(_metaSonoController.text),
            'meta_atividade': int.tryParse(_metaAtividadeController.text),
            'meta_calorias': int.tryParse(_metaCaloriasController.text),
          })
          .eq('id_utilizador', widget.userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Perfil atualizado!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Terminar Sessão"),
        content: const Text("Tens a certeza?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Abre a página de atualizações da aplicação num browser externo.
  /// Caso não seja possível abrir, apresenta uma mensagem de erro ao utilizador.
  Future<void> _procurarAtualizacoes() async {
    final uri = Uri.parse(
      'http://87.196.41.131:5244/d/Toshiba/SaudApp/Atualiza%C3%A7%C3%B5es/app-release.apk?sign=ZU6aczJJIBMpnb8EeNddvnlfUO2gHtrzSvLNwFpAg0o=:0',
    );

    // Tenta abrir o link numa aplicação externa (por exemplo, o browser padrão).
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível abrir a página de atualizações."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 238),
      appBar: AppBar(
        title: const Text(
          "Perfil",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
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
                  GestureDetector(
                    onTap: _escolherFoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: _sexo == 'M'
                              ? Colors.blue[100]
                              : Colors.pink[100],
                          backgroundImage: _fotoUrl != null
                              ? NetworkImage(_fotoUrl!)
                              : null,
                          child: _fotoUrl == null
                              ? Icon(
                                  _sexo == 'M'
                                      ? Icons.person
                                      : Icons.person_outline,
                                  size: 80,
                                  color: _sexo == 'M'
                                      ? Colors.blue
                                      : Colors.pink,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.cyan,
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
                  GestureDetector(
                    onTap: _alterarEmail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _emailController.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.cyan),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _alterarPassword,
                    icon: const Icon(Icons.lock, color: Colors.white),
                    label: const Text(
                      "Alterar Password",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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
                          style: TextStyle(color: Colors.grey, fontSize: 14),
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
                  const SizedBox(height: 10),
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
                      borderRadius: BorderRadius.circular(25),
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
                  // Botão para procurar atualizações da aplicação.
                  // Abre a página de atualizações no browser predefinido.
                  OutlinedButton.icon(
                  onPressed: _procurarAtualizacoes,
                  icon: const Icon(Icons.system_update),
                  label: const Text(
                    "PROCURAR ATUALIZAÇÕES",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: const BorderSide(
                      color: Colors.cyan,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ],
              ),
            ),
    );
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
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
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
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
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
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
