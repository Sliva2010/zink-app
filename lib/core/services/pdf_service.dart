import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/note.dart';

/// Экспорт конспектов в PDF в фирменном стиле ZINK (B&W).
class PdfService {
  PdfService._();

  static Future<File> exportNoteToPdf(Note note) async {
    final doc = pw.Document(title: note.title, author: 'ZINK');

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Bold.ttf'),
    );
    final fontSemi = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 56, 48, 48),
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(font: fontRegular, fontSize: 12),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'ZINK',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 18,
                  letterSpacing: 3,
                ),
              ),
              pw.Text(
                'персональный ИИ-репетитор',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'стр. ${context.pageNumber} из ${context.pagesCount}',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1.4),
              ),
            ),
            child: pw.Text(
              note.title,
              style: pw.TextStyle(font: fontBold, fontSize: 26, height: 1.1),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              if (note.subject != null && note.subject!.isNotEmpty) ...[
                _chip(note.subject!, fontSemi),
                pw.SizedBox(width: 8),
              ],
              for (final tag in note.tags) ...[
                _chip('#$tag', fontSemi),
                pw.SizedBox(width: 8),
              ],
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            note.content,
            style: pw.TextStyle(font: fontRegular, fontSize: 12, height: 1.55),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 6),
          pw.Text(
            'создано: ${note.createdAt.toLocal()}',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    return _saveBytes(bytes, _safeFileName('${note.title}.pdf'));
  }

  static pw.Widget _chip(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9)),
    );
  }

  static Future<File> _saveBytes(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _safeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll('\n', ' ')
        .trim();
  }

  static Future<void> sharePdf(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: text ?? 'Конспект ZINK',
    );
  }
}
