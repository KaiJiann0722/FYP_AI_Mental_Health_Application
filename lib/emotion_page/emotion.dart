import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emotion.dart';
import '../models/journal_model.dart'; // Import the JournalModel
import '../journal_pages/utils.dart';
import 'package:intl/intl.dart';
import 'utils_emotion.dart';

class EmotionChartPage extends StatefulWidget {
  @override
  _EmotionChartPageState createState() => _EmotionChartPageState();
}

class _EmotionChartPageState extends State<EmotionChartPage> {
  late Future<Map<String, dynamic>> _emotionData;
  int touchIndex = -1;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _emotionData = _fetchEmotionData(userId);
    } else {
      _emotionData = Future.value({
        'emotions': [],
        'sentiments': [],
        'dates': [],
        'counts': {'week': {}, 'month': {}, 'year': {}},
      });
    }
  }

  Future<Map<String, dynamic>> _fetchEmotionData(String userId) async {
    final databaseService = DatabaseService();
    return await databaseService.getAllEmotionsAndSentiments(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _emotionData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold();
        }
        if (snapshot.hasError) {
          return _buildErrorScaffold(snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyScaffold();
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Emotion Insights',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Chart', icon: Icon(Icons.show_chart)),
                  Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                EmotionChart(
                  emotions: snapshot.data!['emotions'],
                  sentimentData:
                      (snapshot.data!['sentiments'] as List<Sentiment>?)
                              ?.map((s) => s.compound)
                              .toList() ??
                          [],
                  dates: (snapshot.data!['dates'] as List?)
                          ?.map((date) => date as DateTime)
                          .toList() ??
                      [],
                ),
                EmotionStatistics(
                  weekCounts: snapshot.data!['counts']['week'],
                  monthCounts: snapshot.data!['counts']['month'],
                  yearCounts: snapshot.data!['counts']['year'],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Insights')),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold(dynamic error) {
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Insights')),
      body: Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Insights')),
      body: Center(child: Text('No data available')),
    );
  }
}

class EmotionStatistics extends StatelessWidget {
  final Map<String, int> weekCounts;
  final Map<String, int> monthCounts;
  final Map<String, int> yearCounts;

  const EmotionStatistics({
    Key? key,
    required this.weekCounts,
    required this.monthCounts,
    required this.yearCounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Week'),
              Tab(text: 'Month'),
              Tab(text: 'Year'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmotionGrid(weekCounts),
                _buildEmotionGrid(monthCounts),
                _buildEmotionGrid(yearCounts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionGrid(Map<String, int> counts) {
    var sortedEmotions = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sortedEmotions.length,
        itemBuilder: (context, index) {
          final emotion = sortedEmotions[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emotionToEmoji[emotion.key.toLowerCase()] ?? '🤔',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  emotion.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${emotion.value} Times',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EmotionChart extends StatelessWidget {
  final List<Emotion> emotions;
  final List<double> sentimentData;
  final List<DateTime> dates;

  EmotionChart({
    required this.emotions,
    required this.sentimentData,
    required this.dates,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSentimentSummary(),
            const SizedBox(height: 16),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SentimentLineChart(
                    sentimentData: sentimentData, dates: dates),
              ),
            ),
            const SizedBox(height: 16),
            _buildEmotionBreakdown(),
            const SizedBox(height: 16),
            _buildSentimentCount(),
            const SizedBox(height: 16),
            JournalEntriesTimelineChart(dates: dates),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentSummary() {
    final averageSentiment = _calculateAverageSentiment();
    String summaryText = _getSentimentDescription(averageSentiment);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sentiment Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            summaryText,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown() {
    // Group and count emotions
    Map<String, int> emotionCounts = {};

    for (var emotion in emotions) {
      emotionCounts[emotion.emotion] =
          (emotionCounts[emotion.emotion] ?? 0) + 1;
    }

    // Sort by count and take the top 6
    var sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topEmotions = sortedEmotions.take(8).toList();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotion Distribution (Top 8)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildBarChart(topEmotions),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, int>> sortedEmotions) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: sortedEmotions.isNotEmpty
              ? sortedEmotions.first.value.toDouble()
              : 1.0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final emotionName = sortedEmotions[group.x.toInt()].key;
                return BarTooltipItem(
                  '$emotionName\n Count: ${rod.toY.toInt()}',
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedEmotions.length) {
                    return Container();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 2,
                    child: Text(
                      emotionToEmoji[sortedEmotions[index].key] ?? '🤔',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4, // Add some space to align the text correctly
                    child: Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 10),
                      textAlign: TextAlign.center, // Center align the text
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          barGroups: sortedEmotions.asMap().entries.map((entry) {
            final index = entry.key;
            final emotion = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: emotion.value.toDouble(),
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildSentimentIcon(SentimentLevel sentimentLevel) {
    return Icon(
      sentimentIcons[sentimentLevel],
      color: sentimentColors[sentimentLevel],
      size: 30,
    );
  }

  Map<SentimentLevel, int> _calculateSentimentCounts() {
    Map<SentimentLevel, int> sentimentCounts = {
      SentimentLevel.superPositive: 0,
      SentimentLevel.positive: 0,
      SentimentLevel.neutral: 0,
      SentimentLevel.negative: 0,
      SentimentLevel.superNegative: 0,
    };

    for (var sentiment in sentimentData) {
      SentimentLevel level = getSentimentLevel(sentiment);
      sentimentCounts[level] = (sentimentCounts[level] ?? 0) + 1;
    }

    return sentimentCounts;
  }

  Widget _buildSentimentCount() {
    Map<SentimentLevel, int> sentimentCounts = _calculateSentimentCounts();
    int totalSentiments =
        sentimentCounts.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentiment Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sentimentCounts.entries.map((entry) {
                    final double percentage =
                        (entry.value / totalSentiments) * 100;
                    return PieChartSectionData(
                      color: sentimentColors[entry.key],
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 16),
            ...sentimentCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      sentimentIcons[entry.key],
                      color: sentimentColors[entry.key],
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      entry.key.toString().split('.').last,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  double _calculateAverageSentiment() {
    return sentimentData.reduce((a, b) => a + b) / sentimentData.length;
  }

  String _getSentimentDescription(double averageSentiment) {
    if (averageSentiment > 0.7)
      return 'You are experiencing extremely positive emotions!';
    if (averageSentiment > 0.2)
      return 'Your sentiment is predominantly positive.';
    if (averageSentiment > -0.2) return 'You have a balanced emotional state.';
    if (averageSentiment > -0.7)
      return 'Your sentiment is leaning towards negative.';
    return 'You are experiencing challenging emotions right now.';
  }
}

class SentimentLineChart extends StatelessWidget {
  final List<double> sentimentData;
  final List<DateTime> dates;

  const SentimentLineChart({
    Key? key,
    required this.sentimentData,
    required this.dates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: LineChart(
          _mainData(),
        ),
      ),
    );
  }

  LineChartData _mainData() {
    return LineChartData(
      // Grid Configuration
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),

      // Titles Configuration
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

        // Bottom Titles (X-Axis)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),

        // Left Titles (Y-Axis)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),

      // Border Configuration
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),

      // Minimum and Maximum Values
      minX: 0,
      maxX: (_getLastSevenDaysData().length - 1).toDouble(),
      minY: _getMinY(),
      maxY: _getMaxY(),

      // Line Configuration
      lineBarsData: [
        LineChartBarData(
          spots: _generateSpots(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue.shade400,
              Colors.blue.shade600,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                  radius: 6,
                  color: _getDotColor(spot.y),
                  strokeWidth: 2,
                  strokeColor: Colors.white);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.lightBlue.shade200.withOpacity(0.4),
                Colors.lightBlue.shade400.withOpacity(0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  List<MapEntry<DateTime, double>> _getLastSevenDaysData() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 31));

    // Group sentiments by date
    Map<String, List<double>> dailyData = {};

    for (int i = 0; i < dates.length && i < sentimentData.length; i++) {
      if (dates[i].isAfter(sevenDaysAgo)) {
        // Format date as string key without time
        String dateKey = DateFormat('yyyy-MM-dd').format(dates[i]);
        dailyData.putIfAbsent(dateKey, () => []);
        dailyData[dateKey]!.add(sentimentData[i]);
      }
    }

    // Calculate average for each day
    Map<DateTime, double> averagedData = dailyData.map((key, value) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(key);
      double avgSentiment = value.reduce((a, b) => a + b) / value.length;
      return MapEntry(date, avgSentiment);
    });

    // Sort dates
    List<DateTime> sortedDates = averagedData.keys.toList()..sort();

    // Get the last seven dates
    List<DateTime> lastSevenDates = sortedDates.length > 7
        ? sortedDates.sublist(sortedDates.length - 7)
        : sortedDates;

    // Retrieve the averaged data for the last seven dates
    List<MapEntry<DateTime, double>> lastSevenData = lastSevenDates.map((date) {
      return MapEntry(date, averagedData[date]!);
    }).toList();

    return lastSevenData;
  }

  // Update spot generation for filtered data
  List<FlSpot> _generateSpots() {
    final weekData = _getLastSevenDaysData();
    return List.generate(weekData.length,
        (i) => FlSpot(i.toDouble(), _normalizeSentiment(weekData[i].value)));
  }

  // Normalize sentiment to a consistent scale
  double _normalizeSentiment(double sentiment) {
    if (sentiment > 0.7) return 5; // Super Positive
    if (sentiment > 0.2) return 4; // Positive
    if (sentiment > -0.2) return 3; // Neutral
    if (sentiment > -0.7) return 2; // Negative
    return 1; // Super Negative
  }

  // Get dot color based on sentiment value
  Color _getDotColor(double value) {
    switch (value.toInt()) {
      case 5:
        return Colors.green; // Super Positive
      case 4:
        return Colors.lightGreen; // Positive
      case 3:
        return Colors.grey; // Neutral
      case 2:
        return Colors.orange; // Negative
      case 1:
        return Colors.red; // Super Negative
      default:
        return Colors.blue;
    }
  }

  // Dynamic Y-axis minimum
  double _getMinY() {
    return -0.0; // Slight padding below the lowest point
  }

  // Dynamic Y-axis maximum
  double _getMaxY() {
    return 6.0; // Slight padding above the highest point
  }

  // Bottom X-axis titles
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    final weekData = _getLastSevenDaysData();
    if (value.toInt() >= weekData.length) return Container();

    final date = weekData[value.toInt()].key;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        DateFormat('MM/dd').format(date),
        style: style,
      ),
    );
  }

  // Left Y-axis titles
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 9,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = 'Super Negative';
        break;
      case 2:
        text = 'Negative';
        break;
      case 3:
        text = 'Neutral';
        break;
      case 4:
        text = 'Positive';
        break;
      case 5:
        text = 'Super Positive';
        break;
      default:
        return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }
}

class JournalEntriesTimelineChart extends StatelessWidget {
  final List<DateTime> dates;

  const JournalEntriesTimelineChart({Key? key, required this.dates})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journal Entries Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.70,
              child: LineChart(
                _generateLineChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _generateLineChartData() {
    // Group entries by date
    Map<DateTime, int> entryCountByDate = {};
    for (var date in dates) {
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      entryCountByDate[normalizedDate] =
          (entryCountByDate[normalizedDate] ?? 0) + 1;
    }

    // Sort and convert to FlSpot
    List<DateTime> sortedDates = entryCountByDate.keys.toList()..sort();
    List<DateTime> lastSevenDates = sortedDates.length > 7
        ? sortedDates.sublist(sortedDates.length - 7)
        : sortedDates;

    double maxY = lastSevenDates.isNotEmpty
        ? lastSevenDates
            .map((date) => entryCountByDate[date]!)
            .reduce((a, b) => a > b ? a : b)
            .toDouble()
        : 1.0;

    List<FlSpot> spots = lastSevenDates.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), entryCountByDate[entry.value]!.toDouble());
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < lastSevenDates.length) {
                final date = lastSevenDates[value.toInt()];
                return Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }
              return Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: (lastSevenDates.length - 1).toDouble(),
      minY: 0,
      maxY: maxY + 1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue.shade400,
              Colors.blue.shade600,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.lightBlue.shade200.withOpacity(0.4),
                Colors.lightBlue.shade400.withOpacity(0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
