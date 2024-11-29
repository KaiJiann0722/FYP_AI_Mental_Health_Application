import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emotion.dart';
import '../models/journal_model.dart'; // Import the JournalModel
import '../journal_pages/utils.dart';
import 'package:intl/intl.dart';

class EmotionChartPage extends StatefulWidget {
  @override
  _EmotionChartPageState createState() => _EmotionChartPageState();
}

class _EmotionChartPageState extends State<EmotionChartPage> {
  late Future<Map<String, dynamic>> _emotionData;

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
              title: Text('Emotion Insights'),
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
      appBar: AppBar(
        title: Text(
          'Emotion Insights',
        ),
      ),
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
    // Group and average emotions
    Map<String, double> groupedEmotions = {};
    Map<String, int> emotionCounts = {};

    for (var emotion in emotions) {
      groupedEmotions[emotion.emotion] =
          (groupedEmotions[emotion.emotion] ?? 0) + emotion.probability;
      emotionCounts[emotion.emotion] =
          (emotionCounts[emotion.emotion] ?? 0) + 1;
    }

    // Calculate averages
    var averagedEmotions = groupedEmotions
        .map((key, value) => MapEntry(key, value / emotionCounts[key]!));

    // Sort by probability
    var sortedEmotions = averagedEmotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
              'Emotion Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...sortedEmotions.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text(emotionToEmoji[entry.key.toLowerCase()] ?? '🤔'),
                      SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
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

  double _calculateAverageSentiment() {
    return sentimentData.reduce((a, b) => a + b) / sentimentData.length;
  }

  String _getSentimentDescription(double averageSentiment) {
    if (averageSentiment > 0.6)
      return 'You are experiencing extremely positive emotions!';
    if (averageSentiment > 0.2)
      return 'Your sentiment is predominantly positive.';
    if (averageSentiment > -0.2) return 'You have a balanced emotional state.';
    if (averageSentiment > -0.6)
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
      aspectRatio: 1.70,
      child: Padding(
        padding:
            const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
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
    final sevenDaysAgo = now.subtract(Duration(days: 7));

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
    List<MapEntry<DateTime, double>> averagedData =
        dailyData.entries.map((entry) {
      // Parse date from key
      DateTime date = DateFormat('yyyy-MM-dd').parse(entry.key);
      // Calculate average sentiment
      double avgSentiment =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(date, avgSentiment);
    }).toList();

    // Sort by date
    averagedData.sort((a, b) => a.key.compareTo(b.key));
    return averagedData;
  }

  // Update spot generation for filtered data
  List<FlSpot> _generateSpots() {
    final weekData = _getLastSevenDaysData();
    return List.generate(weekData.length,
        (i) => FlSpot(i.toDouble(), _normalizeSentiment(weekData[i].value)));
  }

  // Normalize sentiment to a consistent scale
  double _normalizeSentiment(double sentiment) {
    if (sentiment > 0.6) return 4; // Super Positive
    if (sentiment > 0.2) return 3; // Positive
    if (sentiment > -0.2) return 2; // Neutral
    if (sentiment > -0.6) return 1; // Negative
    return 0; // Super Negative
  }

  // Get dot color based on sentiment value
  Color _getDotColor(double value) {
    switch (value.toInt()) {
      case 4:
        return Colors.green; // Super Positive
      case 3:
        return Colors.lightGreen; // Positive
      case 2:
        return Colors.grey; // Neutral
      case 1:
        return Colors.orange; // Negative
      case 0:
        return Colors.red; // Super Negative
      default:
        return Colors.blue;
    }
  }

  // Dynamic Y-axis minimum
  double _getMinY() {
    return -1.0; // Slight padding below the lowest point
  }

  // Dynamic Y-axis maximum
  double _getMaxY() {
    return 5.0; // Slight padding above the highest point
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
      fontSize: 8,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Super Negative';
        break;
      case 1:
        text = 'Negative';
        break;
      case 2:
        text = 'Neutral';
        break;
      case 3:
        text = 'Positive';
        break;
      case 4:
        text = 'Super Positive';
        break;
      default:
        return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }
}
