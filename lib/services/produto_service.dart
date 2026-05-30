import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto.dart';
import 'session_service.dart';

class ProdutoService {
  final _db = FirebaseFirestore.instance;
  String get _empresaId => SessionService().empresaId ?? '';

  Future<List<Produto>> listarProdutos({String? tipo}) async {
    final snap = await _db
        .collection('produtos')
        .where('empresaId', isEqualTo: _empresaId)
        .get();
    var lista = snap.docs.map((d) => Produto.fromMap(d.id, d.data())).toList();
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    if (tipo != null) {
      return lista.where((p) => p.tipo == tipo).toList();
    }
    return lista;
  }

  Future<void> salvarProduto(Produto produto) async {
    final map = produto.toMap()..['empresaId'] = _empresaId;
    if (produto.id == null) {
      await _db.collection('produtos').add(map);
    } else {
      await _db.collection('produtos').doc(produto.id).update(map);
    }
  }
}