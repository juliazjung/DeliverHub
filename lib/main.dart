import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _restaurarSessao();
  runApp(const DeliverHubApp());
}

// Tenta restaurar a sessão se já houver usuário logado no Firebase Auth
Future<void> _restaurarSessao() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      final empresaDoc = await FirebaseFirestore.instance
        .collection('empresas')
        .doc(data['empresaId'])
        .get();
      SessionService().iniciar(
        empresaId: data['empresaId'] ?? '',
        cnpj: data['cnpj'] ?? '',
        usuario: data['usuario'] ?? '',
        impressoraPadrao: empresaDoc.data()?['impressoraPadrao'] ?? '',
      );
    } else {
      // Documento não encontrado — faz logout para evitar crash
      await FirebaseAuth.instance.signOut();
    }
  } catch (e) {
    // Erro ao buscar — faz logout para evitar crash
    await FirebaseAuth.instance.signOut();
  }
}

// Notifier global de zoom acessível de qualquer tela
class ZoomNotifier extends ValueNotifier<double> {
  ZoomNotifier() : super(1.0);

  void aumentar() => value = (value + 0.1).clamp(0.5, 2.0);
  void diminuir() => value = (value - 0.1).clamp(0.5, 2.0);
  void resetar() => value = 1.0;
}

final zoomNotifier = ZoomNotifier();

class DeliverHubApp extends StatelessWidget {
  const DeliverHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a rota inicial baseada em se há sessão ativa
    final sessaoAtiva = SessionService().empresaId != null &&
        SessionService().empresaId!.isNotEmpty;

    return ValueListenableBuilder<double>(
      valueListenable: zoomNotifier,
      builder: (context, zoom, child) {
        return MaterialApp(
          title: 'DeliverHub',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
            useMaterial3: true,
          ),
          initialRoute: sessaoAtiva ? '/main' : '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/main': (_) => const MainScreen(),
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(zoom),
                size: mq.size / zoom,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}