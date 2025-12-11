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
        centerTitle: true,
        
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Key Metrics
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
          
          // Most Rented Equipment Chart
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
          
          // Monthly Trends
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
          // Efficiency Insights
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
          
          // Most Donated Equipment
          _buildSectionHeader('Most Donated Equipment', Icons.volunteer_activism_rounded),
          const SizedBox(height: 20),
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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Overdue Statistics', Icons.access_time_rounded),
          const SizedBox(height: 20),
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
                    _buildSectionHeader('Overdue Equipment by Type', Icons.category_rounded),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8ECEF)),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Maintenance Records', Icons.handyman_rounded),
          const SizedBox(height: 20),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2B6C67).withOpacity(0.1),
            const Color(0xFF2B6C67).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2B6C67).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2B6C67),
                  Color(0xFF1A4A47),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
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
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF2B6C67)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF94A3B8),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> analytics) {
    final metrics = [
      _MetricItem('Total Rentals', analytics['totalRentals'].toString(), Icons.event_available, const Color(0xFF2B6C67)),
      _MetricItem('Active Rentals', analytics['activeRentals'].toString(), Icons.schedule, const Color(0xFF10B981)),
      _MetricItem('Utilization Rate', '${analytics['utilizationRate'].toStringAsFixed(1)}%', Icons.trending_up, const Color(0xFFF59E0B)),
      _MetricItem('Total Revenue', '\$${analytics['totalRevenue'].toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF8B5CF6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(List<Map<String, dynamic>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last ${data.length} Months',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(data),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFE8ECEF),
                        strokeWidth: 1,
                      );
                    },
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE8ECEF)),
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
                      color: const Color(0xFF2B6C67),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2B6C67).withOpacity(0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF2B6C67),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B6C67).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF2B6C67),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Key Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insightsList.isEmpty)
              const Text(
                'All equipment is performing within normal ranges.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              )
            else
              ...insightsList.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2B6C67),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.construction,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              item['name'] ?? 'Unknown Equipment',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'Utilization: ${(item['utilizationRate'] ?? 0 * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['rentalCount'] ?? 0} rentals',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverdueMetrics(Map<String, dynamic> stats) {
    final metrics = [
      _MetricItem('Overdue Items', stats['overdueCount']?.toString() ?? '0', Icons.warning, const Color(0xFFEF4444)),
      _MetricItem('Overdue Rate', '${(stats['overdueRate'] ?? 0).toStringAsFixed(1)}%', Icons.trending_down, const Color(0xFFF59E0B)),
      _MetricItem('Late Fees', '\$${(stats['totalLateFees'] ?? 0).toStringAsFixed(0)}', Icons.attach_money, const Color(0xFF10B981)),
      _MetricItem('Equipment Types', (stats['overdueEquipment']?.length ?? 0).toString(), Icons.category, const Color(0xFF8B5CF6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.build_outlined,
            color: Color(0xFF8B5CF6),
            size: 20,
          ),
        ),
        title: Text(
          record['equipmentName'] ?? 'Unknown Equipment',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record['userFullName'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'User: ${record['userFullName']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            if (record['adminNotes'] != null && record['adminNotes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Notes: ${record['adminNotes']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.parse(record['maintenanceDate']).toString().substring(11, 16),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              )
            : const Text(
                'No date',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
      ),
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B6C67).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Color(0xFF2B6C67),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Export Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8ECEF)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6C67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download_outlined,
                  color: Color(0xFF2B6C67),
                  size: 20,
                ),
              ),
              title: const Text(
                'Export as JSON',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleExport('json');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              title: const Text(
                'Export as CSV',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleExport('csv');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              title: const Text(
                'Generate PDF Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleExport('pdf');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              title: const Text(
                'View Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF2B6C67)),
              ),
              SizedBox(width: 20),
              Text(
                'Generating report...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
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