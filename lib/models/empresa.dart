class Empresa {
  final String? id;
  final String nome;
  final String razaoSocial;
  final String cnpj;
  final String estado;
  final String cidade;
  final String endereco;
  final String numero;
  final String email;
  final String celular;
  final bool contaVerificada;
  final String impressoraPadrao;

  Empresa({
    this.id,
    required this.nome,
    required this.razaoSocial,
    required this.cnpj,
    required this.estado,
    required this.cidade,
    required this.endereco,
    required this.numero,
    required this.email,
    required this.celular,
    this.contaVerificada = false,
    this.impressoraPadrao = '',
  });

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'razaoSocial': razaoSocial,
    'cnpj': cnpj,
    'estado': estado,
    'cidade': cidade,
    'endereco': endereco,
    'numero': numero,
    'email': email,
    'celular': celular,
    'contaVerificada': contaVerificada,
    'impressoraPadrao': impressoraPadrao,
  };

  factory Empresa.fromMap(String id, Map<String, dynamic> map) => Empresa(
    id: id,
    nome: map['nome'] ?? '',
    razaoSocial: map['razaoSocial'] ?? '',
    cnpj: map['cnpj'] ?? '',
    estado: map['estado'] ?? '',
    cidade: map['cidade'] ?? '',
    endereco: map['endereco'] ?? '',
    numero: map['numero'] ?? '',
    email: map['email'] ?? '',
    celular: map['celular'] ?? '',
    contaVerificada: map['contaVerificada'] ?? false,
    impressoraPadrao: map['impressoraPadrao'] ?? '',
  );
}