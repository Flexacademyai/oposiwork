import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/security_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/premium_lock_widget.dart';

class _Mensaje {
  final String texto;
  final bool esUsuario;
  final List<String> fuentes;

  const _Mensaje({required this.texto, required this.esUsuario, this.fuentes = const []});
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.oposicionId});
  final String oposicionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Mensaje> _mensajes = [];
  bool _enviando = false;
  bool _consentimientoAceptado = false;

  @override
  void initState() {
    super.initState();
    _verificarConsentimiento();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _verificarConsentimiento() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('consentimientos')
        .select()
        .eq('usuario_id', user.id)
        .eq('tipo', 'ia')
        .maybeSingle();
    if (data != null && mounted) {
      setState(() => _consentimientoAceptado = true);
      _agregarMensajeBienvenida();
    } else if (mounted) {
      _mostrarDialogoConsentimiento();
    }
  }

  void _agregarMensajeBienvenida() {
    setState(() {
      _mensajes.add(const _Mensaje(
        texto: 'Hola, soy tu asistente de estudio. Puedo responder preguntas sobre el temario de tu oposición basándome exclusivamente en el contenido oficial. ¿En qué puedo ayudarte?',
        esUsuario: false,
      ));
    });
  }

  Future<void> _mostrarDialogoConsentimiento() async {
    final aceptado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Asistente de IA'),
        content: const Text(
          'Este chat usa inteligencia artificial para responder tus preguntas. Las respuestas se generan automáticamente basándose en el contenido del temario oficial y pueden contener errores. Siempre contrasta con las fuentes oficiales del BOE.\n\n¿Aceptas usar este servicio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (aceptado == true && mounted) {
      await _registrarConsentimiento();
      setState(() => _consentimientoAceptado = true);
      _agregarMensajeBienvenida();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _registrarConsentimiento() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('consentimientos').upsert({
      'usuario_id': user.id,
      'tipo': 'ia',
      'aceptado': true,
      'aceptado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando || !_consentimientoAceptado) return;

    final sanitizado = SecurityService.sanitizar(texto);
    if (!SecurityService.longitudValida(sanitizado, min: 1, max: 500)) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: sanitizado, esUsuario: true));
      _enviando = true;
    });
    _controller.clear();
    _scrollAlFinal();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.functions.invoke(
        'chat-rag',
        body: {
          'pregunta': sanitizado,
          'oposicion_id': widget.oposicionId,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      final respuesta = data?['respuesta'] as String? ?? 'Sin respuesta disponible.';
      final fuentesRaw = data?['fuentes'] as List? ?? [];
      final fuentes = fuentesRaw
          .map((f) => f['fragmento']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .take(2)
          .toList();

      if (mounted) {
        setState(() {
          _mensajes.add(_Mensaje(texto: respuesta, esUsuario: false, fuentes: fuentes));
        });
        _scrollAlFinal();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensajes.add(const _Mensaje(
            texto: 'Ha ocurrido un error. Inténtalo de nuevo.',
            esUsuario: false,
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
        actions: [
          Tooltip(
            message: 'Respuestas generadas por IA basadas en el temario oficial',
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.info_outline_rounded, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _mensajes.length + (_enviando ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _mensajes.length && _enviando) {
                      return _buildBurbuja(const _Mensaje(texto: '...', esUsuario: false), cargando: true);
                    }
                    return _buildBurbuja(_mensajes[i]);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildBurbuja(_Mensaje mensaje, {bool cargando = false}) {
    final esUsuario = mensaje.esUsuario;
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: esUsuario ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: esUsuario ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: esUsuario ? null : Border.all(color: AppColors.border),
        ),
        child: cargando
            ? const SizedBox(
                width: 40,
                child: LinearProgressIndicator(minHeight: 2),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje.texto,
                    style: TextStyle(
                      color: esUsuario ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (mensaje.fuentes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    const Text(
                      'Basado en el temario oficial',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _enviarMensaje(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _enviando ? null : _enviarMensaje,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
