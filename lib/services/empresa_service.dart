import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/empresa.dart';

class EmpresaService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> cadastrarEmpresa({
    required Empresa empresa,
    required String usuarioAdmin,
    required String senhaAdmin,
  }) async {
    // 1. Cria o usuário no Firebase Auth
    final email = '$usuarioAdmin@${empresa.cnpj}.deliverhub';
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senhaAdmin,
    );

    // 2. Salva a empresa no Firestore
    final empresaRef = await _db.collection('empresas').add(empresa.toMap());

    // 3. Salva o usuário admin vinculado à empresa
    await _db.collection('usuarios').doc(credential.user!.uid).set({
      'usuario': usuarioAdmin,
      'empresaId': empresaRef.id,
      'cnpj': empresa.cnpj,
      'perfil': 'admin',
    });
  }

  Future<void> atualizarEmpresa(Empresa empresa) async {
    await _db.collection('empresas').doc(empresa.id).update(empresa.toMap());
  }
}