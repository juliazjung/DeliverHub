import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';
import '../models/item_pedido.dart';
import '../models/produto.dart';
import '../models/cliente.dart';
import '../services/pedido_service.dart';
import '../services/produto_service.dart';
import '../services/cliente_service.dart';
import '../services/session_service.dart';
import '../services/print_service.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _service = PedidoService();
  List<Pedido> _pedidos = [];
  bool _loading = true;
  DateTime _dataFiltro = DateTime.now();
  final _filtroCliente = TextEditingController();

  List<Pedido> get _pedidosFiltrados {
    if (_filtroCliente.text.isEmpty) return _pedidos;
    return _pedidos
        .where(
          (p) => p.clienteNome.toLowerCase().contains(
            _filtroCliente.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await _service.listarPedidos(data: _dataFiltro);
    setState(() {
      _pedidos = lista;
      _loading = false;
    });
  }

  void _abrirCadastro([Pedido? pedido]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CadastroPedidoDialog(pedido: pedido, service: _service),
    );
    _carregar();
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'enviado':
        return Colors.blue;
      case 'entregue':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
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
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_dataFiltro.day.toString().padLeft(2, '0')}/'
                    '${_dataFiltro.month.toString().padLeft(2, '0')}/'
                    '${_dataFiltro.year}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: _dataFiltro,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (data != null) {
                        setState(() => _dataFiltro = data);
                        _carregar();
                      }
                    },
                    child: const Text('Alterar data'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _dataFiltro = DateTime.now());
                      _carregar();
                    },
                    child: const Text('Hoje'),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _filtroCliente,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por cliente...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirCadastro(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Pedido'),
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
                    child: _pedidos.isEmpty
                        ? const Center(child: Text('Nenhum pedido registrado.'))
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Cliente')),
                                DataColumn(label: Text('Endereço')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Pagamento')),
                                DataColumn(label: Text('Formato')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Ações')),
                                DataColumn(label: Text('Impresso')),
                              ],
                              rows: _pedidosFiltrados
                                  .map(
                                    (p) => DataRow(
                                      cells: [
                                        DataCell(Text('${p.codigoDiario}')),
                                        DataCell(Text(p.clienteNome)),
                                        DataCell(
                                          Text(
                                            '${p.clienteEndereco}, ${p.clienteNumero}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            'R\$ ${p.valorTotal.toStringAsFixed(2)}',
                                          ),
                                        ),
                                        DataCell(Text(p.formaPagamento.toUpperCase())),
                                        DataCell(Text(p.formato.toUpperCase())),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _corStatus(
                                                p.status,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              p.status.toUpperCase(),
                                              style: TextStyle(
                                                color: _corStatus(p.status),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
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
                                        DataCell(
                                          p.impresso
                                              ? IconButton(
                                                  tooltip:
                                                      p.dataImpressao != null
                                                      ? '${p.dataImpressao!.hour.toString().padLeft(2, '0')}:${p.dataImpressao!.minute.toString().padLeft(2, '0')}'
                                                      : '',
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                  onPressed: () async {
                                                    final r =
                                                        await PrintService()
                                                            .imprimirPedido(p);
                                                    if (r.sucesso) {
                                                      await _service
                                                          .marcarImpresso(
                                                            p.id!,
                                                            true,
                                                          );
                                                      _carregar();
                                                    } else if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            r.mensagem,
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              : IconButton(
                                                  tooltip: 'Imprimir',
                                                  icon: const Icon(
                                                    Icons.print,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed: () async {
                                                    final r =
                                                        await PrintService()
                                                            .imprimirPedido(p);
                                                    if (r.sucesso) {
                                                      await _service
                                                          .marcarImpresso(
                                                            p.id!,
                                                            true,
                                                          );
                                                      _carregar();
                                                    } else if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            r.mensagem,
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );
                                                    }
                                                  },
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

// ─── Dialog Cadastro Pedido ────────────────────────────────────────────────

class CadastroPedidoDialog extends StatefulWidget {
  final Pedido? pedido;
  final PedidoService service;
  const CadastroPedidoDialog({super.key, this.pedido, required this.service});

  @override
  State<CadastroPedidoDialog> createState() => _CadastroPedidoDialogState();
}

class _CadastroPedidoDialogState extends State<CadastroPedidoDialog> {
  final _produtoService = ProdutoService();
  final _clienteService = ClienteService();

  List<Produto> _produtosTipo = [];
  List<Produto> _produtosBebida = [];
  List<Produto> _adicionais = [];
  List<Cliente> _clientes = [];

  List<ItemPedido> _itens = [];
  List<ItemPedido> _bebidas = [];

  final _clienteNome = TextEditingController();
  final _clienteEndereco = TextEditingController();
  final _clienteNumero = TextEditingController();
  final _clienteComplemento = TextEditingController();
  final _clienteCidade = TextEditingController();
  final _clienteEstado = TextEditingController();
  final _freteController = TextEditingController(text: '0.00');
  final _totalController = TextEditingController(text: '0.00');
  final _horarioPreferido = TextEditingController();

  String _formaPagamento = 'indefinido';
  bool _pagouNoPedido = false;
  String _status = 'pendente';
  int _codigoDiario = 0;
  DateTime _dataHora = DateTime.now();
  bool _loading = true;
  bool _salvando = false;
  String _formato = 'entrega';

  String _cidadeEmpresa = '';
  String _estadoEmpresa = '';
  List<Cliente> _sugestoes = [];

  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    } else {
      final c = _controllers[key]!;
      if (c.text != initialValue && initialValue.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.text = initialValue;
          c.selection = TextSelection.collapsed(offset: c.text.length);
        });
      }
    }
    return _controllers[key]!;
  }

  @override
  void initState() {
    super.initState();
    _inicializar();
    _freteController.addListener(_recalcularTotal);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _freteController.dispose();
    _totalController.dispose();
    _clienteNome.dispose();
    _clienteEndereco.dispose();
    _clienteNumero.dispose();
    _clienteComplemento.dispose();
    _clienteCidade.dispose();
    _clienteEstado.dispose();
    _horarioPreferido.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await Future.wait([
      _carregarProdutos(),
      _carregarClientes(),
      _carregarEmpresa(),
    ]);

    final pedido = widget.pedido;
    if (pedido != null) {
      _codigoDiario = pedido.codigoDiario;
      _itens = pedido.itens.where((i) => i.secao != 'bebida').toList();
      _bebidas = pedido.itens.where((i) => i.secao == 'bebida').toList();
      _clienteNome.text = pedido.clienteNome;
      _clienteEndereco.text = pedido.clienteEndereco;
      _clienteNumero.text = pedido.clienteNumero;
      _clienteComplemento.text = pedido.clienteComplemento;
      _clienteCidade.text = pedido.clienteCidade;
      _clienteEstado.text = pedido.clienteEstado;
      _freteController.text = pedido.frete.toStringAsFixed(2);
      _totalController.text = pedido.valorTotal.toStringAsFixed(2);
      _formaPagamento = pedido.formaPagamento;
      _pagouNoPedido = pedido.pagouNoPedido;
      _status = pedido.status;
      _dataHora = pedido.dataHora;
      _formato = pedido.formato;
      _horarioPreferido.text = pedido.horarioPreferido ?? '';
    } else {
      _codigoDiario = await widget.service.proximoCodigoDiario();
      _clienteCidade.text = _cidadeEmpresa;
      _clienteEstado.text = _estadoEmpresa;
      _itens.add(ItemPedido(tipo: '', sabor: '', valor: 0, secao: 'item'));
      _bebidas.add(ItemPedido(tipo: '', sabor: '', valor: 0, secao: 'bebida'));
    }

    setState(() => _loading = false);
  }

  Future<void> _carregarProdutos() async {
    final todos = await _produtoService.listarProdutos();
    _produtosTipo = todos.where((p) => p.ativo && p.tipo == 'produto').toList();
    _produtosBebida = todos
        .where((p) => p.ativo && p.tipo == 'bebida')
        .toList();
    _adicionais = todos.where((p) => p.ativo && p.tipo == 'adicional').toList();
  }

  Future<void> _carregarClientes() async {
    _clientes = await _clienteService.listarClientes();
  }

  Future<void> _carregarEmpresa() async {
    final empresaId = SessionService().empresaId;
    if (empresaId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .get();
    _cidadeEmpresa = doc.data()?['cidade'] ?? '';
    _estadoEmpresa = doc.data()?['estado'] ?? '';
  }

  void _buscarSugestoes(String query) {
    if (query.isEmpty) {
      setState(() => _sugestoes = []);
      return;
    }
    setState(() {
      _sugestoes = _clientes
          .where((c) => c.nome.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
    });
  }

  void _selecionarCliente(Cliente c) {
    setState(() {
      _clienteNome.text = c.nome;
      _clienteEndereco.text = c.endereco;
      _clienteNumero.text = c.numero;
      _clienteComplemento.text = c.complemento;
      _clienteCidade.text = c.cidade;
      _clienteEstado.text = c.estado;
      _sugestoes = [];
    });
  }

  void _recalcularTotal() {
    final somaItens = _itens.fold(0.0, (s, i) => s + (i.valor + _somaAdicionais(i)) * i.quantidade);
    final somaBebidas = _bebidas.fold(0.0, (s, i) => s + i.valor * i.quantidade);

    final frete =
        double.tryParse(_freteController.text.replaceAll(',', '.')) ?? 0;
    _totalController.text = (somaItens + somaBebidas + frete).toStringAsFixed(
      2,
    );
  }

  void _atualizarItem(int index, ItemPedido item, {bool isBebida = false}) {
    final lista = isBebida ? _bebidas : _itens;
    setState(() {
      lista[index] = item;
      if (index == lista.length - 1 &&
          (item.tipo.isNotEmpty || item.sabor.isNotEmpty)) {
        lista.add(ItemPedido(tipo: '', sabor: '', valor: 0, secao: item.secao));
      }
    });
    _recalcularTotal();
  }

  void _removerItem(int index, {bool isBebida = false}) {
    setState(() => (isBebida ? _bebidas : _itens).removeAt(index));
    _recalcularTotal();
  }

  double _somaAdicionais(ItemPedido item) {
    double soma = 0;
    for (final nomeAdicional in item.adicionais) {
      final partes = nomeAdicional.split(': ');
      final nomeGrupo = partes[0];
      final nomeSub = partes.length > 1 ? partes[1] : null;

      final grupo = _adicionais.where((a) => a.nome == nomeGrupo).firstOrNull;
      if (grupo == null) continue;

      if (nomeSub != null) {
        final sub = grupo.subprodutos
            .where((s) => s.nomeCompleto == nomeSub)
            .firstOrNull;
        if (sub != null) soma += sub.preco;
      }
      // adicional sem subproduto: precisaria ter preco direto no Produto
      // por enquanto só subprodutos têm preço
    }
    return soma;
  }

  Future<void> _salvar() async {
    if (_clienteNome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do cliente!')),
      );
      return;
    }
    final itensFiltrados = [
      ..._itens.where((i) => i.tipo.isNotEmpty || i.sabor.isNotEmpty),
      ..._bebidas.where((i) => i.sabor.isNotEmpty),
    ];
    if (itensFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um item!')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      String? clienteId;
      final clienteExistente = await _clienteService.buscarPorNome(
        _clienteNome.text.trim(),
      );
      if (clienteExistente != null) {
        clienteId = clienteExistente.id;
        await _clienteService.salvarCliente(
          Cliente(
            id: clienteExistente.id,
            nome: _clienteNome.text.trim(),
            endereco: _clienteEndereco.text.trim(),
            numero: _clienteNumero.text.trim(),
            complemento: _clienteComplemento.text.trim(),
            cidade: _clienteCidade.text.trim(),
            estado: _clienteEstado.text.trim(),
            cpf: clienteExistente.cpf,
          ),
        );
      } else {
        clienteId = await _clienteService.salvarCliente(
          Cliente(
            nome: _clienteNome.text.trim(),
            endereco: _clienteEndereco.text.trim(),
            numero: _clienteNumero.text.trim(),
            complemento: _clienteComplemento.text.trim(),
            cidade: _clienteCidade.text.trim(),
            estado: _clienteEstado.text.trim(),
            cpf: '',
          ),
        );
      }

      final frete =
          double.tryParse(_freteController.text.replaceAll(',', '.')) ?? 0;
      final total =
          double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0;

      final pedido = Pedido(
        id: widget.pedido?.id,
        codigoDiario: _codigoDiario,
        itens: itensFiltrados,
        clienteId: clienteId,
        clienteNome: _clienteNome.text.trim(),
        clienteEndereco: _clienteEndereco.text.trim(),
        clienteNumero: _clienteNumero.text.trim(),
        clienteComplemento: _clienteComplemento.text.trim(),
        clienteCidade: _clienteCidade.text.trim(),
        clienteEstado: _clienteEstado.text.trim(),
        frete: frete,
        valorTotal: total,
        formaPagamento: _formaPagamento,
        pagouNoPedido: _pagouNoPedido,
        dataHora: _dataHora,
        status: _status,
        formato: _formato,
        horarioPreferido: _horarioPreferido.text.trim().isEmpty
            ? null
            : _horarioPreferido.text.trim(),
      );

      await widget.service.salvarPedido(pedido);
      if (mounted) {
        Navigator.pop(context);
        await _tentarImprimir(pedido);
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

  bool get _podeCancelar =>
      widget.pedido != null && (_status == 'pendente' || _status == 'enviado');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Pedido #$_codigoDiario'),
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Itens do Pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGridItens(),
                      const SizedBox(height: 24),

                      const Text(
                        'Bebidas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGridBebidas(),
                      const SizedBox(height: 24),

                      const Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCampoCliente(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _campoTexto(_clienteEndereco, 'Endereço'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _campoTexto(_clienteNumero, 'Número'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _campoTexto(
                              _clienteComplemento,
                              'Complemento',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _campoTexto(_clienteCidade, 'Cidade'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _campoTexto(_clienteEstado, 'Estado'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Pagamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _formaPagamento,
                              decoration: const InputDecoration(
                                labelText: 'Forma de Pagamento',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'indefinido',
                                  child: Text('Indefinido'),
                                ),
                                DropdownMenuItem(
                                  value: 'dinheiro',
                                  child: Text('Dinheiro'),
                                ),
                                DropdownMenuItem(
                                  value: 'pix',
                                  child: Text('Pix'),
                                ),
                                DropdownMenuItem(
                                  value: 'cartao',
                                  child: Text('Cartão'),
                                ),
                                DropdownMenuItem(
                                  value: 'caderno',
                                  child: Text('Caderno'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _formaPagamento = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _campoTexto(_freteController, 'Frete (R\$)'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _campoTexto(_totalController, 'Total (R\$)'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _formato,
                              decoration: const InputDecoration(
                                labelText: 'Formato',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'entrega',
                                  child: Text('Entrega'),
                                ),
                                DropdownMenuItem(
                                  value: 'retirada',
                                  child: Text('Retirada'),
                                ),
                                DropdownMenuItem(
                                  value: 'comer',
                                  child: Text('Comer'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _formato = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pendente',
                                  child: Text('Pendente'),
                                ),
                                DropdownMenuItem(
                                  value: 'enviado',
                                  child: Text('Enviado'),
                                ),
                                DropdownMenuItem(
                                  value: 'entregue',
                                  child: Text('Entregue'),
                                ),
                                DropdownMenuItem(
                                  value: 'cancelado',
                                  child: Text('Cancelado'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _pagouNoPedido,
                            activeColor: const Color(0xFFE53935),
                            onChanged: (v) =>
                                setState(() => _pagouNoPedido = v!),
                          ),
                          const Text('Pagou no caixa'),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _horarioPreferido,
                              decoration: const InputDecoration(
                                labelText: 'Horário preferido',
                                hintText: 'Ex: 19:30',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            'Data: ${_dataHora.day.toString().padLeft(2, '0')}/${_dataHora.month.toString().padLeft(2, '0')}/${_dataHora.year} '
                            '${_dataHora.hour.toString().padLeft(2, '0')}:${_dataHora.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          if (_podeCancelar)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancelar pedido'),
                                    content: const Text(
                                      'Tem certeza que deseja cancelar este pedido?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Não'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Sim, cancelar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmar == true) {
                                  setState(() => _status = 'cancelado');
                                  await _salvar();
                                }
                              },
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Cancelar Pedido',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          const Spacer(),
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
                                vertical: 16,
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
    );
  }

  // ── Campo cliente ───────────────────────────────────────────────────────────

  Widget _buildCampoCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _clienteNome,
          decoration: const InputDecoration(
            labelText: 'Nome do cliente',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _buscarSugestoes,
        ),
        if (_sugestoes.isNotEmpty)
          Card(
            elevation: 4,
            child: Column(
              children: _sugestoes
                  .map(
                    (c) => ListTile(
                      title: Text(c.nome),
                      subtitle: Text(
                        '${c.endereco}, ${c.numero} - ${c.cidade}',
                      ),
                      onTap: () => _selecionarCliente(c),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  // ── Grid Itens ─────────────────────────────────────────────────────────────

  Widget _buildGridItens() {
    return Card(
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Produto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Subproduto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Adicionais',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Qtd',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Valor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Observação',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itens.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _buildLinhaItem(i),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaItem(int index) {
    final item = _itens[index];
    final produtoSelecionado = _produtosTipo
        .where((p) => p.id == item.produtoId)
        .firstOrNull;
    final subprodutos = produtoSelecionado?.subprodutos ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Produto — Autocomplete digitável
          Expanded(
            flex: 2,
            child: Autocomplete<Produto>(
              key: ValueKey('prod_$index'),
              initialValue: TextEditingValue(text: item.tipo),
              displayStringForOption: (p) => p.nome,
              optionsBuilder: (v) {
                if (v.text.isEmpty) return _produtosTipo;
                return _produtosTipo.where(
                  (p) => p.nome.toLowerCase().contains(v.text.toLowerCase()),
                );
              },
              onSelected: (p) {
                _atualizarItem(
                  index,
                  item.copyWith(
                    produtoId: p.id,
                    tipo: p.nome,
                    clearProdutoId: false,
                    sabor: '',
                    valor: 0,
                  ),
                );
              },
              fieldViewBuilder: (ctx, ctrl, fn, onSub) => TextFormField(
                controller: ctrl,
                focusNode: fn,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Produto...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) => _atualizarItem(
                  index,
                  item.copyWith(
                    tipo: v,
                    clearProdutoId: true,
                    sabor: '',
                    valor: 0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Subproduto — Autocomplete digitável, filtra pelo produto selecionado
          Expanded(
            flex: 2,
            child: Autocomplete<Subproduto>(
              key: ValueKey('sub_${index}_${item.produtoId}'),
              initialValue: TextEditingValue(text: item.sabor),
              displayStringForOption: (s) => s.nomeCompleto,
              optionsBuilder: (v) {
                if (subprodutos.isEmpty) return const [];
                if (v.text.isEmpty) return subprodutos;
                return subprodutos.where(
                  (s) => s.nomeCompleto.toLowerCase().contains(
                    v.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (s) {
                _atualizarItem(
                  index,
                  item.copyWith(sabor: s.nomeCompleto, valor: s.preco),
                );
              },
              fieldViewBuilder: (ctx, ctrl, fn, onSub) => TextFormField(
                controller: ctrl,
                focusNode: fn,
                style: const TextStyle(fontSize: 13),
                enabled: produtoSelecionado != null,
                decoration: InputDecoration(
                  hintText: produtoSelecionado == null
                      ? 'Selecione o produto'
                      : 'Subproduto...',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) =>
                    _atualizarItem(index, item.copyWith(sabor: v)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Adicionais
          Expanded(flex: 3, child: _buildAdicionais(index, item)),
          const SizedBox(width: 8),

          // Qtd
          SizedBox(
            width: 50,
            child: TextFormField(
              key: ValueKey('qtd_$index${item.quantidade}'),
              initialValue: '${item.quantidade}',
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _atualizarItem(
                index,
                item.copyWith(quantidade: int.tryParse(v) ?? 1),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Valor
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: _getController(
                'valor_$index',
                item.valor > 0 ? item.valor.toStringAsFixed(2) : '',
              ),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _atualizarItem(
                index,
                item.copyWith(
                  valor: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Total
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'R\$ ${((item.valor + _somaAdicionais(item)) * item.quantidade).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Observação
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('obs_$index'),
              initialValue: item.observacao,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) =>
                  _atualizarItem(index, item.copyWith(observacao: v)),
            ),
          ),
          const SizedBox(width: 4),

          // Remover
          SizedBox(
            width: 36,
            child: _itens.length > 1
                ? IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _removerItem(index),
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ── Grid Bebidas ────────────────────────────────────────────────────────────

  Widget _buildGridBebidas() {
    return Card(
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Bebida',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Subproduto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Qtd',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Valor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bebidas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _buildLinhaBebida(i),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaBebida(int index) {
    final item = _bebidas[index];
    final produtoSelecionado = _produtosBebida
        .where((p) => p.id == item.produtoId)
        .firstOrNull;
    final subprodutos = produtoSelecionado?.subprodutos ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Bebida — Autocomplete digitável
          Expanded(
            flex: 2,
            child: Autocomplete<Produto>(
              key: ValueKey('bprod_$index'),
              initialValue: TextEditingValue(text: item.tipo),
              displayStringForOption: (p) => p.nome,
              optionsBuilder: (v) {
                if (v.text.isEmpty) return _produtosBebida;
                return _produtosBebida.where(
                  (p) => p.nome.toLowerCase().contains(v.text.toLowerCase()),
                );
              },
              onSelected: (p) {
                _atualizarItem(
                  index,
                  item.copyWith(
                    produtoId: p.id,
                    tipo: p.nome,
                    clearProdutoId: false,
                    sabor: '',
                    valor: 0,
                    secao: 'bebida',
                  ),
                  isBebida: true,
                );
              },
              fieldViewBuilder: (ctx, ctrl, fn, onSub) => TextFormField(
                controller: ctrl,
                focusNode: fn,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Bebida...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) => _atualizarItem(
                  index,
                  item.copyWith(
                    tipo: v,
                    clearProdutoId: true,
                    sabor: '',
                    valor: 0,
                    secao: 'bebida',
                  ),
                  isBebida: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Subproduto bebida — Autocomplete digitável
          Expanded(
            flex: 2,
            child: Autocomplete<Subproduto>(
              key: ValueKey('bsub_${index}_${item.produtoId}'),
              initialValue: TextEditingValue(text: item.sabor),
              displayStringForOption: (s) => s.nomeCompleto,
              optionsBuilder: (v) {
                if (subprodutos.isEmpty) return const [];
                if (v.text.isEmpty) return subprodutos;
                return subprodutos.where(
                  (s) => s.nomeCompleto.toLowerCase().contains(
                    v.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (s) {
                _atualizarItem(
                  index,
                  item.copyWith(
                    sabor: s.nomeCompleto,
                    valor: s.preco,
                    secao: 'bebida',
                  ),
                  isBebida: true,
                );
              },
              fieldViewBuilder: (ctx, ctrl, fn, onSub) => TextFormField(
                controller: ctrl,
                focusNode: fn,
                style: const TextStyle(fontSize: 13),
                enabled: produtoSelecionado != null,
                decoration: InputDecoration(
                  hintText: produtoSelecionado == null
                      ? 'Selecione a bebida'
                      : 'Subproduto...',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) => _atualizarItem(
                  index,
                  item.copyWith(sabor: v, secao: 'bebida'),
                  isBebida: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Qtd
          SizedBox(
            width: 50,
            child: TextFormField(
              key: ValueKey('bqtd_$index${item.quantidade}'),
              initialValue: '${item.quantidade}',
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _atualizarItem(
                index,
                item.copyWith(
                  quantidade: int.tryParse(v) ?? 1,
                  secao: 'bebida',
                ),
                isBebida: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Valor
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: _getController(
                'bvalor_$index',
                item.valor > 0 ? item.valor.toStringAsFixed(2) : '',
              ),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _atualizarItem(
                index,
                item.copyWith(
                  valor: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                  secao: 'bebida',
                ),
                isBebida: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Total
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'R\$ ${(item.valor * item.quantidade).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Remover
          SizedBox(
            width: 36,
            child: _bebidas.length > 1
                ? IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _removerItem(index, isBebida: true),
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  // ── Adicionais ─────────────────────────────────────────────────────────────

  Widget _buildAdicionais(int index, ItemPedido item) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (_) => _AdicionaisDialog(
            adicionais: item.produtoId == null
              ? _adicionais
              : _adicionais.where((a) =>
                  a.produtosVinculados.isEmpty ||
                  a.produtosVinculados.contains(item.produtoId)).toList(),
            selecionados: List<String>.from(item.adicionais),
            onConfirmar: (lista) =>
                _atualizarItem(index, item.copyWith(adicionais: lista)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          item.adicionais.isEmpty
              ? 'Nenhum adicional'
              : item.adicionais.join(', '),
          style: TextStyle(
            fontSize: 13,
            color: item.adicionais.isEmpty ? Colors.grey : Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _campoTexto(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Future<void> _tentarImprimir(Pedido pedido) async {
    final resultado = await PrintService().imprimirPedido(pedido);
    if (resultado.sucesso) {
      if (pedido.id != null) {
        await widget.service.marcarImpresso(pedido.id!, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.print_disabled, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(resultado.mensagem)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

// ─── Dialog Adicionais ─────────────────────────────────────────────────────

class _AdicionaisDialog extends StatefulWidget {
  final List<Produto> adicionais;
  final List<String> selecionados;
  final Function(List<String>) onConfirmar;

  const _AdicionaisDialog({
    required this.adicionais,
    required this.selecionados,
    required this.onConfirmar,
  });

  @override
  State<_AdicionaisDialog> createState() => _AdicionaisDialogState();
}

class _AdicionaisDialogState extends State<_AdicionaisDialog> {
  late Map<String, Set<String>> _selecao;

  @override
  void initState() {
    super.initState();
    _selecao = {};
    for (final adicional in widget.adicionais) {
      _selecao[adicional.nome] = {};
      for (final sub in adicional.subprodutos) {
        final chave1 = '${adicional.nome}: ${sub.nomeCompleto}';
        final chave2 = sub.nomeCompleto;
        if (widget.selecionados.contains(chave1) ||
            widget.selecionados.contains(chave2)) {
          _selecao[adicional.nome]!.add(sub.nomeCompleto);
        }
      }
      if (adicional.subprodutos.isEmpty &&
          widget.selecionados.contains(adicional.nome)) {
        _selecao[adicional.nome]!.add(adicional.nome);
      }
    }
  }

  List<String> get _listaSelecionados {
    final result = <String>[];
    for (final adicional in widget.adicionais) {
      final subs = _selecao[adicional.nome] ?? {};
      for (final sub in subs) {
        result.add(
          adicional.subprodutos.isEmpty ? sub : '${adicional.nome}: $sub',
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionais'),
      content: SizedBox(
        width: 400,
        child: widget.adicionais.isEmpty
            ? const Text('Nenhum adicional cadastrado.')
            : ListView(
                shrinkWrap: true,
                children: widget.adicionais.map((a) {
                  if (a.subprodutos.isEmpty) {
                    return CheckboxListTile(
                      title: Text(a.nome),
                      value: (_selecao[a.nome] ?? {}).isNotEmpty,
                      activeColor: const Color(0xFFE53935),
                      onChanged: (v) => setState(() {
                        _selecao[a.nome] = v == true ? {a.nome} : {};
                      }),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                        child: Text(
                          a.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...a.subprodutos.map(
                        (s) => CheckboxListTile(
                          title: Text(
                            s.descricaoAdicional.isNotEmpty
                                ? '${s.nomeCompleto} - ${s.descricaoAdicional}'
                                : s.nomeCompleto,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            'R\$ ${s.preco.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: (_selecao[a.nome] ?? {}).contains(
                            s.nomeCompleto,
                          ),
                          activeColor: const Color(0xFFE53935),
                          onChanged: (v) => setState(() {
                            _selecao[a.nome] ??= {};
                            if (v == true) {
                              _selecao[a.nome]!.add(s.nomeCompleto);
                            } else {
                              _selecao[a.nome]!.remove(s.nomeCompleto);
                            }
                          }),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirmar(_listaSelecionados);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
