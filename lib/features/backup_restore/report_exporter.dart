import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/date_helpers.dart';
import '../../database/app_database.dart';
import '../../database/models.dart';

/// Generates and exports user nutrition, macro, hydration, and profile reports
/// in PDF, CSV, TXT, and Markdown (MD) formats 100% offline on-device.
class FitNepalReportExporter {
  FitNepalReportExporter._();

  static Future<({
    UserProfile profile,
    NutritionGoal goal,
    List<FoodLogEntry> foodLogs,
    List<WaterLogEntry> waterLogs,
  })> _loadReportData(AppDatabase db) async {
    final profile = await db.getProfileOnce();
    final goal = await db.getActiveGoalOnce();
    final start = DateTime(2020, 1, 1);
    final end = DateTime.now().add(const Duration(days: 2));
    final foodLogs = await db.watchFoodLogsInRange(start, end).first;
    final waterLogs = await db.watchWaterLogsInRange(start, end).first;
    return (
      profile: profile,
      goal: goal,
      foodLogs: foodLogs.reversed.toList(),
      waterLogs: waterLogs.reversed.toList(),
    );
  }

  /// Generates a CSV spreadsheet string of all logged meals and water entries.
  static Future<String> generateCsv(AppDatabase db) async {
    final data = await _loadReportData(db);
    final sb = StringBuffer();
    sb.writeln(
      'Type,Date,Time,Meal/Category,Item Name,Quantity,Unit,Calories (kcal),Protein (g),Carbs (g),Fats (g),Water (ml)',
    );

    for (final f in data.foodLogs) {
      final d = LocalDateHelpers.dateKey(f.loggedAt);
      final t =
          '${f.loggedAt.hour.toString().padLeft(2, '0')}:${f.loggedAt.minute.toString().padLeft(2, '0')}';
      final safeName = f.foodNameSnapshot.replaceAll('"', '""');
      final safeUnit = f.servingLabel.replaceAll('"', '""');
      sb.writeln(
        'FOOD,$d,$t,${f.mealType},"$safeName",${f.quantity},"$safeUnit",${f.kcalSnapshot},${f.proteinSnapshot},${f.carbsSnapshot},${f.fatSnapshot},0',
      );
    }

    for (final w in data.waterLogs) {
      final d = LocalDateHelpers.dateKey(w.loggedAt);
      final t =
          '${w.loggedAt.hour.toString().padLeft(2, '0')}:${w.loggedAt.minute.toString().padLeft(2, '0')}';
      sb.writeln(
        'WATER,$d,$t,Hydration,"Water Intake",1,"ml",0,0,0,0,${w.amountMl}',
      );
    }
    return sb.toString();
  }

  /// Generates a clean Markdown (.md) report.
  static Future<String> generateMarkdown(AppDatabase db) async {
    final data = await _loadReportData(db);
    final p = data.profile;
    final g = data.goal;
    final totalKcal =
        data.foodLogs.fold<int>(0, (s, e) => s + e.kcalSnapshot);
    final totalProt =
        data.foodLogs.fold<double>(0.0, (s, e) => s + e.proteinSnapshot);
    final totalCarbs =
        data.foodLogs.fold<double>(0.0, (s, e) => s + e.carbsSnapshot);
    final totalFat =
        data.foodLogs.fold<double>(0.0, (s, e) => s + e.fatSnapshot);
    final totalWater =
        data.waterLogs.fold<int>(0, (s, e) => s + e.amountMl);

    final sb = StringBuffer();
    sb.writeln('# FitNepal v5.0 Elite — Personal Nutrition & Hydration Report');
    sb.writeln();
    sb.writeln('- **Generated At**: ${DateTime.now().toIso8601String()}');
    sb.writeln('- **Name**: ${p.displayName} (${p.tagline})');
    sb.writeln(
      '- **Profile**: ${p.normalizedGender} | ${p.age} yrs | ${p.heightCm.round()} cm | ${p.weightKg.round()} kg | BMI ${p.bmiLabel}',
    );
    sb.writeln(
      '- **Daily Targets**: ${g.calorieTarget} kcal | Protein ${g.proteinTargetG.round()}g | Carbs ${g.carbsTargetG.round()}g | Fats ${g.fatTargetG.round()}g | Water ${g.waterTargetMl} ml',
    );
    sb.writeln();
    sb.writeln('## Cumulative Summary');
    sb.writeln('- **Total Logged Meals**: ${data.foodLogs.length}');
    sb.writeln('- **Total Calories**: $totalKcal kcal');
    sb.writeln(
      '- **Total Macros**: Protein ${totalProt.toStringAsFixed(1)}g | Carbs ${totalCarbs.toStringAsFixed(1)}g | Fats ${totalFat.toStringAsFixed(1)}g',
    );
    sb.writeln('- **Total Hydration**: $totalWater ml (${data.waterLogs.length} entries)');
    sb.writeln();
    sb.writeln('## Food Log History');
    sb.writeln('| Date | Meal | Food Item | Qty | Calories | P (g) | C (g) | F (g) |');
    sb.writeln('| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |');
    for (final f in data.foodLogs) {
      sb.writeln(
        '| ${LocalDateHelpers.dateKey(f.loggedAt)} | ${f.mealType} | ${f.foodNameSnapshot} | ${f.quantity} x ${f.servingLabel} | ${f.kcalSnapshot} kcal | ${f.proteinSnapshot} | ${f.carbsSnapshot} | ${f.fatSnapshot} |',
      );
    }
    sb.writeln();
    sb.writeln('## Hydration History');
    sb.writeln('| Date | Time | Amount (ml) |');
    sb.writeln('| :--- | :--- | :---: |');
    for (final w in data.waterLogs) {
      final t =
          '${w.loggedAt.hour.toString().padLeft(2, '0')}:${w.loggedAt.minute.toString().padLeft(2, '0')}';
      sb.writeln('| ${LocalDateHelpers.dateKey(w.loggedAt)} | $t | ${w.amountMl} ml |');
    }
    return sb.toString();
  }

  /// Generates a clean Plain Text (.txt) report.
  static Future<String> generateTxt(AppDatabase db) async {
    final data = await _loadReportData(db);
    final p = data.profile;
    final g = data.goal;
    final totalKcal =
        data.foodLogs.fold<int>(0, (s, e) => s + e.kcalSnapshot);
    final totalProt =
        data.foodLogs.fold<double>(0.0, (s, e) => s + e.proteinSnapshot);
    final totalWater =
        data.waterLogs.fold<int>(0, (s, e) => s + e.amountMl);

    final sb = StringBuffer();
    sb.writeln('==============================================================');
    sb.writeln('   FITNEPAL v5.0 ELITE - NUTRITION & HYDRATION REPORT');
    sb.writeln('==============================================================');
    sb.writeln('Exported  : ${DateTime.now().toLocal()}');
    sb.writeln('User      : ${p.displayName}');
    sb.writeln(
      'Stats     : ${p.normalizedGender}, ${p.age} yrs, ${p.heightCm.round()} cm, ${p.weightKg.round()} kg (BMI ${p.bmiLabel})',
    );
    sb.writeln(
      'Goals     : ${g.calorieTarget} kcal | P ${g.proteinTargetG.round()}g | C ${g.carbsTargetG.round()}g | F ${g.fatTargetG.round()}g | Water ${g.waterTargetMl} ml',
    );
    sb.writeln('--------------------------------------------------------------');
    sb.writeln(
      'TOTALS    : ${data.foodLogs.length} meals | $totalKcal kcal | Protein ${totalProt.toStringAsFixed(1)}g | Water $totalWater ml',
    );
    sb.writeln('--------------------------------------------------------------');
    sb.writeln('FOOD LOGS:');
    if (data.foodLogs.isEmpty) {
      sb.writeln('  (No food entries recorded)');
    } else {
      for (final f in data.foodLogs) {
        sb.writeln(
          '  [${LocalDateHelpers.dateKey(f.loggedAt)}] ${f.mealType.padRight(9)} | ${f.foodNameSnapshot} (${f.quantity} x ${f.servingLabel}) -> ${f.kcalSnapshot} kcal (P:${f.proteinSnapshot}g C:${f.carbsSnapshot}g F:${f.fatSnapshot}g)',
        );
      }
    }
    sb.writeln('--------------------------------------------------------------');
    sb.writeln('WATER LOGS:');
    if (data.waterLogs.isEmpty) {
      sb.writeln('  (No water entries recorded)');
    } else {
      for (final w in data.waterLogs) {
        sb.writeln(
          '  [${LocalDateHelpers.dateKey(w.loggedAt)}] +${w.amountMl} ml',
        );
      }
    }
    sb.writeln('==============================================================');
    return sb.toString();
  }

  /// Generates a valid binary PDF 1.4 document containing the user's report.
  static Future<Uint8List> generatePdfBytes(AppDatabase db) async {
    final txt = await generateTxt(db);
    final rawLines = txt.split('\n');
    final lines = <String>[];
    for (final line in rawLines) {
      // Sanitize to printable ASCII for standard PDF Type1 Helvetica encoding
      final ascii = line.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
      if (ascii.length > 88) {
        lines.add(ascii.substring(0, 88));
        lines.add('  ${ascii.substring(88)}');
      } else {
        lines.add(ascii);
      }
    }

    final streamBuffer = StringBuffer();
    streamBuffer.writeln('BT');
    streamBuffer.writeln('/F1 10 Tf');
    streamBuffer.writeln('14 TL');
    streamBuffer.writeln('36 756 Td');

    final maxLines = lines.length.clamp(0, 50);
    for (var i = 0; i < maxLines; i++) {
      final escaped = lines[i]
          .replaceAll(r'\', r'\\')
          .replaceAll('(', r'\(')
          .replaceAll(')', r'\)');
      streamBuffer.writeln('($escaped) Tj');
      if (i < maxLines - 1) {
        streamBuffer.writeln('T*');
      }
    }
    streamBuffer.writeln('ET');
    final contentStream = streamBuffer.toString();
    final contentLength = utf8.encode(contentStream).length;

    final pdf = StringBuffer();
    pdf.write('%PDF-1.4\n');
    final obj1Offset = pdf.length;
    pdf.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    final obj2Offset = pdf.length;
    pdf.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
    final obj3Offset = pdf.length;
    pdf.write(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
    );
    final obj4Offset = pdf.length;
    pdf.write(
      '4 0 obj\n<< /Length $contentLength >>\nstream\n$contentStream\nendstream\nendobj\n',
    );
    final obj5Offset = pdf.length;
    pdf.write(
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n',
    );
    final xrefOffset = pdf.length;

    String pad10(int n) => n.toString().padLeft(10, '0');
    pdf.write('xref\n0 6\n');
    pdf.write('0000000000 65535 f \n');
    pdf.write('${pad10(obj1Offset)} 00000 n \n');
    pdf.write('${pad10(obj2Offset)} 00000 n \n');
    pdf.write('${pad10(obj3Offset)} 00000 n \n');
    pdf.write('${pad10(obj4Offset)} 00000 n \n');
    pdf.write('${pad10(obj5Offset)} 00000 n \n');
    pdf.write(
      'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n',
    );

    return Uint8List.fromList(utf8.encode(pdf.toString()));
  }

  /// Exports and saves the chosen format ('pdf' | 'csv' | 'txt' | 'md') using
  /// Android Storage Access Framework, with clipboard fallback for text formats.
  static Future<String> exportReport({
    required BuildContext context,
    required AppDatabase db,
    required String format, // 'pdf' | 'csv' | 'txt' | 'md'
  }) async {
    final dateStamp = DateTime.now().toIso8601String().split('T').first;
    final ext = format.toLowerCase();
    final fileName = 'fitnepal_report_$dateStamp.$ext';

    late final Uint8List bytes;
    String? textPreview;

    if (ext == 'pdf') {
      bytes = await generatePdfBytes(db);
    } else if (ext == 'csv') {
      textPreview = await generateCsv(db);
      bytes = Uint8List.fromList(utf8.encode(textPreview));
    } else if (ext == 'md') {
      textPreview = await generateMarkdown(db);
      bytes = Uint8List.fromList(utf8.encode(textPreview));
    } else {
      textPreview = await generateTxt(db);
      bytes = Uint8List.fromList(utf8.encode(textPreview));
    }

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export FitNepal Report ($ext)',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [ext],
      bytes: bytes,
    );

    if (savedPath != null) {
      return 'Exported $fileName successfully!';
    }
    if (textPreview != null) {
      await Clipboard.setData(ClipboardData(text: textPreview));
      return 'Copied ${ext.toUpperCase()} report to clipboard!';
    }
    return 'Export cancelled.';
  }
}
