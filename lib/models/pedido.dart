import 'item_pedido.dart';

class Pedido {
  final String? id;
  final int codigoDiario;
  final List<ItemPedido> itens;
  final String? clienteId;
  final String clienteNome;
  final String clienteEndereco;
  final String clienteNumero;
  final String clienteComplemento;
  final String clienteCidade;
  final String clienteEstado;
  final double frete;
  final double valorTotal;
  final String formaPagamento;
  final bool pagouNoPedido;
  final DateTime dataHora;
  final String status;
  final bool impresso;
  final DateTime? dataImpressao;
  final String formato;
  final String? horarioPreferido;
  final String? entregador;
  final String? empresaId;

  Pedido({
    this.id,
    required this.codigoDiario,
    required this.itens,
    this.clienteId,
    required this.clienteNome,
    required this.clienteEndereco,
    required this.clienteNumero,
    this.clienteComplemento = '',
    required this.clienteCidade,
    required this.clienteEstado,
    required this.frete,
    required this.valorTotal,
    required this.formaPagamento,
    required this.pagouNoPedido,
    required this.dataHora,
    required this.status,
    this.impresso = false,
    this.dataImpressao,
    this.formato = 'entrega',
    this.horarioPreferido,
    this.entregador,
    this.empresaId,
  });

  Map<String, dynamic> toMap() => {
    'codigoDiario': codigoDiario,
    'itens': itens.map((i) => i.toMap()).toList(),
    'clienteId': clienteId,
    'clienteNome': clienteNome,
    'clienteEndereco': clienteEndereco,
    'clienteNumero': clienteNumero,
    'clienteComplemento': clienteComplemento,
    'clienteCidade': clienteCidade,
    'clienteEstado': clienteEstado,
    'frete': frete,
    'valorTotal': valorTotal,
    'formaPagamento': formaPagamento,
    'pagouNoPedido': pagouNoPedido,
    'dataHora': dataHora.toIso8601String(),
    'status': status,
    'impresso': impresso,
    'dataImpressao': dataImpressao?.toIso8601String(),
    'formato': formato,
    'horarioPreferido': horarioPreferido,
    'entregador': entregador,
    'empresaId': empresaId,
  };

  factory Pedido.fromMap(String id, Map<String, dynamic> map) => Pedido(
    id: id,
    codigoDiario: map['codigoDiario'] ?? 0,
    itens: (map['itens'] as List<dynamic>? ?? [])
        .map((i) => ItemPedido.fromMap(i))
        .toList(),
    clienteId: map['clienteId'],
    clienteNome: map['clienteNome'] ?? '',
    clienteEndereco: map['clienteEndereco'] ?? '',
    clienteNumero: map['clienteNumero'] ?? '',
    clienteComplemento: map['clienteComplemento'] ?? '',
    clienteCidade: map['clienteCidade'] ?? '',
    clienteEstado: map['clienteEstado'] ?? '',
    frete: (map['frete'] ?? 0).toDouble(),
    valorTotal: (map['valorTotal'] ?? 0).toDouble(),
    formaPagamento: map['formaPagamento'] ?? 'dinheiro',
    pagouNoPedido: map['pagouNoPedido'] ?? false,
    dataHora: DateTime.parse(map['dataHora']),
    status: map['status'] ?? 'pendente',
    impresso: map['impresso'] ?? false,
    dataImpressao: map['dataImpressao'] != null
        ? DateTime.parse(map['dataImpressao'])
        : null,
    formato: map['formato'] ?? 'entrega',
    horarioPreferido: map['horarioPreferido'],
    entregador: map['entregador'],
    empresaId: map['empresaId'],
  );
}