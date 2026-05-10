import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_loader.dart';
import '../../widgets/zink_scaffold.dart';
import '../../core/storage/storage_service.dart';
import '../../models/note.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  bool _busy = false;
  String? _text;
  String? _error;

  Future<void> _capture(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await OcrService.pickAndRecognize(source: source);
      if (text == null) {
        // отменено
      } else if (text.isEmpty) {
        setState(() => _error = 'Текст не обнаружен');
      } else {
        ZinkHaptics.medium();
        setState(() => _text = text);
        final gain = await GamificationService.addXp(
          AppConfig.xpPerOcrScan,
          scansDelta: 1,
        );
        ref.read(totalXpProvider.notifier).state = gain.newTotal;
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAsNote() async {
    if (_text == null || _text!.isEmpty) return;
    final note = Note(
      title: 'Скан тетради ${DateTime.now().day}.${DateTime.now().month}',
      content: _text!,
    );
    await StorageService.notes.put(note.id, note.toJson());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено в конспекты')),
    );
  }

  void _askInChat() {
    if (_text == null || _text!.isEmpty) return;
    context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'OCR сканер'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZinkSpacing.md),
            Text(
              'Сфотографируй конспект — я распознаю текст',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: ZinkSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ZinkButton(
                    label: 'Камера',
                    icon: Icons.camera_alt_rounded,
                    onPressed: _busy ? null : () => _capture(ImageSource.camera),
                    expand: true,
                  ),
                ),
                const SizedBox(width: ZinkSpacing.sm),
                Expanded(
                  child: ZinkButton(
                    label: 'Галерея',
                    icon: Icons.photo_library_outlined,
                    variant: ZinkButtonVariant.outline,
                    onPressed: _busy ? null : () => _capture(ImageSource.gallery),
                    expand: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ZinkSpacing.lg),
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: ZinkSpacing.xxl),
                  child: ZinkLoader(size: 32),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(ZinkSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
                ),
                child: Text(_error!, style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: ZinkSpacing.lg),
            if (_text != null) ...[
              Text('Распознанный текст',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
              const SizedBox(height: ZinkSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _text!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: ZinkSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ZinkButton(
                      label: 'Сохранить',
                      icon: Icons.bookmark_add_outlined,
                      variant: ZinkButtonVariant.outline,
                      onPressed: _saveAsNote,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.sm),
                  Expanded(
                    child: ZinkButton(
                      label: 'В чат',
                      icon: Icons.send_rounded,
                      onPressed: _askInChat,
                      expand: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZinkSpacing.xl),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
