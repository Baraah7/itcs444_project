import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'reports_service.dart';

class ReportExportService {
  final ReportsService _reportsService = ReportsService();

  // Generate comprehensive report data
  Future<Map<String, dynamic>> generateComprehensiveReport() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    try {
      // Gather all report data
      final usageAnalytics = await _reportsService.getUsageAnalytics();
      final mostRented = await _reportsService.getMostRentedEquipment();
      final mostDonated = await _reportsService.getMostDonatedEquipment();
      final overdueStats = await _reportsService.getOverdueStatistics();
      final maintenanceRecords = await _reportsService.getMaintenanceRecords();
      final monthlyTrends = await _reportsService.getMonthlyTrends();
      final efficiencyInsights = await _reportsService.getEfficiencyInsights();

      return {
        'reportMetadata': {
          'title': 'Care Center Equipment Management Report',
          'generatedAt': formatter.format(now),
          'reportPeriod': 'All Time',
          'version': '1.0',
        },
        'executiveSummary':
            _generateExecutiveSummary(usageAnalytics, overdueStats),
        'usageAnalytics': usageAnalytics,
        'equipmentPerformance': {
          'mostRented': mostRented,
          'mostDonated': mostDonated,
          'efficiencyInsights': efficiencyInsights,
        },
        'overdueAnalysis': overdueStats,
        'maintenanceRecords': maintenanceRecords,
        'trends': {
          'monthly': monthlyTrends,
        },
        'recommendations': _generateRecommendations(
            usageAnalytics, overdueStats, efficiencyInsights),
      };
    } catch (e) {
      if (kDebugMode) print('Error generating report: $e');
      rethrow;
    }
  }

  // Generate executive summary
  Map<String, dynamic> _generateExecutiveSummary(
    Map<String, dynamic> usage,
    Map<String, dynamic> overdue,
  ) {
    final utilizationRate = (usage['utilizationRate'] is int)
        ? (usage['utilizationRate'] as int).toDouble()
        : (usage['utilizationRate'] as double? ?? 0.0);
    final overdueRate = (overdue['overdueRate'] is int)
        ? (overdue['overdueRate'] as int).toDouble()
        : (overdue['overdueRate'] as double? ?? 0.0);
    final totalRevenue = (usage['totalRevenue'] is int)
        ? (usage['totalRevenue'] as int).toDouble()
        : (usage['totalRevenue'] as double? ?? 0.0);

    String performanceStatus;
    if (utilizationRate > 75) {
      performanceStatus = 'Excellent';
    } else if (utilizationRate > 50) {
      performanceStatus = 'Good';
    } else if (utilizationRate > 25) {
      performanceStatus = 'Fair';
    } else {
      performanceStatus = 'Needs Improvement';
    }

    return {
      'totalEquipmentItems': usage['totalEquipment'],
      'totalRentals': usage['totalRentals'],
      'utilizationRate': utilizationRate,
      'performanceStatus': performanceStatus,
      'totalRevenue': totalRevenue,
      'overdueRate': overdueRate,
      'keyMetrics': {
        'activeRentals': usage['activeRentals'],
        'availableEquipment': usage['availableEquipment'],
        'averageRevenuePerRental': usage['averageRevenuePerRental'],
      },
    };
  }

  // Generate actionable recommendations
  List<Map<String, dynamic>> _generateRecommendations(
    Map<String, dynamic> usage,
    Map<String, dynamic> overdue,
    Map<String, dynamic> efficiency,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Utilization recommendations
    final utilizationRate = (usage['utilizationRate'] is int)
        ? (usage['utilizationRate'] as int).toDouble()
        : (usage['utilizationRate'] as double? ?? 0.0);
    if (utilizationRate < 50) {
      recommendations.add({
        'category': 'Utilization',
        'priority': 'High',
        'title': 'Improve Equipment Utilization',
        'description':
            'Current utilization rate is ${utilizationRate.toStringAsFixed(1)}%. Consider marketing campaigns or pricing adjustments.',
        'actionItems': [
          'Review pricing strategy',
          'Implement promotional campaigns',
          'Analyze customer feedback',
          'Consider equipment relocation',
        ],
      });
    }

    // Overdue recommendations
    final overdueRate = (overdue['overdueRate'] is int)
        ? (overdue['overdueRate'] as int).toDouble()
        : (overdue['overdueRate'] as double? ?? 0.0);
    if (overdueRate > 10) {
      recommendations.add({
        'category': 'Overdue Management',
        'priority': 'High',
        'title': 'Reduce Overdue Rentals',
        'description':
            'Overdue rate is ${overdueRate.toStringAsFixed(1)}%. Implement better tracking and reminder systems.',
        'actionItems': [
          'Implement automated reminder system',
          'Review rental periods',
          'Increase late fees',
          'Improve customer communication',
        ],
      });
    }

    // Efficiency recommendations
    final underutilized = efficiency['underutilized'] as List;
    if (underutilized.isNotEmpty) {
      recommendations.add({
        'category': 'Equipment Efficiency',
        'priority': 'Medium',
        'title': 'Address Underutilized Equipment',
        'description':
            '${underutilized.length} equipment items are underutilized.',
        'actionItems': [
          'Review equipment demand patterns',
          'Consider equipment redistribution',
          'Evaluate equipment retirement',
          'Adjust inventory levels',
        ],
      });
    }

    // High performing equipment
    final highPerforming = efficiency['highPerforming'] as List;
    if (highPerforming.isNotEmpty) {
      recommendations.add({
        'category': 'Inventory Expansion',
        'priority': 'Medium',
        'title': 'Expand High-Demand Equipment',
        'description':
            '${highPerforming.length} equipment types have high demand.',
        'actionItems': [
          'Increase inventory for high-demand items',
          'Consider bulk purchasing discounts',
          'Evaluate supplier relationships',
          'Plan for seasonal demand',
        ],
      });
    }

    // Revenue optimization
    final avgRevenue = (usage['averageRevenuePerRental'] is int)
        ? (usage['averageRevenuePerRental'] as int).toDouble()
        : (usage['averageRevenuePerRental'] as double? ?? 0.0);
    if (avgRevenue < 50) {
      recommendations.add({
        'category': 'Revenue Optimization',
        'priority': 'Medium',
        'title': 'Optimize Pricing Strategy',
        'description':
            'Average revenue per rental is \$${avgRevenue.toStringAsFixed(2)}.',
        'actionItems': [
          'Conduct market pricing analysis',
          'Implement dynamic pricing',
          'Offer package deals',
          'Review rental duration policies',
        ],
      });
    }

    return recommendations;
  }

  // Export report as JSON string
  String exportAsJson(Map<String, dynamic> reportData) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(reportData);
  }

  // Export report as CSV format (simplified)
  String exportAsCsv(Map<String, dynamic> reportData) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Care Center Equipment Management Report');
    buffer.writeln('Generated: ${reportData['reportMetadata']['generatedAt']}');
    buffer.writeln('');

    // Executive Summary
    buffer.writeln('EXECUTIVE SUMMARY');
    final summary = reportData['executiveSummary'];
    buffer.writeln('Total Equipment,${summary['totalEquipmentItems']}');
    buffer.writeln('Total Rentals,${summary['totalRentals']}');
    buffer.writeln(
        'Utilization Rate,${summary['utilizationRate'].toStringAsFixed(1)}%');
    buffer.writeln('Performance Status,${summary['performanceStatus']}');
    buffer.writeln(
        'Total Revenue,\$${summary['totalRevenue'].toStringAsFixed(2)}');
    buffer
        .writeln('Overdue Rate,${summary['overdueRate'].toStringAsFixed(1)}%');
    buffer.writeln('');

    // Most Rented Equipment
    buffer.writeln('MOST RENTED EQUIPMENT');
    buffer.writeln('Equipment Name,Rental Count');
    final mostRented = reportData['equipmentPerformance']['mostRented'] as List;
    for (final item in mostRented) {
      buffer.writeln('${item['name']},${item['count']}');
    }
    buffer.writeln('');

    // Recommendations
    buffer.writeln('RECOMMENDATIONS');
    buffer.writeln('Category,Priority,Title,Description');
    final recommendations = reportData['recommendations'] as List;
    for (final rec in recommendations) {
      buffer.writeln(
          '${rec['category']},${rec['priority']},${rec['title']},"${rec['description']}"');
    }

    return buffer.toString();
  }

  // Generate summary statistics for dashboard
  Future<Map<String, dynamic>> generateDashboardSummary() async {
    try {
      final usageAnalytics = await _reportsService.getUsageAnalytics();
      final overdueStats = await _reportsService.getOverdueStatistics();

      return {
        'totalRentals': usageAnalytics['totalRentals'],
        'activeRentals': usageAnalytics['activeRentals'],
        'utilizationRate': usageAnalytics['utilizationRate'],
        'totalRevenue': usageAnalytics['totalRevenue'],
        'overdueCount': overdueStats['overdueCount'],
        'overdueRate': overdueStats['overdueRate'],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('Error generating dashboard summary: $e');
      return {};
    }
  }
}
