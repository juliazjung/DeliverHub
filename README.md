# 🛵 DeliverHub

Aplicativo desktop e web para gestão de pedidos de delivery. Desenvolvido para uso interno, permite registrar pedidos, gerenciar clientes, produtos e realizar o fechamento de caixa diário.

---

## 📋 Funcionalidades

- **Pedidos** — cadastro e acompanhamento de pedidos com itens, bebidas, adicionais, forma de pagamento e status
- **Produtos** — cadastro de produtos com subprodutos (sabores/tamanhos) e adicionais vinculados
- **Clientes** — cadastro automático de clientes a partir dos pedidos
- **Fechamento de caixa** — resumo diário por entregador, totais por forma de pagamento e reconciliação do caixa
- **Impressão térmica** — impressão direta em impressora POS 58mm no Windows; geração de PDF no navegador
- **Multi-tenant** — suporte a múltiplas empresas com isolamento de dados
- **Zoom global** — controle de escala da interface via `Ctrl++` / `Ctrl+-` ou botões na barra lateral

---

## 🛠️ Tecnologias

- [Flutter](https://flutter.dev/) — framework UI (targets: Windows desktop e Web)
- [Firebase Auth](https://firebase.google.com/products/auth) — autenticação
- [Cloud Firestore](https://firebase.google.com/products/firestore) — banco de dados
- [esc_pos_utils_plus](https://pub.dev/packages/esc_pos_utils_plus) — geração de comandos ESC/POS
- [win32](https://pub.dev/packages/win32) — comunicação com impressora no Windows
- [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) — geração de PDF no Web

---

## 🚀 Como executar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) com workload **Desenvolvimento para desktop com C++** (para target Windows)
- Projeto Firebase configurado (Auth + Firestore)

### Configuração do Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Ative **Authentication** (método: Email/Senha) e **Firestore**
3. Copie o arquivo de exemplo e preencha com suas chaves:

```bash
cp lib/firebase_options.example.dart lib/firebase_options.dart
```

Ou gere automaticamente com o FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Instalação

```bash
git clone https://github.com/juliazjung/deliverhub.git
cd deliverhub
flutter pub get
```

### Executar em modo desenvolvimento

```bash
# Windows
flutter run -d windows

# Web
flutter run -d chrome
```

### Gerar build de produção

```bash
# Windows (.exe)
flutter build windows --release
# Executável em: build\windows\x64\runner\Release\

# Web
flutter build web --release
```

> ⚠️ Para distribuir o app Windows, copie a pasta `Release` completa — não apenas o `.exe`.

---

## 📸 Screenshots

*Em breve.*

---

## 📄 Licença

Projeto de uso pessoal. Todos os direitos reservados.