import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:win32/win32.dart';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/pedido.dart';
import 'session_service.dart';

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
    try {
      final nomePrinter = SessionService().impressoraPadrao ?? '';
      if (nomePrinter.isEmpty) {
        return ResultadoImpressao(
          StatusImpressao.impressoraNaoEncontrada,
          'Nome da impressora não configurado. Configure em Empresa.',
        );
      }

      final bytes = await _montarTicket(pedido);
      final resultado = _enviarParaImpressora(Uint8List.fromList(bytes), nomePrinter);

      if (resultado) {
        return ResultadoImpressao(
          StatusImpressao.sucesso,
          'Pedido #${pedido.codigoDiario} impresso com sucesso!',
        );
      } else {
        return ResultadoImpressao(
          StatusImpressao.erro,
          'Falha ao enviar para a impressora.',
        );
      }
    } catch (e) {
      return ResultadoImpressao(StatusImpressao.erro, 'Erro ao imprimir: $e');
    }
  }

  bool _enviarParaImpressora(Uint8List dados, String nomePrinter) {
    final printerName = nomePrinter.toNativeUtf16();
    final phPrinter = calloc<HANDLE>();
    final pDefault = calloc<PRINTER_DEFAULTS>();

    try {
      // Abre a impressora
      final abriu = OpenPrinter(printerName, phPrinter, pDefault);
      if (abriu == FALSE) return false;

      final hPrinter = phPrinter.value;

      // Define o job de impressão RAW
      final docInfo = calloc<DOC_INFO_1>();
      docInfo.ref.pDocName = 'Pedido'.toNativeUtf16();
      docInfo.ref.pOutputFile = nullptr;
      docInfo.ref.pDatatype = 'RAW'.toNativeUtf16();

      final jobId = StartDocPrinter(hPrinter, 1, docInfo.cast());
      if (jobId == 0) {
        ClosePrinter(hPrinter);
        return false;
      }

      StartPagePrinter(hPrinter);

      // Envia os bytes
      final buffer = calloc<Uint8>(dados.length);
      final bufferList = buffer.asTypedList(dados.length);
      bufferList.setAll(0, dados);

      final bytesWritten = calloc<DWORD>();
      WritePrinter(hPrinter, buffer, dados.length, bytesWritten);

      EndPagePrinter(hPrinter);
      EndDocPrinter(hPrinter);
      ClosePrinter(hPrinter);

      calloc.free(buffer);
      calloc.free(bytesWritten);

      return true;
    } finally {
      calloc.free(printerName);
      calloc.free(phPrinter);
      calloc.free(pDefault);
    }
  }

  Future<List<int>> _montarTicket(Pedido pedido) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // ── Número, data e formato ──────────────────
    //bytes += generator.hr();
    
    final String cabecalho = '#${pedido.codigoDiario}'.padRight(8) + _formatarData(pedido.dataHora);
    bytes += generator.text(
      cabecalho,
      styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.center),
    );

    bytes += generator.hr();

    final itensProduto = pedido.itens
        .where((i) => i.secao != 'bebida')
        .toList();
    final itensBebida = pedido.itens.where((i) => i.secao == 'bebida').toList();

    if (itensProduto.isNotEmpty) {
      //bytes += generator.feed(1);

      for (final item in itensProduto) {
        final descricao =
            '${item.quantidade} ${item.tipo.toUpperCase()} ${item.sabor.toUpperCase()}'
                .trim();
        //final valor = 'R$cifrao ${(item.valor * item.quantidade).toStringAsFixed(2)}';

        bytes += generator.text(
          descricao.trim(),
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.left),
        );

        if (item.adicionais.isNotEmpty) {
          bytes += generator.text(
            '  + ${item.adicionais.join(', ')}',
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontB),
          );
        }

        if (item.observacao.isNotEmpty) {
          bytes += generator.text(
            '  ${item.observacao}',
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, fontType: PosFontType.fontB),
          );
        }
      }
    }

    if (itensBebida.isNotEmpty) {
      bytes += generator.hr();
      //bytes += generator.feed(1);

      for (final item in itensBebida) {
        final descricao =
            '${item.quantidade} ${item.tipo.toUpperCase()} ${item.sabor.toUpperCase()}'
                .trim();
        final valor =
            'R' + String.fromCharCode(0x24) + ' ${(item.valor * item.quantidade).toStringAsFixed(2)}';

        bytes += generator.row([
          PosColumn(
            text: descricao, 
            width: 8,
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),  
          ),
          PosColumn(
            text: valor,
            width: 4,
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.right),
          ),
        ]);
      }
    }

    bytes += generator.hr();

    if (pedido.frete > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'FRETE:', 
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),  
        ),
        PosColumn(
          text: 'R' + String.fromCharCode(0x24) + ' ${pedido.frete.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true)),
      PosColumn(
        text: 'R' + String.fromCharCode(0x24) + ' ${pedido.valorTotal.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true, align: PosAlign.right),
      ),
    ]);

    //bytes += generator.hr();

    if (pedido.formaPagamento != 'indefinido') {
      bytes += generator.text(
        pedido.formaPagamento.toUpperCase(),
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.center),
      );
    }

    if (pedido.pagouNoPedido) {
      bytes += generator.row([
        PosColumn(
          text: 'PAGO:', 
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
        ),
        PosColumn(
          text: 'SIM',
          width: 6,
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    if (pedido.formato == 'entrega') {
      //bytes += generator.text('ENTREGA', styles: const PosStyles(bold: true));
      bytes += generator.text(
        pedido.clienteNome,
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),  
      );

      String endereco = '${pedido.clienteEndereco}, ${pedido.clienteNumero}'.trim();
      if (pedido.clienteComplemento.isNotEmpty) {
        endereco += ' - ${pedido.clienteComplemento}';
      }

      bytes += generator.text(
        endereco.trim(),
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
      );
      
      if (!pedido.clienteCidade.toUpperCase().contains('ENTRE')) {
        bytes += generator.text(
          '${pedido.clienteCidade}',
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),  
        );
      }
    } else {
      bytes += generator.text(
        pedido.formato == 'retirada' ? 'RETIRADA' : 'COMER',
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        pedido.clienteNome,
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
      );      
    }

    if (pedido.horarioPreferido != null &&
        pedido.horarioPreferido!.isNotEmpty) {
      bytes += generator.text(
        'HORARIO: ${pedido.horarioPreferido}',
        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, align: PosAlign.center, bold: true),
      );
    }

    //bytes += generator.hr();
    //bytes += generator.feed(3);

    bytes += generator.cut();

    return bytes;
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
