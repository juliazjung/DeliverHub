import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';
import 'session_service.dart';

class ClienteService {
  final _db = FirebaseFirestore.instance;
  String get _empresaId => SessionService().empresaId ?? '';

  Future<List<Cliente>> listarClientes() async {
    final snap = await _db
        .collection('clientes')
        .where('empresaId', isEqualTo: _empresaId)
        .get();
    final lista = snap.docs.map((d) => Cliente.fromMap(d.id, d.data())).toList();
    lista.sort((a, b) => a.nome.compareTo(b.nome));
    return lista;
  }

  Future<Cliente?> buscarPorNome(String nome) async {
    final snap = await _db
        .collection('clientes')
        .where('empresaId', isEqualTo: _empresaId)
        .where('nome', isEqualTo: nome)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Cliente.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Future<String> salvarCliente(Cliente cliente) async {
    final map = cliente.toMap()..['empresaId'] = _empresaId;
    if (cliente.id == null) {
      final ref = await _db.collection('clientes').add(map);
      return ref.id;
    } else {
      await _db.collection('clientes').doc(cliente.id).update(map);
      return cliente.id!;
    }
  }
}