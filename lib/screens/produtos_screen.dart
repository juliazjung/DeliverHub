import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _service = ProdutoService();
  List<Produto> _produtos = [];
  bool _loading = true;
  String? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await _service.listarProdutos();
    setState(() {
      _produtos = lista;
      _loading = false;
    });
  }

  void _abrirCadastro([Produto? produto]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CadastroProdutoDialog(produto: produto, service: _service),
    );
    _carregar();
  }

  List<Produto> get _produtosFiltrados {
    if (_filtroTipo == null) return _produtos;
    return _produtos.where((p) => p.tipo == _filtroTipo).toList();
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'produto':
        return 'Produto';
      case 'bebida':
        return 'Bebida';
      case 'adicional':
        return 'Adicional';
      case 'combo':
        return 'Combo';
      default:
        return tipo;
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo) {
      case 'produto':
        return Colors.blue;
      case 'bebida':
        return Colors.teal;
      case 'adicional':
        return Colors.orange;
      case 'combo':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
              const Text(
                'Produtos cadastrados',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirCadastro(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Produto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filtrar por: ', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _filtroTipo,
                hint: const Text('Todos'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'produto', child: Text('Produto')),
                  DropdownMenuItem(value: 'bebida', child: Text('Bebida')),
                  DropdownMenuItem(
                    value: 'adicional',
                    child: Text('Adicional'),
                  ),
                ],
                onChanged: (v) => setState(() => _filtroTipo = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: _produtosFiltrados.isEmpty
                        ? const Center(
                            child: Text('Nenhum produto cadastrado.'),
                          )
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Subprodutos')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: _produtosFiltrados
                                  .map(
                                    (p) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            p.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _corTipo(
                                                p.tipo,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _labelTipo(p.tipo),
                                              style: TextStyle(
                                                color: _corTipo(p.tipo),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            p.subprodutos.isEmpty
                                                ? '-'
                                                : p.subprodutos
                                                      .map(
                                                        (s) => s.nomeCompleto,
                                                      )
                                                      .join(', '),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: p.ativo
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              p.ativo ? 'Ativo' : 'Inativo',
                                              style: TextStyle(
                                                color: p.ativo
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFFE53935),
                                            ),
                                            onPressed: () => _abrirCadastro(p),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Cadastro Produto ───────────────────────────────────────────────

class CadastroProdutoDialog extends StatefulWidget {
  final Produto? produto;
  final ProdutoService service;
  const CadastroProdutoDialog({super.key, this.produto, required this.service});

  @override
  State<CadastroProdutoDialog> createState() => _CadastroProdutoDialogState();
}

class _CadastroProdutoDialogState extends State<CadastroProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();

  String _tipo = 'produto';
  bool _ativo = true;
  bool _salvando = false;

  List<_SubprodutoEditavel> _subprodutos = [];
  List<String> _produtosVinculados = [];
  List<Produto> _todosProdutos = [];

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _nome.text = p.nome;
      _tipo = p.tipo;
      _ativo = p.ativo;
      _subprodutos = p.subprodutos
          .map(
            (s) => _SubprodutoEditavel(
              nome: TextEditingController(text: s.nome),
              tamanho: TextEditingController(text: s.tamanho),
              descricao: TextEditingController(text: s.descricaoAdicional),
              preco: TextEditingController(text: s.preco.toStringAsFixed(2)),
            ),
          )
          .toList();
      _produtosVinculados = List<String>.from(p.produtosVinculados);
    }
    if (_subprodutos.isEmpty) _adicionarSubproduto();

    widget.service.listarProdutos(tipo: 'produto').then((lista) {
      setState(() => _todosProdutos = lista);
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    for (final s in _subprodutos) {
      s.dispose();
    }
    super.dispose();
  }

  void _adicionarSubproduto() {
    setState(() {
      _subprodutos.add(
        _SubprodutoEditavel(
          nome: TextEditingController(),
          tamanho: TextEditingController(),
          descricao: TextEditingController(),
          preco: TextEditingController(),
        ),
      );
    });
  }

  void _removerSubproduto(int index) {
    setState(() {
      _subprodutos[index].dispose();
      _subprodutos.removeAt(index);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final subprodutos = _subprodutos
          .where((s) => s.nome.text.trim().isNotEmpty)
          .map(
            (s) => Subproduto(
              nome: s.nome.text.trim(),
              tamanho: s.tamanho.text.trim(),
              descricaoAdicional: s.descricao.text.trim(),
              preco:
                  double.tryParse(s.preco.text.trim().replaceAll(',', '.')) ??
                  0,
            ),
          )
          .toList();

      await widget.service.salvarProduto(
        Produto(
          id: widget.produto?.id,
          nome: _nome.text.trim(),
          tipo: _tipo,
          subprodutos: subprodutos,
          produtosVinculados: _produtosVinculados,
          ativo: _ativo,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 780,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              widget.produto == null ? 'Novo Produto' : 'Editar Produto',
            ),
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome, Tipo e Ativo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nome,
                          decoration: const InputDecoration(
                            labelText: 'Nome do produto',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Informe o nome' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipo,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'produto',
                              child: Text('Produto'),
                            ),
                            DropdownMenuItem(
                              value: 'bebida',
                              child: Text('Bebida'),
                            ),
                            DropdownMenuItem(
                              value: 'adicional',
                              child: Text('Adicional'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _tipo = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Column(
                        children: [
                          const Text(
                            'Ativo',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Switch(
                            value: _ativo,
                            activeThumbColor: const Color(0xFFE53935),
                            onChanged: (v) => setState(() => _ativo = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_tipo == 'adicional') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Produtos vinculados',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _todosProdutos.map((p) {
                            final selecionado = _produtosVinculados.contains(
                              p.id,
                            );
                            return FilterChip(
                              label: Text(p.nome),
                              selected: selecionado,
                              selectedColor: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.15),
                              checkmarkColor: const Color(0xFFE53935),
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _produtosVinculados.add(p.id!);
                                } else {
                                  _produtosVinculados.remove(p.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Cabeçalho subprodutos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subprodutos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _adicionarSubproduto,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Header da grid
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Nome',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Tamanho/Peso/Qtd',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Descrição adicional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Preço',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Linhas de subprodutos
                  ..._subprodutos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: s.nome,
                              decoration: const InputDecoration(
                                hintText: 'Ex: Frango',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: s.tamanho,
                              decoration: const InputDecoration(
                                hintText: 'Ex: G, 2L, 500g',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: s.descricao,
                              decoration: const InputDecoration(
                                hintText: 'Ex: com catupiry',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: s.preco,
                              decoration: const InputDecoration(
                                prefixText: 'R\$ ',
                                hintText: '0,00',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: _subprodutos.length > 1
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _removerSubproduto(i),
                                    padding: EdgeInsets.zero,
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _salvando ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                        ),
                        child: _salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
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
    );
  }
}

class _SubprodutoEditavel {
  final TextEditingController nome;
  final TextEditingController tamanho;
  final TextEditingController descricao;
  final TextEditingController preco;

  _SubprodutoEditavel({
    required this.nome,
    required this.tamanho,
    required this.descricao,
    required this.preco,
  });

  void dispose() {
    nome.dispose();
    tamanho.dispose();
    descricao.dispose();
    preco.dispose();
  }
}
