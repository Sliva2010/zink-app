import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/pdf_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../models/note.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_loader.dart';
import '../../widgets/zink_scaffold.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  Note? _note;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final raw = StorageService.notes.get(widget.noteId);
    if (raw is Map) _note = Note.fromJson(raw);
    _titleCtrl = TextEditingController(text: _note?.title ?? '');
    _contentCtrl = TextEditingController(text: _note?.content ?? '');
  }

  @override
  void dispose() {
    _save();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_note == null) return;
    final updated = _note!.copyWith(
      title: _titleCtrl.text.trim().isEmpty ? 'Без названия' : _titleCtrl.text.trim(),
      content: _contentCtrl.text,
      updatedAt: DateTime.now(),
    );
    await StorageService.notes.put(updated.id, updated.toJson());
    _note = updated;
  }

  Future<void> _exportPdf() async {
    if (_note == null) return;
    setState(() => _exporting = true);
    try {
      await _save();
      final file = await PdfService.exportNoteToPdf(_note!);
      await PdfService.sharePdf(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_note == null) {
      return ZinkScaffold(
        appBar: const ZinkAppBar(title: 'Конспект'),
        body: const Center(child: Text('Конспект не найден')),
      );
    }
    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: 'Конспект',
        actions: [
          IconButton(
            icon: _exporting
                ? const ZinkLoader(size: 18, strokeWidth: 2)
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Экспорт в PDF',
            onPressed: _exporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Сохранить и выйти',
            onPressed: () async {
              await _save();
              if (mounted) context.pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZinkSpacing.sm),
            TextField(
              controller: _titleCtrl,
              style: theme.textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: 'Название',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: ZinkSpacing.sm),
            Container(
              height: 1,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: ZinkSpacing.md),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                style: theme.textTheme.bodyLarge,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Пиши свободно...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
