import '../models/pedido.dart';

enum StatusImpressao {
  sucesso,
  impressoraNaoEncontrada,
  portaNaoAbriu,
  timeout,
  semSuporteWeb,
  erro,
}

class ResultadoImpressao {
  final StatusImpressao status;
  final String mensagem;
  ResultadoImpressao(this.status, this.mensagem);
  bool get sucesso => status == StatusImpressao.sucesso;
}

class PrintService {
  Future<ResultadoImpressao> imprimirPedido(Pedido pedido) async {
    return ResultadoImpressao(
      StatusImpressao.semSuporteWeb,
      'Impressão não disponível nesta plataforma.',
    );
  }
}