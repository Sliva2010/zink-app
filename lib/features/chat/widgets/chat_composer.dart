import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/animations/zink_animations.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/zink_spacing.dart';
import '../../../core/utils/haptics.dart';

typedef OnSend = void Function(String text, String? attachmentText);

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.onSend, required this.streaming});

  final OnSend onSend;
  final bool streaming;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _listening = false;
  String? _ocrText;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await VoiceService.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await VoiceService.init();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Распознавание недоступно')),
      );
      return;
    }
    setState(() => _listening = true);
    ZinkHaptics.medium();
    await VoiceService.startListening(
      onResult: (partial, isFinal) {
        if (!mounted) return;
        setState(() => _ctrl.text = partial);
        if (isFinal) {
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _scanFromCamera() async {
    final text = await OcrService.pickAndRecognize(source: ImageSource.camera);
    if (text == null || !mounted) return;
    setState(() => _ocrText = text);
    ZinkHaptics.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Текст с фото прикреплён к вопросу')),
    );
  }

  void _doSend() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.streaming) return;
    widget.onSend(text, _ocrText);
    setState(() {
      _ctrl.clear();
      _ocrText = null;
    });
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: scheme.outline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ZinkSpacing.md,
            ZinkSpacing.sm,
            ZinkSpacing.md,
            ZinkSpacing.sm,
          ),
          child: Column(
            children: [
              if (_ocrText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: ZinkSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZinkSpacing.md,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.document_scanner_outlined,
                          size: 14, color: scheme.onSurface),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'OCR: ${_ocrText!.length > 60 ? '${_ocrText!.substring(0, 60)}…' : _ocrText!}',
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _ocrText = null),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _IconButton(
                    icon: Icons.document_scanner_outlined,
                    onTap: _scanFromCamera,
                    tooltip: 'Сканировать тетрадь',
                  ),
                  const SizedBox(width: ZinkSpacing.xs),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(ZinkSpacing.radiusLg),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 6,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: _listening
                              ? 'Слушаю...'
                              : 'Спроси о чём-нибудь',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: ZinkSpacing.md,
                            vertical: ZinkSpacing.sm + 4,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.xs),
                  ZinkPulse(
                    active: _listening,
                    child: _IconButton(
                      icon: _listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                      onTap: _toggleVoice,
                      tooltip: 'Голос',
                      filled: _listening,
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.xs),
                  _SendButton(
                    enabled: _ctrl.text.trim().isNotEmpty && !widget.streaming,
                    streaming: widget.streaming,
                    onTap: _doSend,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: () {
          ZinkHaptics.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: filled ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
          ),
          child: Icon(
            icon,
            color: filled ? scheme.onPrimary : scheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.streaming,
    required this.onTap,
  });

  final bool enabled;
  final bool streaming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? () { ZinkHaptics.medium(); onTap(); } : null,
      borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? scheme.primary
              : scheme.primary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
        ),
        child: streaming
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                ),
              )
            : Icon(
                Icons.arrow_upward_rounded,
                color: scheme.onPrimary,
                size: 20,
              ),
      ),
    );
  }
}
