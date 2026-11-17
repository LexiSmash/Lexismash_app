// =================================================================
// lib/main.dart — LexiSmash (involucro nativo)
// =================================================================
// Fase 7 (22/09/2026): NON è una riscrittura del gioco. È un «involucro»
// che mostra https://lexismash.it/ in una WebView a schermo intero: ogni
// modifica al sito (docs/) arriva subito anche nell'app.
//
// D2 (17/11/2026, piano-inviti-store-app-distribuzione.md) — migliorie
// native richieste dagli store, che rifiutano le app «solo sito»:
//   - schermata «senza connessione» con Riprova;
//   - link esterni (social, siti di terzi, mailto:, tel:…) nel browser o
//     nell'app giusta; restano dentro l'app solo il sito, il server, gli
//     accessi (Google, GitHub, Facebook, Microsoft) e il pagamento Stripe;
//   - tasto Indietro: torna alla pagina precedente del sito (anche con il
//     «gesto Indietro» moderno di Android, vedi AndroidManifest);
//   - schermo sempre acceso nelle pagine di gioco (Master, giocatore,
//     Monitor, lobby, tornei);
//   - condivisione nativa (menu Condividi del telefono) e comandi vocali
//     con il riconoscimento vocale del telefono, attraverso il canale
//     JavaScript «LexiSmashApp» usato da docs/js/app-bridge.js;
//   - microfono per le pagine che lo chiedono e scelta dei file (brani del
//     Jukebox, impostazioni, video della presentazione).
// Niente librerie proprietarie (Google Play Services, Firebase nativo):
// l'app resta pubblicabile su F-Droid. Le notifiche push native sono
// rimandate per questo motivo (vedi il piano, D2b).
// =================================================================
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const String kHomeUrl = 'https://lexismash.it/';
const Color kBg = Color(0xFF0F172A);
const Color kAccent = Color(0xFFDB2777);

// Pagine in cui lo schermo non deve spegnersi (si gioca senza toccarlo).
final RegExp kGamePages = RegExp(r'/(host|player|player-integrated|monitor|lobby|tournament|tournament-view)\.html', caseSensitive: false);

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
      theme: ThemeData(colorSchemeSeed: kAccent, brightness: Brightness.dark),
      home: const LexiSmashWebViewScreen(),
    );
  }
}

// ---------------------------------------------------------------- testi
// Pochi testi nativi, nella lingua del telefono (le 6 lingue del gioco).
const Map<String, List<String>> kTexts = {
  // titolo, spiegazione, pulsante
  'it': ['Nessuna connessione', 'LexiSmash ha bisogno di Internet. Controlla la rete e riprova.', 'Riprova'],
  'en': ['No connection', 'LexiSmash needs the Internet. Check your network and try again.', 'Try again'],
  'fr': ['Pas de connexion', 'LexiSmash a besoin d\'Internet. Vérifie ta connexion et réessaie.', 'Réessayer'],
  'de': ['Keine Verbindung', 'LexiSmash braucht Internet. Prüfe deine Verbindung und versuche es erneut.', 'Erneut versuchen'],
  'es': ['Sin conexión', 'LexiSmash necesita Internet. Revisa la conexión y vuelve a intentarlo.', 'Reintentar'],
  'nl': ['Geen verbinding', 'LexiSmash heeft internet nodig. Controleer je verbinding en probeer het opnieuw.', 'Opnieuw proberen'],
};
List<String> texts() {
  final lang = Platform.localeName.split(RegExp('[_-]')).first.toLowerCase();
  return kTexts[lang] ?? kTexts['en']!;
}

class LexiSmashWebViewScreen extends StatefulWidget {
  const LexiSmashWebViewScreen({super.key});

  @override
  State<LexiSmashWebViewScreen> createState() => _LexiSmashWebViewScreenState();
}

class _LexiSmashWebViewScreenState extends State<LexiSmashWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _offline = false;
  bool _awake = false;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  int _speechSession = 0;

  @override
  void initState() {
    super.initState();
    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: _onPermissionRequest,
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kBg)
      ..addJavaScriptChannel('LexiSmashApp', onMessageReceived: _onBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onUrlChange: (change) => _updateWakelock(change.url),
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) setState(() => _offline = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false); // suoni e Jukebox come nel browser
      platform.setOnShowFileSelector(_onShowFileSelector);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _speech.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- link
  static bool _inApp(Uri u) {
    if (!(u.scheme == 'https' || u.scheme == 'http')) return u.scheme == 'about' || u.scheme == 'data' || u.scheme == 'blob' || u.scheme == 'javascript';
    final h = u.host.toLowerCase();
    final p = u.path.toLowerCase();
    bool isOrSub(String d) => h == d || h.endsWith('.$d');
    if (isOrSub('lexismash.it')) return true;                    // il sito
    if (h.endsWith('.run.app')) return true;                       // il server (Cloud Run)
    if (isOrSub('firebaseapp.com') || isOrSub('web.app')) return true; // accesso Firebase
    if (h == 'accounts.google.com' || h == 'accounts.youtube.com') return true;
    if (h == 'github.com' && (p.startsWith('/login') || p.startsWith('/sessions'))) return true;
    if (isOrSub('facebook.com') && (p.contains('oauth') || p.contains('login'))) return true;
    if (h == 'login.microsoftonline.com' || h == 'login.live.com' || h == 'account.live.com') return true;
    if (isOrSub('stripe.com')) return true;                        // pagamento
    return false;
  }

  Future<NavigationDecision> _onNavigationRequest(NavigationRequest request) async {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    if (uri == null || _inApp(uri)) return NavigationDecision.navigate;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {/* nessuna app per aprirlo: si resta dove si è */}
    return NavigationDecision.prevent;
  }

  // ---------------------------------------------------------------- schermo acceso
  void _updateWakelock(String? url) {
    final want = url != null && kGamePages.hasMatch(url);
    if (want == _awake) return;
    _awake = want;
    want ? WakelockPlus.enable() : WakelockPlus.disable();
  }

  // ---------------------------------------------------------------- permessi del sito
  Future<void> _onPermissionRequest(WebViewPermissionRequest request) async {
    if (request.types.contains(WebViewPermissionResourceType.microphone)) {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        await request.grant();
        return;
      }
    }
    await request.deny();
  }

  // ---------------------------------------------------------------- file (Jukebox, impostazioni, video)
  Future<List<String>> _onShowFileSelector(FileSelectorParams params) async {
    final accept = params.acceptTypes.join(',').toLowerCase();
    FileType type = FileType.any;
    List<String>? ext;
    if (accept.contains('audio')) {
      type = FileType.audio;
    } else if (accept.contains('video')) {
      type = FileType.video;
    } else if (accept.contains('image')) {
      type = FileType.image;
    } else if (accept.contains('.json')) {
      type = FileType.custom;
      ext = ['json'];
    }
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: type,
        allowedExtensions: ext,
      );
      if (res == null) return <String>[];
      return res.files.where((f) => f.path != null).map((f) => Uri.file(f.path!).toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  // ---------------------------------------------------------------- ponte con il sito
  // Messaggi JSON da docs/js/app-bridge.js: {type: 'share'|'speechStart'|'speechStop', …}
  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    Map<String, dynamic> m;
    try {
      m = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (m['type']) {
      case 'share':
        final text = [m['text'], m['url']].where((x) => x is String && x.isNotEmpty).join('\n');
        if (text.isNotEmpty) await Share.share(text, subject: (m['title'] as String?) ?? 'LexiSmash');
        break;
      case 'speechStart':
        await _speechStart(m['id']?.toString() ?? '0', (m['lang'] as String?) ?? 'it-IT');
        break;
      case 'speechStop':
        await _speech.stop();
        break;
    }
  }

  Future<void> _js(String code) async {
    try {
      await _controller.runJavaScript(code);
    } catch (_) {}
  }

  Future<void> _speechStart(String id, String lang) async {
    final session = ++_speechSession;
    void emit(String fn, [Object? arg]) {
      if (session != _speechSession) return;
      _js('window.__lxSpeech && window.__lxSpeech.$fn(${jsonEncode(id)}${arg == null ? '' : ', ${jsonEncode(arg)}'})');
    }

    if (!_speechReady) {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        emit('error', 'not-allowed');
        emit('end');
        return;
      }
      _speechReady = await _speech.initialize(
        onError: (SpeechRecognitionError e) {
          final code = e.errorMsg.contains('no_match') || e.errorMsg.contains('speech_timeout') ? 'no-speech' : (e.errorMsg.contains('network') ? 'network' : 'aborted');
          emit('error', code);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') emit('end');
        },
      );
      if (!_speechReady) {
        emit('error', 'service-not-allowed'); // telefono senza servizio di riconoscimento vocale
        emit('end');
        return;
      }
    }
    await _speech.listen(
      localeId: lang.replaceAll('-', '_'),
      listenOptions: SpeechListenOptions(partialResults: false, cancelOnError: true, listenMode: ListenMode.dictation),
      onResult: (SpeechRecognitionResult r) {
        if (r.finalResult && r.recognizedWords.isNotEmpty) emit('result', r.recognizedWords);
      },
    );
  }

  // ---------------------------------------------------------------- Indietro
  Future<void> _handleBack(bool didPop) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _retry() {
    setState(() {
      _offline = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = texts();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading && !_offline) const Center(child: CircularProgressIndicator(color: kAccent)),
              if (_offline)
                Positioned.fill(
                  child: Container(
                    color: kBg,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 72, color: kAccent),
                        const SizedBox(height: 20),
                        Text(t[0], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(t[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFFCBD5E1))),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(t[2]),
                          style: FilledButton.styleFrom(backgroundColor: kAccent, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
