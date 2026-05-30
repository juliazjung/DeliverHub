class Subproduto {
  final String nome;
  final String tamanho;
  final String descricaoAdicional;
  final double preco;

  Subproduto({
    required this.nome,
    this.tamanho = '',
    this.descricaoAdicional = '',
    required this.preco,
  });

  // Exibe nome + tamanho concatenados (ex: "Coca 2L", "Frango G")
  String get nomeCompleto {
    if (tamanho.isNotEmpty) return '$nome $tamanho';
    return nome;
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'tamanho': tamanho,
    'descricaoAdicional': descricaoAdicional,
    'preco': preco,
  };

  factory Subproduto.fromMap(Map<String, dynamic> map) => Subproduto(
    nome: map['nome'] ?? '',
    tamanho: map['tamanho'] ?? '',
    descricaoAdicional: map['descricaoAdicional'] ?? '',
    preco: (map['preco'] ?? 0).toDouble(),
  );

  Subproduto copyWith({
    String? nome,
    String? tamanho,
    String? descricaoAdicional,
    double? preco,
  }) => Subproduto(
    nome: nome ?? this.nome,
    tamanho: tamanho ?? this.tamanho,
    descricaoAdicional: descricaoAdicional ?? this.descricaoAdicional,
    preco: preco ?? this.preco,
  );
}

class Produto {
  final String? id;
  final String nome;
  final String tipo; // 'produto', 'bebida', 'adicional', 'combo'
  final List<Subproduto> subprodutos;
  final bool ativo;
  final String? empresaId;
  final List<String> produtosVinculados;

  Produto({
    this.id,
    required this.nome,
    required this.tipo,
    this.subprodutos = const [],
    this.ativo = true,
    this.empresaId,
    this.produtosVinculados = const [],
  });

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'tipo': tipo,
    'subprodutos': subprodutos.map((s) => s.toMap()).toList(),
    'ativo': ativo,
    'empresaId': empresaId,
    'produtosVinculados': produtosVinculados,
  };

  factory Produto.fromMap(String id, Map<String, dynamic> map) => Produto(
    id: id,
    nome: map['nome'] ?? '',
    tipo: map['tipo'] ?? 'produto',
    subprodutos: (map['subprodutos'] as List<dynamic>? ?? [])
        .map((s) => Subproduto.fromMap(s as Map<String, dynamic>))
        .toList(),
    ativo: map['ativo'] ?? true,
    empresaId: map['empresaId'],
    produtosVinculados: List<String>.from(map['produtosVinculados'] ?? []),
  );
}