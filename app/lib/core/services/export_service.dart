import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/features/news/domain/entities/news_article.dart';

class ExportService {
  Future<void> shareMarkdown(NewsArticle article) async {
    final markdown = _generateMarkdown(article);
    // ignore: deprecated_member_use
    await Share.share(markdown, subject: article.title);
  }

  Future<void> copyMarkdownToClipboard(NewsArticle article) async {
    final markdown = _generateMarkdown(article);
    await Clipboard.setData(ClipboardData(text: markdown));
  }

  Future<void> sharePdf(NewsArticle article) async {
    final doc = pw.Document();

    // Load font if needed, or use standard
    // simple layout
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                article.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Source: ${article.source} • ${article.publishedAt.toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(article.summary, style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text(
                'Read more at: ${article.url}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${_sanitizeFilename(article.title)}.pdf',
    );
  }

  String _generateMarkdown(NewsArticle article) {
    return '''
# ${article.title}

**Source:** ${article.source}
**Date:** ${article.publishedAt.toString()}

${article.summary}

[Read full article](${article.url})
''';
  }

  String _sanitizeFilename(String title) {
    return title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
  }
}
