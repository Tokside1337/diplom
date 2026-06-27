import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:diplom/models/emk_model.dart';
import 'package:diplom/models/patient.dart';

class PdfService {
  static Future<void> printEMK(EMK emk, Patient patient) async {
    try {
      debugPrint('Начало генерации PDF...');
      final pw.Document doc = pw.Document();
      final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Arial-Regular.ttf'),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Arial-Bold.ttf'),
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ЭЛЕКТРОННАЯ МЕДИЦИНСКАЯ КАРТА', style: pw.TextStyle(font: boldFont, fontSize: 18)),
                    pw.Text('РеСтарт', style: const pw.TextStyle(color: PdfColors.blue)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Информация о пациенте
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ПАЦИЕНТ: ${patient.name}', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                    pw.Text('Дата рождения: ${patient.birthDate}'),
                    pw.Text('Дата формирования выписки: ${DateTime.now().toString().substring(0, 16)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              _buildPdfSection('1. САНАТОРНО-КУРОРТНАЯ КАРТА (СКК)', {
                'Номер СКК': patient.skkNumber,
                'Дата выдачи': patient.skkDate,
                'Кем выдана': patient.issuedByLpu,
                'Основной диагноз (МКБ)': patient.mainDiagnosisMkb,
                'Диет. стол': patient.dietTable,
                'Режим': patient.mobilityRegime,
                'Группа здоровья': patient.healthGroup,
              }, boldFont),
              _buildPdfSection('2. ДИАГНОЗЫ (КЛИНИЧЕСКИЕ)', emk.diagnoses, boldFont),
              _buildPdfSection('3. ПРОТИВОПОКАЗАНИЯ', emk.contraindications, boldFont),
              _buildPdfSection('4. ЦЕЛИ ЛЕЧЕНИЯ (SMART)', emk.treatmentGoals, boldFont),
              
              pw.SizedBox(height: 10),
              pw.Text('5.1 ЕЖЕДНЕВНЫЕ ЗАПИСИ (ДНЕВНИК)', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue900)),
              pw.Divider(),
              if (emk.dailyLogs.isEmpty) pw.Text('Нет записей', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ...emk.dailyLogs.map((log) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Bullet(text: log.toString(), style: const pw.TextStyle(fontSize: 10)),
              )),
              
              pw.SizedBox(height: 10),
              pw.Text('5.2 ЭТАПНЫЕ ОСМОТРЫ', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue900)),
              pw.Divider(),
              if (emk.stageReviews.isEmpty) pw.Text('Нет записей', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ...emk.stageReviews.map((step) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Bullet(text: step.toString(), style: const pw.TextStyle(fontSize: 10)),
              )),

              pw.SizedBox(height: 10),
              _buildPdfSection('6. ИТОГОВЫЕ РЕКОМЕНДАЦИИ', emk.finalRecommendations, boldFont),

              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Лечащий врач: ____________________'),
                      pw.SizedBox(height: 5),
                      pw.Text('М.П.', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Text('Подпись пациента: ____________________'),
                ],
              ),
            ];
          },
        ),
      );

      debugPrint('Отправка на печать...');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'EMK_${patient.name}.pdf',
        format: PdfPageFormat.a4,
      );
      debugPrint('Печать инициирована успешно');
    } catch (e) {
      debugPrint('Критическая ошибка печати: $e');
    }
  }

  static pw.Widget _buildPdfSection(String title, Map<String, dynamic> data, pw.Font bold) {
    final entries = data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.blue900)),
        pw.Divider(),
        if (entries.isEmpty)
          pw.Text('Не заполнено', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
        else
          ...entries.map((e) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: '${e.key}: ', style: pw.TextStyle(font: bold, fontSize: 10)),
                  pw.TextSpan(text: e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          )),
      ],
    );
  }
}
