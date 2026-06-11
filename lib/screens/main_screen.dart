import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart' show zoomNotifier;
import 'produtos_screen.dart';
import 'clientes_screen.dart';
import 'empresas_screen.dart';
import 'pedidos_screen.dart';
import 'fechamento_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<_MenuItem> _menuItems = [
    _MenuItem(label: 'Pedidos', icon: Icons.receipt_long),
    _MenuItem(label: 'Caixa', icon: Icons.point_of_sale),
    _MenuItem(label: 'Produtos', icon: Icons.fastfood),
    _MenuItem(label: 'Clientes', icon: Icons.people),
    _MenuItem(label: 'Empresa', icon: Icons.business),
  ];

  Widget _buildPlaceholder(String label) {
    return Center(
      child: Text(label, style: const TextStyle(fontSize: 24, color: Colors.grey)),
    );
  }

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0: return const PedidosScreen();
      case 1: return const FechamentoScreen();
      case 2: return const ProdutosScreen();
      case 3: return const ClientesScreen();
      case 4: return const EmpresasScreen();
      default: return _buildPlaceholder('Pedidos');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailPartes = user?.email?.split('@') ?? [''];
    final nomeUsuario = emailPartes[0];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () => zoomNotifier.aumentar(),
        const SingleActivator(LogicalKeyboardKey.add, control: true): () => zoomNotifier.aumentar(),
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () => zoomNotifier.diminuir(),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () => zoomNotifier.resetar(),
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): () => zoomNotifier.resetar(),
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): () => zoomNotifier.aumentar(),
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () => zoomNotifier.diminuir(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              // Menu lateral
              Container(
                width: 220,
                color: const Color(0xFF212121),
                child: Column(
                  children: [
                    // Header do menu
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      color: const Color(0xFFE53935),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.delivery_dining, color: Colors.white, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'DeliverHub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Itens do menu
                    Expanded(
                      child: ListView.builder(
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          final selected = _selectedIndex == index;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                item.icon,
                                color: selected ? const Color(0xFFE53935) : Colors.white70,
                              ),
                              title: Text(
                                item.label,
                                style: TextStyle(
                                  color: selected ? const Color(0xFFE53935) : Colors.white70,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              onTap: () => setState(() => _selectedIndex = index),
                            ),
                          );
                        },
                      ),
                    ),

                    // Controles de zoom
                    const Divider(color: Colors.white24),
                    ValueListenableBuilder<double>(
                      valueListenable: zoomNotifier,
                      builder: (context, zoom, _) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white54, size: 18),
                              tooltip: 'Diminuir (Ctrl+-)',
                              onPressed: zoomNotifier.diminuir,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            GestureDetector(
                              onTap: zoomNotifier.resetar,
                              child: Text(
                                '${(zoom * 100).round()}%',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white54, size: 18),
                              tooltip: 'Aumentar (Ctrl++)',
                              onPressed: zoomNotifier.aumentar,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer com usuário e logout
                    const Divider(color: Colors.white24),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE53935),
                            radius: 16,
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nomeUsuario,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
                            tooltip: 'Sair',
                            onPressed: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo principal
              Expanded(
                child: Column(
                  children: [
                    // Topbar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _menuItems[_selectedIndex].label,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Tela atual
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: _currentScreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  _MenuItem({required this.label, required this.icon});
}