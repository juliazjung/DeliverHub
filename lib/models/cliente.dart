class Cliente {
  final String? id;
  final String nome;
  final String endereco;
  final String numero;
  final String complemento;
  final String cidade;
  final String estado;
  final String cpf;
  final String? empresaId;

  Cliente({
    this.id,
    required this.nome,
    required this.endereco,
    required this.numero,
    this.complemento = '',
    required this.cidade,
    required this.estado,
    required this.cpf,
    this.empresaId,
  });

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'endereco': endereco,
    'numero': numero,
    'complemento': complemento,
    'cidade': cidade,
    'estado': estado,
    'cpf': cpf,
    'empresaId': empresaId,
  };

  factory Cliente.fromMap(String id, Map<String, dynamic> map) => Cliente(
    id: id,
    nome: map['nome'] ?? '',
    endereco: map['endereco'] ?? '',
    numero: map['numero'] ?? '',
    complemento: map['complemento'] ?? '',
    cidade: map['cidade'] ?? '',
    estado: map['estado'] ?? '',
    cpf: map['cpf'] ?? '',
    empresaId: map['empresaId'],
  );
}