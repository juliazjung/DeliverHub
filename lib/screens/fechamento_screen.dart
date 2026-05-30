import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';

class FechamentoScreen extends StatefulWidget {
  const FechamentoScreen({super.key});

  @override
  State<FechamentoScreen> createState() => _FechamentoScreenState();
}

class _FechamentoScreenState extends State<FechamentoScreen> {
  final _service = PedidoService();
  List<Pedido> _pedidos = [];
  bool _loading = true;
  DateTime _dataFiltro = DateTime.now();

  // Pedido com itens expandidos
  String? _pedidoExpandido;

  // Controllers inline para edição
  final Map<String, TextEditingController> _entregadorControllers = {};
  final Map<String, String> _pagamentoTemp = {};
  final Map<String, TextEditingController> _valorRecebidoControllers = {};
  final Map<String, TextEditingController> _valorInicialControllers = {};

  // Controllers fechamento de caixa
  final _dinheiroCaixaController = TextEditingController();
  final _valorRecebidoTotalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in _entregadorControllers.values) c.dispose();
    for (final c in _valorRecebidoControllers.values) c.dispose();
    for (final c in _valorInicialControllers.values) c.dispose();
    _dinheiroCaixaController.dispose();
    _valorRecebidoTotalController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await _service.listarPedidosFechamento(data: _dataFiltro);
    setState(() {
      _pedidos = lista;
      _entregadorControllers.clear();
      _pagamentoTemp.clear();
      for (final p in lista) {
        _entregadorControllers[p.id!] = TextEditingController(
          text: p.entregador ?? '',
        );
        _pagamentoTemp[p.id!] = p.formaPagamento;
      }
      _loading = false;
    });
    await _carregarDadosEntregadores();
  }

  Future<void> _salvarLinha(Pedido pedido) async {
    final entregador = _entregadorControllers[pedido.id!]?.text.trim() ?? '';
    final pagamento = _pagamentoTemp[pedido.id!] ?? pedido.formaPagamento;
    await _service.atualizarEntregadorPagamento(
      pedido.id!,
      entregador,
      pagamento,
    );
  }

  // ── Cálculos ───────────────────────────────────────────────────────────────

  List<Pedido> get _pedidosEntrega =>
      _pedidos.where((p) => p.formato == 'entrega').toList();

  List<Pedido> get _pedidosRetiradaComer =>
      _pedidos.where((p) => p.formato != 'entrega').toList();

  Map<String, List<Pedido>> get _porEntregador {
    final Map<String, List<Pedido>> mapa = {};
    for (final p in _pedidosEntrega) {
      final entregador = _entregadorControllers[p.id!]?.text.trim() ?? '';
      final key = entregador.isEmpty ? '(sem entregador)' : entregador;
      mapa.putIfAbsent(key, () => []).add(p);
    }
    return mapa;
  }

  Map<String, double> _totalPorPagamento(List<Pedido> lista) {
    final Map<String, double> mapa = {};
    for (final p in lista) {
      final pag = _pagamentoTemp[p.id!] ?? p.formaPagamento;
      mapa[pag] = (mapa[pag] ?? 0) + p.valorTotal;
    }
    return mapa;
  }

  double _somarTotal(List<Pedido> lista) =>
      lista.fold(0.0, (sum, p) => sum + p.valorTotal);

  // Dinheiro pago no caixa: pagouNoPedido == true E pagamento == dinheiro
  double get _dinheiroPagoCaixa => _pedidos
      .where(
        (p) =>
            p.pagouNoPedido &&
            (_pagamentoTemp[p.id!] ?? p.formaPagamento) == 'dinheiro',
      )
      .fold(0.0, (s, p) => s + p.valorTotal);

  // Dinheiro entregas: pagamento == dinheiro E formato == entrega
  double get _dinheiroEntregas => _pedidos
      .where(
        (p) =>
            (_pagamentoTemp[p.id!] ?? p.formaPagamento) == 'dinheiro' &&
            p.formato == 'entrega',
      )
      .fold(0.0, (s, p) => s + p.valorTotal);

  double get _dinheiroCaixa =>
      double.tryParse(_dinheiroCaixaController.text.replaceAll(',', '.')) ?? 0;

  double get _valorRecebidoTotal =>
      double.tryParse(
        _valorRecebidoTotalController.text.replaceAll(',', '.'),
      ) ??
      0;

  double get _saldo =>
      _dinheiroPagoCaixa +
      _dinheiroEntregas +
      _dinheiroCaixa -
      _valorRecebidoTotal;

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
          // ── Filtro de data ──
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
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
          const SizedBox(height: 16),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGridPedidos(),
                        const SizedBox(height: 32),
                        _buildResumoEntregadores(),
                        const SizedBox(height: 32),
                        _buildFechamentoCaixa(),
                        const SizedBox(height: 32),
                        _buildTotaisGerais(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Grid de pedidos ────────────────────────────────────────────────────────

  Widget _buildGridPedidos() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pedidos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _pedidos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum pedido encontrado.')),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Itens')),
                      DataColumn(label: Text('Formato')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Valor')),
                      DataColumn(label: Text('Pago no caixa')),
                      DataColumn(label: Text('Pagamento')),
                      DataColumn(label: Text('Entregador')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: _pedidos.expand((p) {
                      final expandido = _pedidoExpandido == p.id;
                      final linhas = <DataRow>[];

                      // Linha principal
                      linhas.add(
                        DataRow(
                          cells: [
                            DataCell(Text('${p.codigoDiario}')),
                            DataCell(Text(p.clienteNome)),

                            // Botão para expandir itens
                            DataCell(
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _pedidoExpandido = expandido ? null : p.id;
                                }),
                                icon: Icon(
                                  expandido
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                ),
                                label: Text(
                                  '${p.itens.length} item(s)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE53935),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                            DataCell(Text(p.formato.toUpperCase())),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _corStatus(p.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
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
                              Text('R\$ ${p.valorTotal.toStringAsFixed(2)}'),
                            ),
                            DataCell(Text(p.pagouNoPedido ? 'Sim' : 'Não')),

                            // Pagamento editável
                            DataCell(
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _pagamentoTemp[p.id!],
                                  isDense: true,
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
                                    DropdownMenuItem(
                                      value: 'outros',
                                      child: Text('Outros'),
                                    ),
                                  ],
                                  onChanged: (v) => setState(
                                    () => _pagamentoTemp[p.id!] = v!,
                                  ),
                                ),
                              ),
                            ),

                            // Entregador editável
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _entregadorControllers[p.id!],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),

                            DataCell(
                              IconButton(
                                icon: const Icon(
                                  Icons.save,
                                  color: Color(0xFFE53935),
                                  size: 20,
                                ),
                                tooltip: 'Salvar',
                                onPressed: () async {
                                  await _salvarLinha(p);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Salvo com sucesso!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );

                      // Linha expandida com itens
                      if (expandido) {
                        linhas.add(
                          DataRow(
                            color: WidgetStateProperty.all(Colors.grey.shade50),
                            cells: [
                              const DataCell(SizedBox()),
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: p.itens.map((item) {
                                      final adicionais =
                                          item.adicionais.isNotEmpty
                                          ? '  + ${item.adicionais.join(', ')}'
                                          : '';
                                      final obs = item.observacao.isNotEmpty
                                          ? '  Obs: ${item.observacao}'
                                          : '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.quantidade}x ${item.tipo} ${item.sabor}  R\$ ${(item.valor * item.quantidade).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (adicionais.isNotEmpty)
                                              Text(
                                                adicionais,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            if (obs.isNotEmpty)
                                              Text(
                                                obs,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                              const DataCell(SizedBox()),
                            ],
                          ),
                        );
                      }

                      return linhas;
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Resumo por entregador ──────────────────────────────────────────────────

  Widget _buildResumoEntregadores() {
    final porEntregador = _porEntregador;
    if (porEntregador.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo por Entregador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...porEntregador.entries.map((entry) {
              final nome = entry.key;
              final pedidos = entry.value;
              final totaisPag = _totalPorPagamento(pedidos);
              final totalGeral = _somarTotal(pedidos);
              final isSemEntregador = nome == '(sem entregador)';

              if (!isSemEntregador) {
                _valorRecebidoControllers.putIfAbsent(
                  nome,
                  () => TextEditingController(),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFFE53935),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${pedidos.length} entrega(s)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: totaisPag.entries
                          .map(
                            (e) => Text(
                              '${e.key}: R\$ ${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: R\$ ${totalGeral.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (!isSemEntregador) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _valorInicialControllers[nome],
                              decoration: const InputDecoration(
                                labelText: 'Valor inicial (R\$)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixText: 'R\$ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _valorRecebidoControllers[nome],
                              decoration: const InputDecoration(
                                labelText: 'Valor recebido (R\$)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixText: 'R\$ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),

                          ElevatedButton.icon(
                            onPressed: () async {
                              await _salvarDadosEntregador(nome);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dados salvos!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Salvar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Fechamento de caixa ────────────────────────────────────────────────────

  Widget _buildFechamentoCaixa() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        final saldo = _saldo;
        final corSaldo = saldo >= 0 ? Colors.green : Colors.red;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fechamento de Caixa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Totais calculados
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildItemCaixa(
                      'Dinheiro pago no caixa',
                      _dinheiroPagoCaixa,
                      Colors.blue,
                      'Pedidos pagos no caixa + dinheiro',
                    ),
                    _buildItemCaixa(
                      'Dinheiro entregas',
                      _dinheiroEntregas,
                      Colors.teal,
                      'Entregas com pagamento em dinheiro',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campos manuais
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _dinheiroCaixaController,
                        decoration: const InputDecoration(
                          labelText: 'Dinheiro caixa (inicial)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _valorRecebidoTotalController,
                        decoration: const InputDecoration(
                          labelText: 'Valor recebido total',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Somar valores recebidos dos entregadores',
                      child: IconButton(
                        icon: const Icon(
                          Icons.calculate,
                          color: Color(0xFFE53935),
                        ),
                        onPressed: _calcularValorRecebidoTotal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Saldo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corSaldo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corSaldo.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        saldo >= 0 ? Icons.check_circle : Icons.warning,
                        color: corSaldo,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo',
                            style: TextStyle(
                              color: corSaldo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'R\$ ${saldo.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: corSaldo,
                            ),
                          ),
                          Text(
                            'Pago caixa + Entregas dinheiro + Caixa inicial − Recebido total',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCaixa(
    String label,
    double valor,
    Color cor,
    String subtitulo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            subtitulo,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ── Totais gerais ──────────────────────────────────────────────────────────

  Widget _buildTotaisGerais() {
    final totalEntregas = _somarTotal(_pedidosEntrega);
    final totalRetiradaComer = _somarTotal(_pedidosRetiradaComer);
    final totalGeral = totalEntregas + totalRetiradaComer;
    final totaisPagGeral = _totalPorPagamento(_pedidos);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totais Gerais',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCardTotal('Entregas', totalEntregas, Colors.blue),
                const SizedBox(width: 16),
                _buildCardTotal(
                  'Retirada / Comer',
                  totalRetiradaComer,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildCardTotal(
                  'Total Geral',
                  totalGeral,
                  const Color(0xFFE53935),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Por forma de pagamento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: totaisPagGeral.entries
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'R\$ ${e.value.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTotal(String label, double valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: cor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auxiliares ─────────────────────────────────────────────────────────────

  Future<void> _carregarDadosEntregadores() async {
    final dataStr =
        '${_dataFiltro.year}'
        '${_dataFiltro.month.toString().padLeft(2, '0')}'
        '${_dataFiltro.day.toString().padLeft(2, '0')}';

    for (final entregador in _porEntregador.keys) {
      if (entregador == '(sem entregador)') continue;
      final dados = await _service.buscarDadosEntregador(
        data: dataStr,
        entregador: entregador,
      );
      _valorRecebidoControllers[entregador] = TextEditingController(
        text: dados?['valorRecebido']?.toStringAsFixed(2) ?? '',
      );
      _valorInicialControllers[entregador] = TextEditingController(
        text: dados?['valorInicial']?.toStringAsFixed(2) ?? '',
      );
    }
    setState(() {});
  }

  Future<void> _salvarDadosEntregador(String entregador) async {
    final dataStr =
        '${_dataFiltro.year}'
        '${_dataFiltro.month.toString().padLeft(2, '0')}'
        '${_dataFiltro.day.toString().padLeft(2, '0')}';

    await _service.salvarDadosEntregador(
      data: dataStr,
      entregador: entregador,
      valorRecebido:
          double.tryParse(
            _valorRecebidoControllers[entregador]?.text.replaceAll(',', '.') ??
                '0',
          ) ??
          0,
      valorInicial:
          double.tryParse(
            _valorInicialControllers[entregador]?.text.replaceAll(',', '.') ??
                '0',
          ) ??
          0,
    );
  }

  void _calcularValorRecebidoTotal() {
    double soma = 0;
    for (final entry in _valorInicialControllers.entries) {
      if (entry.key == '(sem entregador)') continue;
      soma += double.tryParse(entry.value.text.replaceAll(',', '.')) ?? 0;
    }
    for (final entry in _valorRecebidoControllers.entries) {
      if (entry.key == '(sem entregador)') continue;
      soma += double.tryParse(entry.value.text.replaceAll(',', '.')) ?? 0;
    }
    setState(() {
      _valorRecebidoTotalController.text = soma.toStringAsFixed(2);
    });
  }
}
