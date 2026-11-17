// =================================================================
// lib/main.dart — LexiSmash (involucro nativo per gli store)
// =================================================================
// Fase 7 (22/09/2026, correzioni finali): NON è una riscrittura del
// gioco. È un semplice "involucro" (wrapper) che mostra
// https://lexismash.it/ dentro una WebView a schermo intero, così
// l'app installata da Play Store/App Store appare come un'app nativa
// sul dispositivo pur restando, sotto, lo stesso identico sito web
// sempre aggiornato — nessuna logica di gioco vive qui: ogni modifica
// fatta al sito (docs/) si riflette automaticamente anche in questa
// app, senza dover mai ripubblicarla per seguire lo sviluppo del gioco.
//
// Il tasto Indietro di Android naviga all'indietro DENTRO la pagina
// web (proprio come il tasto Indietro di un browser) finché c'è
// cronologia da percorrere; solo quando non ce n'è più lascia che il
// tasto Indietro faccia il suo comportamento di sistema normale
// (mettere in background/chiudere l'app) — il comportamento atteso da
// chi la usa come un'app vera, non come una pagina web dentro un
// browser.
// =================================================================
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kHomeUrl = 'https://lexismash.it/';

void main() {
  runApp(const LexiSmashApp());
}

class LexiSmashApp extends StatelessWidget {
  const LexiSmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexiSmash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFDB2777), // stesso rosa/magenta del jukebox/tema del sito
        brightness: Brightness.dark,
      ),
      home: const LexiSmashWebViewScreen(),
    );
  }
}

class LexiSmashWebViewScreen extends StatefulWidget {
  const LexiSmashWebViewScreen({super.key});

  @override
  State<LexiSmashWebViewScreen> createState() => _LexiSmashWebViewScreenState();
}

class _LexiSmashWebViewScreenState extends State<LexiSmashWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A)) // stesso sfondo scuro del sito
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));
  }

  Future<void> _handleBack(bool didPop) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // 16/11/2026: onPopInvoked è deprecato dalle versioni recenti di Flutter.
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFDB2777)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
