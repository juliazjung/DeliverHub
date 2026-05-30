import '../models/pedido.dart';
import 'pdf_service.dart';

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
    await PdfService().visualizarTicket(pedido);
    return ResultadoImpressao(
      StatusImpressao.sucesso,
      'PDF gerado com sucesso!',
    );
  }
}