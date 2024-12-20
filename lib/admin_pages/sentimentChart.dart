import 'package:flutter/material.dart';
import 'package:flutter_fyp/admin_pages/sentimentController.dart';
import 'package:fl_chart/fl_chart.dart';

class SentimentChart extends StatefulWidget {
  const SentimentChart({super.key});

  @override
  State<SentimentChart> createState() => _SentimentChartState();
}

class _SentimentChartState extends State<SentimentChart> {
  final SentimentController _adminController = SentimentController();
  bool isLoading = true;
  List<String> userNames = [];
  List<double> userAverageSentiment =
      []; // List to store average sentiment for each user
  Map<String, int> sentimentCounts = {
    'Super Positive': 0,
    'Positive': 0,
    'Neutral': 0,
    'Negative': 0,
    'Super Negative': 0,
  };

  String errorMessage = ''; // For error handling

  @override
  void initState() {
    super.initState();
    _loadUserNames(); // Fetch user names from journals
  }

  // Fetch user names from journals
  Future<void> _loadUserNames() async {
    try {
      // Fetch full names for all users
      List<String> fetchedUserNames =
          await _adminController.fetchUserDetailsForAllJournals();

      setState(() {
        userNames = fetchedUserNames;
        isLoading = false; // Set loading to false once data is fetched
      });

      // After fetching user names, calculate the sentiment for each user
      _loadUserSentimentData();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading user details: $e';
        isLoading = false; // Stop loading in case of error
      });
    }
  }

  // Load sentiment data for each user
  Future<void> _loadUserSentimentData() async {
    try {
      List<double> sentimentScores = [];

      // Fetch user IDs from journals
      List<String> userIds = await _adminController.fetchUserIdsFromJournals();

      // For each userId, fetch sentiment data and calculate average sentiment
      for (String userId in userIds) {
        // Fetch sentiment data for each user using the userId
        Map<String, dynamic> sentimentData =
            await _adminController.fetchSentimentOverview(userId);

        // Calculate average sentiment score for each user
        double averageSentiment = _adminController
            .calculateAverageSentiment(sentimentData['compoundScores']);
        sentimentScores.add(averageSentiment);

        _updateSentimentCategory(averageSentiment);
      }

      setState(() {
        userAverageSentiment =
            sentimentScores; // Update the sentiment scores list
        sentimentCounts = _getSentimentCounts(); // Update sentiment counts
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading sentiment data: $e';
      });
    }
  }

  // Function to return the sentiment category based on value
  String _getSentimentLabel(double value) {
    if (value > 0.6) {
      return 'Super Positive';
    }
    if (value > 0.2) {
      return 'Positive';
    }
    if (value > -0.2) {
      return 'Neutral';
    }
    if (value > -0.6) {
      return 'Negative';
    }
    return 'Super Negative';
  }

  // Count occurrences of each sentiment category
  Map<String, int> _getSentimentCounts() {
    int superPositive = 0;
    int positive = 0;
    int neutral = 0;
    int negative = 0;
    int superNegative = 0;

    for (var sentiment in userAverageSentiment) {
      String label = _getSentimentLabel(sentiment);
      switch (label) {
        case 'Super Positive':
          superPositive++;
          break;
        case 'Positive':
          positive++;
          break;
        case 'Neutral':
          neutral++;
          break;
        case 'Negative':
          negative++;
          break;
        case 'Super Negative':
          superNegative++;
          break;
      }
      print("This is sentiment count: $sentimentCounts");
    }

    return {
      'Super Positive': superPositive,
      'Positive': positive,
      'Neutral': neutral,
      'Negative': negative,
      'Super Negative': superNegative,
    };
  }

  void _updateSentimentCategory(double sentimentValue) {
    if (sentimentValue > 0.6) {
      sentimentCounts['Super Positive'] =
          sentimentCounts['Super Positive']! + 1;
    } else if (sentimentValue > 0.2) {
      sentimentCounts['Positive'] = sentimentCounts['Positive']! + 1;
    } else if (sentimentValue > -0.2) {
      sentimentCounts['Neutral'] = sentimentCounts['Neutral']! + 1;
    } else if (sentimentValue > -0.6) {
      sentimentCounts['Negative'] = sentimentCounts['Negative']! + 1;
    } else {
      sentimentCounts['Super Negative'] =
          sentimentCounts['Super Negative']! + 1;
    }
  }

  // Create PieChartData for the graph
  PieChartData _getPieChartData() {
    int totalUsers = userNames.length;

    return PieChartData(
      sectionsSpace: 0, // No space between pie sections
      centerSpaceRadius: 30, // Smaller hole in the center
      sections: [
        PieChartSectionData(
          value: sentimentCounts['Super Positive']!.toDouble(),
          color: Colors.green,
          radius: 70, // Increased radius for a bigger pie chart
          showTitle: false, // Hide text inside the pie chart
        ),
        PieChartSectionData(
          value: sentimentCounts['Positive']!.toDouble(),
          color: Colors.lightGreen,
          radius: 70, // Increased radius for a bigger pie chart
          showTitle: false, // Hide text inside the pie chart
        ),
        PieChartSectionData(
          value: sentimentCounts['Neutral']!.toDouble(),
          color: Colors.grey,
          radius: 70, // Increased radius for a bigger pie chart
          showTitle: false, // Hide text inside the pie chart
        ),
        PieChartSectionData(
          value: sentimentCounts['Negative']!.toDouble(),
          color: Colors.orange,
          radius: 70, // Increased radius for a bigger pie chart
          showTitle: false, // Hide text inside the pie chart
        ),
        PieChartSectionData(
          value: sentimentCounts['Super Negative']!.toDouble(),
          color: Colors.red,
          radius: 70, // Increased radius for a bigger pie chart
          showTitle: false, // Hide text inside the pie chart
        ),
      ],
    );
  }

// Helper function to generate the label with percentage and count
  String _getPieChartLabel(String label, int count, int totalUsers) {
    double percentage = (count / totalUsers) * 100;
    return '$label\n$count (${percentage.toStringAsFixed(1)}%)';
  }

  // Display color legend below the pie chart
  Widget _buildLegend() {
    int totalUsers = userNames.length;
    return Column(
      children: [
        // First row: Super Positive, Positive
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // First Column
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(_getPieChartLabel('Super Positive',
                        sentimentCounts['Super Positive']!, totalUsers)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.lightGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(_getPieChartLabel(
                        'Positive', sentimentCounts['Positive']!, totalUsers)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 70),
            // Second column: Super Negative and Negative
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(_getPieChartLabel('Super Negative',
                        sentimentCounts['Super Negative']!, totalUsers)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(_getPieChartLabel(
                        'Negative', sentimentCounts['Negative']!, totalUsers)),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Second row: Neutral
        Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 20,
              height: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(_getPieChartLabel(
                'Neutral', sentimentCounts['Neutral']!, totalUsers)),
          ],
        ),
      ],
    );
  }

  // Build the Pie Chart widget
  Widget _buildSentimentGraph() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 30.0, bottom: 20), // Set the top padding
        child: AspectRatio(
          aspectRatio: 1.70, // Ensure proper aspect ratio
          child: PieChart(_getPieChartData()), // Display the pie chart
        ),
      ),
    );
  }

  // Display the user sentiment data
  Widget displayUserSentiment() {
    if (userNames.isEmpty ||
        userAverageSentiment.isEmpty ||
        userNames.length != userAverageSentiment.length) {
      return const Center(
        child: Text('No sentiment data available.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: List.generate(userNames.length, (index) {
          double averageSentiment = userAverageSentiment[index];
          String sentimentDescription =
              _getSentimentDescription(averageSentiment);

          return ListTile(
            title: Text(
              userNames[index],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Sentiment: ${averageSentiment.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  sentimentDescription,
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Add this method to get the sentiment description based on average sentiment
  String _getSentimentDescription(double averageSentiment) {
    if (averageSentiment > 0.6) {
      return 'User has extremely positive emotions!';
    }
    if (averageSentiment > 0.2) {
      return 'User is predominantly positive.';
    }
    if (averageSentiment > -0.2) {
      return 'User has a balanced emotional state.';
    }
    if (averageSentiment > -0.6) {
      return 'User is leaning towards negative.';
    }
    return 'User has challenging emotions right now.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentiment Chart'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SingleChildScrollView(
            // Wrap the content with SingleChildScrollView
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (isLoading) const CircularProgressIndicator(),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!isLoading && errorMessage.isEmpty) ...[
                  _buildSentimentGraph(),
                  _buildLegend(),
                  const SizedBox(height: 16),
                  displayUserSentiment(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
