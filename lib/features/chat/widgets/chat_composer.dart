import 'package:flutter/material.dart';

import '../../../core/animations/zink_animations.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/zink_spacing.dart';

typedef OnSend = void Function(String text);

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

  void _doSend() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.streaming) return;
    widget.onSend(text);
    setState(() {
      _ctrl.clear();
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
        onTap: onTap,
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
      onTap: enabled ? onTap : null,
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
