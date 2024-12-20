import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_fyp/admin_pages/emotionController.dart';
import 'package:intl/intl.dart';

class EmotionChart extends StatefulWidget {
  const EmotionChart({super.key});

  @override
  State<EmotionChart> createState() => _EmotionChartState();
}

class _EmotionChartState extends State<EmotionChart> {
  final EmotionController _emotionController = EmotionController();
  Map<String, Map<String, int>> emotionFrequencies = {};
  Map<String, Map<String, int>> filteredEmotionFrequencies = {};
  bool isLoading = true;
  String selectedRange = 'Weekly'; // Default range

  @override
  void initState() {
    super.initState();
    loadEmotionFrequencies();
  }

  Future<void> loadEmotionFrequencies() async {
    try {
      var data = await _emotionController.fetchEmotionFrequencies();
      setState(() {
        emotionFrequencies = data;
        filterDataByRange();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading emotion frequencies: $e');
    }
  }

  // Filter data based on selected range
  void filterDataByRange() {
    DateTime today = DateTime.now();

    // Normalize today to end of day
    today = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // Initialize startDate with a default value
    DateTime startDate = today;
    List<DateTime> intervalDates = [];

    if (selectedRange == 'Weekly') {
      startDate = today.subtract(const Duration(days: 7));
      intervalDates = List.generate(
          8, (index) => today.subtract(Duration(days: 7 - index)));
    } else if (selectedRange == 'Monthly') {
      startDate = DateTime(today.year, today.month - 1, today.day);
      intervalDates = List.generate(
          ((today.difference(startDate).inDays) / 14).ceil() + 1,
          (index) =>
              startDate.add(Duration(days: index * 14 + (index % 2 * 7))));

      if (intervalDates.last != today) {
        intervalDates.add(today);
      }
    } else if (selectedRange == 'Yearly') {
      startDate = DateTime(today.year - 1, today.month, today.day);
      intervalDates = [];

      for (int year = startDate.year; year <= today.year; year++) {
        int startMonth = (year == startDate.year) ? startDate.month : 1;
        int endMonth = (year == today.year) ? today.month : 12;

        for (int month = startMonth; month <= endMonth; month++) {
          DateTime firstOfMonth = DateTime(year, month, 1);
          DateTime lastOfMonth = DateTime(year, month + 1, 0);

          List<int> intervalOffsets = [5, 20, 35];

          for (int offset in intervalOffsets) {
            DateTime intervalPoint = firstOfMonth.add(Duration(days: offset));

            if (intervalPoint.isBefore(lastOfMonth) ||
                intervalPoint.isAtSameMomentAs(lastOfMonth)) {
              intervalDates.add(intervalPoint);
            }
          }
        }
      }

      intervalDates = intervalDates.toSet().toList();
      intervalDates.sort();

      if (intervalDates.last != today) {
        intervalDates.add(today);
      }
    }

    setState(() {
      filteredEmotionFrequencies = {};
      for (var intervalDate in intervalDates) {
        String formattedDate = DateFormat('yyyy-MM-dd').format(intervalDate);
        filteredEmotionFrequencies[formattedDate] =
            emotionFrequencies[formattedDate] ?? {};
      }

      emotionFrequencies.forEach((date, emotionMap) {
        DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date);

        if ((dateTime.isAfter(startDate.subtract(const Duration(days: 1))) ||
                dateTime.isAtSameMomentAs(startDate)) &&
            (dateTime.isBefore(today.add(const Duration(days: 1))) ||
                dateTime.isAtSameMomentAs(today))) {
          filteredEmotionFrequencies[date] = emotionMap;
        }
      });
    });
  }

  Widget dateBottomTitle(double value, TitleMeta meta) {
    int index = value.toInt();
    List<String> sortedDates = filteredEmotionFrequencies.keys.toList();
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    if (!sortedDates.contains(todayString)) {
      sortedDates.add(todayString);
    }

    sortedDates.sort((a, b) => DateFormat('yyyy-MM-dd')
        .parse(a)
        .compareTo(DateFormat('yyyy-MM-dd').parse(b)));

    if (index >= 0 && index < sortedDates.length) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(sortedDates[index]);
      String formattedDate = DateFormat('d/M').format(date);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          formattedDate,
          style: const TextStyle(fontSize: 10),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Frequencies'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton2<String>(
                    value: selectedRange,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedRange = newValue!;
                        filterDataByRange();
                      });
                    },
                    items: ['Weekly', 'Monthly']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      children: getEmotionFrequencyCharts(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> getEmotionFrequencyCharts() {
    List<Widget> charts = [];
    Set<String> emotions = <String>{};

    for (var emotionMap in filteredEmotionFrequencies.values) {
      emotions.addAll(emotionMap.keys);
    }

    for (var emotion in emotions) {
      charts.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  emotion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: SizedBox(
                  height: 300,
                  width: 350,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: getSpotsForEmotion(emotion),
                          color: Colors.blue,
                          barWidth: 6,
                          isCurved: false,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text('Frequency'),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}');
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text('Date'),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: getIntervalForRange(selectedRange),
                            getTitlesWidget: dateBottomTitle,
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(width: 1, color: Colors.black),
                          bottom: BorderSide(width: 1, color: Colors.black),
                          right: BorderSide(width: 1, color: Colors.black),
                          top: BorderSide(width: 1, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return charts;
  }

  double getIntervalForRange(String range) {
    double interval = 1.0;

    if (range == 'Weekly') {
      interval = 1;
    } else if (range == 'Monthly') {
      interval = 5;
    } else if (range == 'Yearly') {
      interval = 7;
    }

    return interval;
  }

  List<FlSpot> getSpotsForEmotion(String emotion) {
    List<FlSpot> spots = [];
    List<String> sortedDates = filteredEmotionFrequencies.keys.toList();
    sortedDates.sort((a, b) => DateFormat('yyyy-MM-dd')
        .parse(a)
        .compareTo(DateFormat('yyyy-MM-dd').parse(b)));

    DateTime today = DateTime.now();

    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date);

      if (dateTime.isAfter(today)) {
        continue;
      }

      int frequency = filteredEmotionFrequencies[date]?[emotion] ?? 0;
      spots.add(FlSpot(i.toDouble(), frequency.toDouble()));
    }

    return spots;
  }

  void showEmotionDetailsDialog(
      String date, int frequency, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emotion Details for $date'),
          content: Text('Frequency: $frequency'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
