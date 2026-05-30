import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import '../services/session_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _service = ClienteService();
  List<Cliente> _clientes = [];
  bool _loading = true;

  String _cidadeEmpresa = '';
  String _estadoEmpresa = '';

  @override
  void initState() {
    super.initState();
    _carregarEmpresa();
    _carregar();
  }

  Future<void> _carregarEmpresa() async {
    final empresaId = SessionService().empresaId;
    if (empresaId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .get();
    setState(() {
      _cidadeEmpresa = doc.data()?['cidade'] ?? '';
      _estadoEmpresa = doc.data()?['estado'] ?? '';
    });
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await _service.listarClientes();
    setState(() {
      _clientes = lista;
      _loading = false;
    });
  }

  void _abrirCadastro([Cliente? cliente]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CadastroClienteDialog(
        cliente: cliente,
        service: _service,
        cidadeEmpresa: _cidadeEmpresa,
        estadoEmpresa: _estadoEmpresa,
      ),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clientes cadastrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              ElevatedButton.icon(
                onPressed: _abrirCadastro,
                icon: const Icon(Icons.add),
                label: const Text('Novo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: _clientes.isEmpty
                        ? const Center(child: Text('Nenhum cliente cadastrado.'))
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Endereço')),
                                DataColumn(label: Text('Número')),
                                DataColumn(label: Text('Complemento')),
                                DataColumn(label: Text('Cidade')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: _clientes.map((c) => DataRow(cells: [
                                DataCell(Text(c.nome)),
                                DataCell(Text(c.endereco)),
                                DataCell(Text(c.numero)),
                                DataCell(Text(c.complemento)),
                                DataCell(Text(c.cidade)),
                                DataCell(Text(c.estado)),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFFE53935)),
                                  onPressed: () => _abrirCadastro(c),
                                )),
                              ])).toList(),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Cadastro Cliente ───────────────────────────────────────────────

class CadastroClienteDialog extends StatefulWidget {
  final Cliente? cliente;
  final ClienteService service;
  final String cidadeEmpresa;
  final String estadoEmpresa;

  const CadastroClienteDialog({
    super.key,
    this.cliente,
    required this.service,
    required this.cidadeEmpresa,
    required this.estadoEmpresa,
  });

  @override
  State<CadastroClienteDialog> createState() => _CadastroClienteDialogState();
}

class _CadastroClienteDialogState extends State<CadastroClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController();
  late final _endereco = TextEditingController();
  late final _numero = TextEditingController();
  late final _complemento = TextEditingController();
  late final _cidade = TextEditingController();
  late final _estado = TextEditingController();
  late final _cpf = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nome.text = c.nome;
      _endereco.text = c.endereco;
      _numero.text = c.numero;
      _complemento.text = c.complemento;
      _cidade.text = c.cidade;
      _estado.text = c.estado;
      _cpf.text = c.cpf;
    } else {
      _cidade.text = widget.cidadeEmpresa;
      _estado.text = widget.estadoEmpresa;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _endereco.dispose();
    _numero.dispose();
    _complemento.dispose();
    _cidade.dispose();
    _estado.dispose();
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.service.salvarCliente(Cliente(
        id: widget.cliente?.id,
        nome: _nome.text.trim(),
        endereco: _endereco.text.trim(),
        numero: _numero.text.trim(),
        complemento: _complemento.text.trim(),
        cidade: _cidade.text.trim(),
        estado: _estado.text.trim(),
        cpf: _cpf.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _campo(TextEditingController controller, String label,
      {bool obrigatorio = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: obrigatorio
            ? (v) => v == null || v.isEmpty ? 'Informe $label' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(_nome, 'Nome'),
                Row(children: [
                  Expanded(flex: 3, child: _campo(_endereco, 'Endereço')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_numero, 'Número', obrigatorio: false)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campo(_complemento, 'Complemento', obrigatorio: false)),
                ]),
                Row(children: [
                  Expanded(flex: 2, child: _campo(_cidade, 'Cidade')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_estado, 'Estado')),
                ]),
                _campo(_cpf, 'CPF', obrigatorio: false),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar')),
        ElevatedButton(
          onPressed: _loading ? null : _salvar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}