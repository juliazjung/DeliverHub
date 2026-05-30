import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/empresa.dart';
import '../services/session_service.dart';
import 'cadastro_empresa_screen.dart';

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  Empresa? _empresa;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final empresaId = SessionService().empresaId;
    if (empresaId == null) {
      setState(() => _loading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .get();
    setState(() {
      _empresa = doc.exists ? Empresa.fromMap(doc.id, doc.data()!) : null;
      _loading = false;
    });
  }

  void _abrirCadastro([Empresa? empresa]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 640,
          child: CadastroEmpresaScreen(empresa: empresa),
        ),
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
          const Text('Dados da empresa',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _empresa == null
                    ? const Center(child: Text('Empresa não encontrada.'))
                    : Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Nome')),
                              DataColumn(label: Text('CNPJ')),
                              DataColumn(label: Text('Endereço')),
                              DataColumn(label: Text('Cidade/Estado')),
                              DataColumn(label: Text('Celular')),
                              DataColumn(label: Text('Ações')),
                            ],
                            rows: [
                              DataRow(cells: [
                                DataCell(Text(_empresa!.nome)),
                                DataCell(Text(_empresa!.cnpj)),
                                DataCell(Text('${_empresa!.endereco}, ${_empresa!.numero}')),
                                DataCell(Text('${_empresa!.cidade}/${_empresa!.estado}')),
                                DataCell(Text(_empresa!.celular)),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFFE53935)),
                                  onPressed: () => _abrirCadastro(_empresa),
                                )),
                              ]),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}