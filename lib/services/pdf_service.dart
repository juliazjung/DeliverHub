import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/pedido.dart';

class PdfService {
  static const double _largura = 58 * 2.8346;

  Future<void> visualizarTicket(Pedido pedido) async {
    await Printing.layoutPdf(
      onLayout: (_) async {
        final pdf = await _gerarPdf(pedido);
        return Uint8List.fromList(pdf);
      },
    );
  }

  Future<List<int>> _gerarPdf(Pedido pedido) async {
    final doc = pw.Document();

    final itensProduto =
        pedido.itens.where((i) => i.secao != 'bebida').toList();
    final itensBebida =
        pedido.itens.where((i) => i.secao == 'bebida').toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_largura, double.infinity, marginAll: 4),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── Número e data ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PEDIDO #${pedido.codigoDiario}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
                pw.Text(
                  _formatarData(pedido.dataHora),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            _hr(),

            // ── Itens ──
            if (itensProduto.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              ...itensProduto.map((item) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantidade} ${item.tipo.toUpperCase()} ${item.sabor.toUpperCase()}'.trim(),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Text(
                            'R\$ ${(item.valor * item.quantidade).toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                      if (item.adicionais.isNotEmpty)
                        pw.Text(
                          '  + ${item.adicionais.join(', ')}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (item.observacao.isNotEmpty)
                        pw.Text(
                          '  Obs: ${item.observacao}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  )),
            ],

            // ── Bebidas ──
            if (itensBebida.isNotEmpty) ...[
              _hr(),
              pw.SizedBox(height: 4),
              ...itensBebida.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantidade}x ${item.tipo.toUpperCase()} ${item.sabor.toUpperCase()}'.trim(),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        'R\$ ${(item.valor * item.quantidade).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  )),
            ],

            _hr(),

            // ── Totais ──
            if (pedido.frete != 0) _linha('FRETE:', 'R\$ ${pedido.frete.toStringAsFixed(2)}'),
            _linhaBold('TOTAL:', 'R\$ ${pedido.valorTotal.toStringAsFixed(2)}'),
            //_hr(),

            // ── Pagamento ──
            if (pedido.formaPagamento != 'indefinido')
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  pedido.formaPagamento.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),

            if (pedido.pagouNoPedido)
              _linha('PAGO', ''),

            _hr(),

            // ── Entrega / Retirada / Comer ──
            if (pedido.formato == 'entrega') ...[
              pw.Text('ENTREGA',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(pedido.clienteNome,
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                '${pedido.clienteEndereco}, ${pedido.clienteNumero}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                '${pedido.clienteCidade} - ${pedido.clienteEstado}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              _hr(),
            ] else ...[
              pw.Center(
                child: pw.Text(
                  pedido.formato == 'retirada' ? 'RETIRADA' : 'COMER',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
              pw.Text(pedido.clienteNome,
                  style: const pw.TextStyle(fontSize: 10)),
              _hr(),
            ],

            // ── Horário preferido ──
            if (pedido.horarioPreferido != null &&
                pedido.horarioPreferido!.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'HORARIO: ${pedido.horarioPreferido}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _hr() => pw.Column(children: [
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
      ]);

  pw.Widget _linha(String label, String valor) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(valor, style: const pw.TextStyle(fontSize: 9)),
        ],
      );

  pw.Widget _linhaBold(String label, String valor) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text(valor,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ],
      );

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}