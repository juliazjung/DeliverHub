class TipoProduto {
  final String? id;
  final String produto;
  final String tipoPreco; // 'unidade' ou 'kilo'
  final String classificacao; // 'produto', 'adicional', 'bebida'
  final String? empresaId;

  TipoProduto({
    this.id,
    required this.produto,
    required this.tipoPreco,
    required this.classificacao,
    this.empresaId,
  });

  Map<String, dynamic> toMap() => {
    'produto': produto,
    'tipoPreco': tipoPreco,
    'classificacao': classificacao,
    'empresaId': empresaId,
  };

  factory TipoProduto.fromMap(String id, Map<String, dynamic> map) => TipoProduto(
    id: id,
    produto: map['produto'] ?? '',
    tipoPreco: map['tipoPreco'] ?? 'unidade',
    classificacao: map['classificacao'] ?? 'produto',
    empresaId: map['empresaId'],
  );
}