class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? empresaId;
  String? cnpj;
  String? usuario;
  String? impressoraPadrao;

  void iniciar({
    required String empresaId,
    required String cnpj,
    required String usuario,
    required String impressoraPadrao,
  }) {
    this.empresaId = empresaId;
    this.cnpj = cnpj;
    this.usuario = usuario;
    this.impressoraPadrao = impressoraPadrao;
  }

  void limpar() {
    empresaId = null;
    cnpj = null;
    usuario = null;
    impressoraPadrao = null;
  }
}