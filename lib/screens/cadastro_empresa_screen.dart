import 'package:flutter/material.dart';
import '../models/empresa.dart';
import '../services/empresa_service.dart';

class CadastroEmpresaScreen extends StatefulWidget {
  final Empresa? empresa;
  const CadastroEmpresaScreen({super.key, this.empresa});

  @override
  State<CadastroEmpresaScreen> createState() => _CadastroEmpresaScreenState();
}

class _CadastroEmpresaScreenState extends State<CadastroEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EmpresaService();
  bool _loading = false;
  bool _senhaVisivel = false;

  late final _nome = TextEditingController();
  late final _razaoSocial = TextEditingController();
  late final _cnpj = TextEditingController();
  late final _estado = TextEditingController();
  late final _cidade = TextEditingController();
  late final _endereco = TextEditingController();
  late final _numero = TextEditingController();
  late final _email = TextEditingController();
  late final _celular = TextEditingController();
  late final _usuarioAdmin = TextEditingController();
  late final _senhaAdmin = TextEditingController();
  late final _impressoraPadrao = TextEditingController();

  bool get _editando => widget.empresa != null;

  @override
  void initState() {
    super.initState();
    final e = widget.empresa;
    if (e != null) {
      _nome.text = e.nome;
      _razaoSocial.text = e.razaoSocial;
      _cnpj.text = e.cnpj;
      _estado.text = e.estado;
      _cidade.text = e.cidade;
      _endereco.text = e.endereco;
      _numero.text = e.numero;
      _email.text = e.email;
      _celular.text = e.celular;
      _impressoraPadrao.text = e.impressoraPadrao;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final empresa = Empresa(
        id: widget.empresa?.id,
        nome: _nome.text.trim(),
        razaoSocial: _razaoSocial.text.trim(),
        cnpj: _cnpj.text.trim(),
        estado: _estado.text.trim(),
        cidade: _cidade.text.trim(),
        endereco: _endereco.text.trim(),
        numero: _numero.text.trim(),
        email: _email.text.trim(),
        celular: _celular.text.trim(),
        impressoraPadrao: _impressoraPadrao.text.trim(),
      );

      if (_editando) {
        await _service.atualizarEmpresa(empresa);
      } else {
        await _service.cadastrarEmpresa(
          empresa: empresa,
          usuarioAdmin: _usuarioAdmin.text.trim(),
          senhaAdmin: _senhaAdmin.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa salva com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _campo(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Informe $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_editando ? 'Editar Empresa' : 'Cadastro de Empresa'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dados da Empresa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _campo(_nome, 'Nome', Icons.store),
                    _campo(_razaoSocial, 'Razão Social', Icons.business),
                    _campo(_cnpj, 'CNPJ', Icons.badge),
                    Row(children: [
                      Expanded(child: _campo(_estado, 'Estado', Icons.map)),
                      const SizedBox(width: 16),
                      Expanded(child: _campo(_cidade, 'Cidade', Icons.location_city)),
                    ]),
                    Row(children: [
                      Expanded(flex: 3, child: _campo(_endereco, 'Endereço', Icons.home)),
                      const SizedBox(width: 16),
                      Expanded(child: _campo(_numero, 'Número', Icons.numbers)),
                    ]),
                    _campo(_email, 'Email', Icons.email),
                    _campo(_celular, 'Celular', Icons.phone),
                    _campo(_impressoraPadrao, 'Nome da impressora', Icons.print),

                    // Usuário admin só no cadastro novo
                    if (!_editando) ...[
                      const SizedBox(height: 24),
                      const Text('Usuário Administrador',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _campo(_usuarioAdmin, 'Usuário', Icons.person),
                      TextFormField(
                        controller: _senhaAdmin,
                        obscureText: !_senhaVisivel,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_senhaVisivel
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (v) => !_editando && (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Conta verificada: pendente',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}