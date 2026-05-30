import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';
import 'session_service.dart';

class PedidoService {
  final _db = FirebaseFirestore.instance;
  String get _empresaId => SessionService().empresaId ?? '';

  Future<int> proximoCodigoDiario() async {
    // Reutiliza listarPedidos para evitar query com índice composto
    final lista = await listarPedidos();
    if (lista.isEmpty) return 1;
    final maxCodigo = lista.map((p) => p.codigoDiario).reduce((a, b) => a > b ? a : b);
    return maxCodigo + 1;
  }

  Future<List<Pedido>> listarPedidos({DateTime? data}) async {
    final hoje = data ?? DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final fim = inicio.add(const Duration(days: 1));

    final snap = await _db
        .collection('pedidos')
        .where('empresaId', isEqualTo: _empresaId)
        .where('dataHora', isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('dataHora', isLessThan: fim.toIso8601String())
        .get();

    final lista = snap.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  Future<void> salvarPedido(Pedido pedido) async {
    final map = pedido.toMap()..['empresaId'] = _empresaId;
    if (pedido.id == null) {
      await _db.collection('pedidos').add(map);
    } else {
      await _db.collection('pedidos').doc(pedido.id).update(map);
    }
  }

  Future<void> marcarImpresso(String pedidoId, bool impresso) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'impresso': impresso,
      'dataImpressao': impresso ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<List<Pedido>> listarPedidosFechamento({required DateTime data}) async {
    final inicio = DateTime(data.year, data.month, data.day);
    final fim = inicio.add(const Duration(days: 1));

    final snap = await _db
        .collection('pedidos')
        .where('empresaId', isEqualTo: _empresaId)
        .where('dataHora', isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('dataHora', isLessThan: fim.toIso8601String())
        .get();

    final lista = snap.docs
        .map((d) => Pedido.fromMap(d.id, d.data()))
        .where((p) => p.status != 'cancelado')
        .toList();

    lista.sort((a, b) => a.codigoDiario.compareTo(b.codigoDiario));
    return lista;
  }

  Future<void> atualizarEntregadorPagamento(
    String pedidoId,
    String entregador,
    String formaPagamento,
  ) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'entregador': entregador,
      'formaPagamento': formaPagamento,
    });
  }

  Future<void> salvarDadosEntregador({
    required String data,
    required String entregador,
    required double valorRecebido,
    required double valorInicial,
  }) async {
    await _db
        .collection('fechamento_entregadores')
        .doc('${_empresaId}_${data}_$entregador')
        .set({
      'empresaId': _empresaId,
      'data': data,
      'entregador': entregador,
      'valorRecebido': valorRecebido,
      'valorInicial': valorInicial,
    });
  }

  Future<Map<String, dynamic>?> buscarDadosEntregador({
    required String data,
    required String entregador,
  }) async {
    final doc = await _db
        .collection('fechamento_entregadores')
        .doc('${_empresaId}_${data}_$entregador')
        .get();
    return doc.data();
  }
}