import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<UserCredential?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Carrega dados do usuário e inicializa a sessão
    final uid = credential.user!.uid;
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final empresaDoc = await _db.collection('empresas').doc(data['empresaId']).get();
      SessionService().iniciar(
        empresaId: data['empresaId'] ?? '',
        cnpj: data['cnpj'] ?? '',
        usuario: data['usuario'] ?? '',
        impressoraPadrao: empresaDoc.data()?['impressoraPadrao'] ?? '',
      );
    }

    return credential;
  }

  Future<void> logout() async {
    SessionService().limpar();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}