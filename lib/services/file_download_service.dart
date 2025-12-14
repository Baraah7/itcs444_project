import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'download_service.dart';

class FileDownloadService {
  
  // Save text file (JSON/CSV)
  Future<String?> saveTextFile(String content, String fileName) async {
    try {
      if (fileName.endsWith('.csv')) {
        return await DownloadService.saveCsv(content, fileName);
      } else {
        // Assume JSON if not CSV
        final jsonData = jsonDecode(content) as Map<String, dynamic>;
        return await DownloadService.saveJson(jsonData, fileName);
      }
    } catch (e) {
      if (kDebugMode) print('Error saving file: $e');
      return null;
    }
  }

  // Generate and save PDF
  Future<String?> generatePDF(Map<String, dynamic> reportData) async {
    try {
      final pdf = pw.Document();
      final summary = reportData['executiveSummary'] ?? {};
      final recommendations = (reportData['recommendations'] as List?) ?? [];
      final metadata = reportData['reportMetadata'] ?? {};
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Care Center Equipment Management Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Report Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Generated: ${metadata['generatedAt'] ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
                    pw.Text('Version: ${metadata['version'] ?? '1.0'}'),
                    pw.Text('Period: ${metadata['reportPeriod'] ?? 'All Time'}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Executive Summary
              pw.Header(
                level: 1,
                child: pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildPdfTableRow('Performance Status', summary['performanceStatus']?.toString() ?? 'Normal', true),
                  _buildPdfTableRow('Total Equipment Items', '${summary['totalEquipmentItems'] ?? 0}'),
                  _buildPdfTableRow('Total Rentals', '${summary['totalRentals'] ?? 0}'),
                  _buildPdfTableRow('Utilization Rate', '${(summary['utilizationRate'] ?? 0).toStringAsFixed(1)}%'),
                  _buildPdfTableRow('Total Revenue', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
                  _buildPdfTableRow('Overdue Rate', '${(summary['overdueRate'] ?? 0).toStringAsFixed(1)}%'),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Key Metrics
              if (summary['keyMetrics'] != null) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text('Key Metrics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableRow('Active Rentals', '${summary['keyMetrics']['activeRentals'] ?? 0}', true),
                    _buildPdfTableRow('Available Equipment', '${summary['keyMetrics']['availableEquipment'] ?? 0}'),
                    _buildPdfTableRow('Average Revenue per Rental', '\$${(summary['keyMetrics']['averageRevenuePerRental'] ?? 0).toStringAsFixed(2)}'),
                  ],
                ),
                
                pw.SizedBox(height: 30),
              ],
              
              // Recommendations
              if (recommendations.isNotEmpty) ...[
                pw.Header(
                  level: 1,
                  child: pw.Text('Recommendations', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                
                pw.SizedBox(height: 10),
                
                ...recommendations.map((rec) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _getPriorityColor(rec['priority']?.toString()),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              rec['priority']?.toString() ?? 'Medium',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            rec['category']?.toString() ?? 'General',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        rec['title']?.toString() ?? 'Recommendation',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        rec['description']?.toString() ?? '',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (rec['actionItems'] != null) ...[
                        pw.SizedBox(height: 8),
                        pw.Text('Action Items:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        ...((rec['actionItems'] as List?) ?? []).map((item) => 
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                            child: pw.Text('- $item', style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
              
              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'This report was automatically generated by the Care Center Equipment Management System.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ];
          },
        ),
      );

      final fileName = 'care_center_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final bytes = await pdf.save();
      return await DownloadService.savePdf(bytes, fileName);
    } catch (e) {
      if (kDebugMode) print('Error generating PDF: $e');
      return null;
    }
  }

  pw.TableRow _buildPdfTableRow(String label, String value, [bool isHeader = false]) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  PdfColor _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return PdfColors.red;
      case 'medium':
        return PdfColors.orange;
      case 'low':
        return PdfColors.green;
      default:
        return PdfColors.blue;
    }
  }
}