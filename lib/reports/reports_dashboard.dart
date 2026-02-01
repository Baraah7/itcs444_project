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

class _ReportsDashboardState extends State<ReportsDashboard> {
  final ReportsService _reportsService = ReportsService();
  final ReportExportService _exportService = ReportExportService();
  final FileDownloadService _downloadService = FileDownloadService();
  String _selectedView = 'overview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6C67),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Export Reports',
            onPressed: () => _showExportMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          Expanded(
            child: _getSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _viewSelectorButton('Overview', _selectedView == 'overview'),
              const SizedBox(width: 12),
              _viewSelectorButton('Usage', _selectedView == 'usage'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _viewSelectorButton('Overdue', _selectedView == 'overdue'),
              const SizedBox(width: 12),
              _viewSelectorButton('Maintenance', _selectedView == 'maintenance'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewSelectorButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = label.toLowerCase();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 222, 235, 234) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFFE8ECEF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForLabel(label),
                size: 18,
                color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Overview':
        return Icons.analytics_outlined;
      case 'Usage':
        return Icons.trending_up_outlined;
      case 'Overdue':
        return Icons.warning_amber_outlined;
      case 'Maintenance':
        return Icons.build_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  Widget _getSelectedView() {
    switch (_selectedView) {
      case 'overview':
        return _buildOverviewTab();
      case 'usage':
        return _buildUsageTab();
      case 'overdue':
        return _buildOverdueTab();
      case 'maintenance':
        return _buildMaintenanceTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Key Metrics', Icons.dashboard_rounded),
          const SizedBox(height: 20),
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
          
          _buildSectionHeader('Most Rented Equipment', Icons.star_rounded),
          const SizedBox(height: 20),
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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MostRentedChart(data: snapshot.data!),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader('Monthly Rental Trends', Icons.show_chart_rounded),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Efficiency Insights', Icons.insights_rounded),
          const SizedBox(height: 20),
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
                    _buildSectionHeader('High Performing Equipment', Icons.rocket_launch_rounded),
                    const SizedBox(height: 16),
                    _buildEquipmentList(insights['highPerforming'], const Color(0xFF10B981)),
                    const SizedBox(height: 24),
                  ],
                  
                  if (insights['underutilized']?.isNotEmpty ?? false) ...[
                    _buildSectionHeader('Underutilized Equipment', Icons.trending_down_rounded),
                    const SizedBox(height: 16),
                    _buildEquipmentList(insights['underutilized'], const Color(0xFFF59E0B)),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueTab() {
    return const Center(
      child: Text('Overdue Tab - Coming Soon'),
    );
  }

  Widget _buildMaintenanceTab() {
    return const Center(
      child: Text('Maintenance Tab - Coming Soon'),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2B6C67), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2B6C67),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: const Text('Metrics Grid - Coming Soon'),
    );
  }

  Widget _buildMonthlyTrendsChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: const Text('Monthly Trends Chart - Coming Soon'),
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: const Text('Insights Card - Coming Soon'),
    );
  }

  Widget _buildEquipmentList(List<dynamic> equipment, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: const Text('Equipment List - Coming Soon'),
    );
  }

  void _showExportMenu(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: Color(0xFF2B6C67),
      ),
    );
  }
}