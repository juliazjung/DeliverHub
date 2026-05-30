class ItemPedido {
  final String? produtoId;
  final String tipo;
  final String sabor;
  final List<String> adicionais;
  final double valor;
  final String observacao;
  final int quantidade;
  final String secao; // 'item' ou 'bebida'

  ItemPedido({
    this.produtoId,
    required this.tipo,
    required this.sabor,
    this.adicionais = const [],
    required this.valor,
    this.observacao = '',
    this.quantidade = 1,
    this.secao = 'item',
  });

  Map<String, dynamic> toMap() => {
    'produtoId': produtoId,
    'tipo': tipo,
    'sabor': sabor,
    'adicionais': adicionais,
    'valor': valor,
    'observacao': observacao,
    'quantidade': quantidade,
    'secao': secao,
  };

  factory ItemPedido.fromMap(Map<String, dynamic> map) => ItemPedido(
    produtoId: map['produtoId'],
    tipo: map['tipo'] ?? '',
    sabor: map['sabor'] ?? '',
    adicionais: List<String>.from(map['adicionais'] ?? []),
    valor: (map['valor'] ?? 0).toDouble(),
    observacao: map['observacao'] ?? '',
    quantidade: (map['quantidade'] ?? 1).toInt(),
    secao: map['secao'] ?? 'item',
  );

  ItemPedido copyWith({
  String? produtoId,
  String? tipo,
  String? sabor,
  List<String>? adicionais,
  double? valor,
  String? observacao,
  bool clearProdutoId = false,
  int? quantidade,
  String? secao,
}) => ItemPedido(
  produtoId: clearProdutoId ? null : (produtoId ?? this.produtoId),
  tipo: tipo ?? this.tipo,
  sabor: sabor ?? this.sabor,
  adicionais: adicionais ?? this.adicionais,
  valor: valor ?? this.valor,
  observacao: observacao ?? this.observacao,
  quantidade: quantidade ?? this.quantidade,
  secao: secao ?? this.secao,
);
}