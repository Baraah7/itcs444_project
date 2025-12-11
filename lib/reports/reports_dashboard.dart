import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/reports_service.dart';
import '../services/report_export_service.dart';
import '../services/file_download_service.dart';
import 'charts/most_rented_chart.dart';
import 'charts/overdue_rented_chart.dart';

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() => _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard> with SingleTickerProviderStateMixin {
  final ReportsService _reportsService = ReportsService();
  final ReportExportService _exportService = ReportExportService();
  final FileDownloadService _downloadService = FileDownloadService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Reports',
            onPressed: () => _showExportMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up_outlined), text: 'Usage'),
            Tab(icon: Icon(Icons.warning_amber_outlined), text: 'Overdue'),
            Tab(icon: Icon(Icons.build_outlined), text: 'Maintenance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsageTab(),
          _buildOverdueTab(),
          _buildMaintenanceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          _buildSectionHeader('Key Metrics'),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _reportsService.getUsageAnalytics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load analytics');
              }
              if (!snapshot.hasData) {
                return _buildEmptyWidget('No analytics data available');
              }
              
              final analytics = snapshot.data!;
              return _buildMetricsGrid(analytics);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Most Rented Equipment Chart
          _buildSectionHeader('Most Rented Equipment'),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reportsService.getMostRentedEquipment(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load rental data');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget('No rental data available');
              }
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MostRentedChart(data: snapshot.data!),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Monthly Trends
          _buildSectionHeader('Monthly Rental Trends'),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reportsService.getMonthlyTrends(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load trend data');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget('No trend data available');
              }
              return _buildMonthlyTrendsChart(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Efficiency Insights
          _buildSectionHeader('Efficiency Insights'),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _reportsService.getEfficiencyInsights(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load insights');
              }
              if (!snapshot.hasData) {
                return _buildEmptyWidget('No insights available');
              }
              
              final insights = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightsCard(insights),
                  
                  const SizedBox(height: 32),
                  
                  if (insights['highPerforming']?.isNotEmpty ?? false) ...[
                    _buildSectionHeader('High Performing Equipment'),
                    const SizedBox(height: 12),
                    _buildEquipmentList(insights['highPerforming'], Colors.green),
                    const SizedBox(height: 24),
                  ],
                  
                  if (insights['underutilized']?.isNotEmpty ?? false) ...[
                    _buildSectionHeader('Underutilized Equipment'),
                    const SizedBox(height: 12),
                    _buildEquipmentList(insights['underutilized'], Colors.orange),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
          
          // Most Donated Equipment
          _buildSectionHeader('Most Donated Equipment'),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reportsService.getMostDonatedEquipment(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load donation data');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget('No donation data available');
              }
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MostRentedChart(data: snapshot.data!, title: 'Most Donated Equipment'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Overdue Statistics'),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _reportsService.getOverdueStatistics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load overdue statistics');
              }
              if (!snapshot.hasData) {
                return _buildEmptyWidget('No overdue statistics available');
              }
              
              final stats = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverdueMetrics(stats),
                  
                  const SizedBox(height: 32),
                  
                  if (stats['overdueEquipment']?.isNotEmpty ?? false) ...[
                    _buildSectionHeader('Overdue Equipment by Type'),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: OverdueChart(overdueData: stats),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Maintenance Records'),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reportsService.getMaintenanceRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }
              if (snapshot.hasError) {
                return _buildErrorWidget('Failed to load maintenance records');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyWidget('No maintenance records found');
              }
              
              final records = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) => _buildMaintenanceCard(records[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> analytics) {
    final metrics = [
      _MetricItem('Total Rentals', analytics['totalRentals'].toString(), Icons.event_available, Colors.blue),
      _MetricItem('Active Rentals', analytics['activeRentals'].toString(), Icons.schedule, Colors.green),
      _MetricItem('Utilization Rate', '${analytics['utilizationRate'].toStringAsFixed(1)}%', Icons.trending_up, Colors.orange),
      _MetricItem('Total Revenue', '\$${analytics['totalRevenue'].toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          metric.title,
          metric.value,
          metric.icon,
          metric.color,
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last ${data.length} Months',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(data),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.length) {
                            final month = data[value.toInt()]['month'].toString();
                            final parts = month.split('-');
                            if (parts.length >= 2) {
                              return Text(
                                '${parts[1]}/${parts[0].substring(2)}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['count'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10;
    final maxCount = data.map((d) => d['count'].toDouble()).reduce((a, b) => a > b ? a : b);
    return maxCount > 100 ? 20 : maxCount > 50 ? 10 : 5;
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    final insightsList = (insights['insights'] as List<String>?) ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Key Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insightsList.isEmpty)
              const Text(
                'All equipment is performing within normal ranges.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...insightsList.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentList(List<Map<String, dynamic>> equipment, Color color) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: equipment.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = equipment[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.medical_services_outlined, color: color),
            ),
            title: Text(
              item['name'] ?? 'Unknown Equipment',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Utilization: ${(item['utilizationRate'] ?? 0 * 100).toStringAsFixed(1)}%',
            ),
            trailing: Chip(
              label: Text(
                '${item['rentalCount'] ?? 0} rentals',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverdueMetrics(Map<String, dynamic> stats) {
    final metrics = [
      _MetricItem('Overdue Items', stats['overdueCount']?.toString() ?? '0', Icons.warning, Colors.red),
      _MetricItem('Overdue Rate', '${(stats['overdueRate'] ?? 0).toStringAsFixed(1)}%', Icons.trending_down, Colors.orange),
      _MetricItem('Late Fees', '\$${(stats['totalLateFees'] ?? 0).toStringAsFixed(0)}', Icons.attach_money, Colors.green),
      _MetricItem('Equipment Types', (stats['overdueEquipment']?.length ?? 0).toString(), Icons.category, Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _buildMetricCard(
          metric.title,
          metric.value,
          metric.icon,
          metric.color,
        );
      },
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> record) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Icon(Icons.build_outlined, color: Colors.purple),
        ),
        title: Text(
          record['equipmentName'] ?? 'Unknown Equipment',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record['userFullName'] != null)
              Text('User: ${record['userFullName']}'),
            if (record['adminNotes'] != null && record['adminNotes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Notes: ${record['adminNotes']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: record['maintenanceDate'] != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateTime.parse(record['maintenanceDate']).toString().substring(0, 10),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateTime.parse(record['maintenanceDate']).toString().substring(11, 16),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : const Text('No date', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export as JSON'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('json');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('csv');
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Generate PDF Summary'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('pdf');
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('View Summary'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('summary');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handleExport(String format) async {
    try {
      _showLoadingDialog();
      final reportData = await _exportService.generateComprehensiveReport();
      Navigator.of(context).pop();
      
      switch (format) {
        case 'json':
          final exportedData = _exportService.exportAsJson(reportData);
          final fileName = 'care_center_report_${DateTime.now().millisecondsSinceEpoch}.json';
          _showExportDialog(exportedData, fileName);
          break;
        case 'csv':
          final exportedData = _exportService.exportAsCsv(reportData);
          final fileName = 'care_center_report_${DateTime.now().millisecondsSinceEpoch}.csv';
          _showExportDialog(exportedData, fileName);
          break;
        case 'pdf':
          await _generateAndDownloadPDF(reportData);
          break;
        case 'summary':
          _showSummaryDialog(reportData);
          break;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Failed to generate report: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 20),
              const Text('Generating report...'),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(String data, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.maxFinite,
              height: 200,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      data,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _downloadFile(data, fileName);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String content, String fileName) async {
    try {
      final filePath = await _downloadService.saveTextFile(content, fileName);
      if (filePath != null) {
        _showSuccessDialog('File saved successfully', filePath);
      } else {
        _showErrorDialog('Failed to save file');
      }
    } catch (e) {
      _showErrorDialog('Error saving file: $e');
    }
  }

  Future<void> _generateAndDownloadPDF(Map<String, dynamic> reportData) async {
    try {
      final filePath = await _downloadService.generatePDF(reportData);
      if (filePath != null) {
        _showSuccessDialog('PDF generated successfully', filePath);
      } else {
        _showErrorDialog('Failed to generate PDF');
      }
    } catch (e) {
      _showErrorDialog('Error generating PDF: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog(Map<String, dynamic> reportData) {
    final summary = reportData['executiveSummary'] ?? {};
    final recommendations = (reportData['recommendations'] as List?) ?? [];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.summarize, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Executive Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem('Performance Status', summary['performanceStatus']?.toString() ?? 'Normal'),
                      _buildSummaryItem('Total Equipment', '${summary['totalEquipmentItems'] ?? 0}'),
                      _buildSummaryItem('Total Rentals', '${summary['totalRentals'] ?? 0}'),
                      _buildSummaryItem('Utilization Rate', '${(summary['utilizationRate'] ?? 0).toStringAsFixed(1)}%'),
                      _buildSummaryItem('Total Revenue', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
                      _buildSummaryItem('Overdue Rate', '${(summary['overdueRate'] ?? 0).toStringAsFixed(1)}%'),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Key Recommendations:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      if (recommendations.isEmpty)
                        const Text('No recommendations available', style: TextStyle(color: Colors.grey))
                      else
                        ...recommendations.take(3).map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: Colors.blue.withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec['title']?.toString() ?? 'Recommendation',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rec['description']?.toString() ?? '',
                                    style:  TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _MetricItem(this.title, this.value, this.icon, this.color);
}