import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart package
import 'utils.dart';
import 'edit_journal.dart';

class JournalDetailsPage extends StatelessWidget {
  final String journalId;

  JournalDetailsPage({required this.journalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to the edit page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditJournalPage(journalId: journalId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // Show a confirmation dialog before deleting
              bool confirmDelete = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Journal'),
                  content:
                      Text('Are you sure you want to delete this journal?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmDelete) {
                // Delete the journal entry
                await DatabaseService().deleteJournal(journalId);
                Navigator.pop(context); // Go back to the previous page
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<Journal?>(
        future: DatabaseService().getJournalById(journalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Journal not found'));
          } else {
            Journal journal = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    journal.entryDate.toDate().toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    journal.content,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Media Attachment:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (journal.imageUrl != null && journal.imageUrl!.isNotEmpty)
                    Image.memory(
                      base64Decode(journal.imageUrl!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                  SizedBox(height: 16),
                  if (journal.emotions != null && journal.emotions!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emotion Analysis:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 1, // Maximum score is 1.0 (100%)
                              barGroups: journal.emotions!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final emotion = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: emotion.probability,
                                      color: Colors.blue,
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value < 0 ||
                                          value >= journal.emotions!.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          journal
                                              .emotions![value.toInt()].emotion,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${(value * 100).toInt()}%',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      );
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 0.2,
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: const Border(
                                  left: BorderSide(),
                                  bottom: BorderSide(),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  tooltipBgColor: Colors.blueAccent,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    String emotion = journal
                                        .emotions![group.x.toInt()].emotion;
                                    return BarTooltipItem(
                                      '$emotion\n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              '${(rod.toY * 100).toStringAsFixed(2)}%',
                                          style: const TextStyle(
                                            color: Colors.yellow,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (journal.sentiment != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24),
                        Text(
                          'Sentiment Analysis:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color:
                                  getSentimentColor(journal.sentiment!.label),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sentiment: ${journal.sentiment!.label}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (journal.sentiment!.compound + 1) /
                              2, // Normalize compound score to [0, 1]
                          backgroundColor: Colors.grey[300],
                          color: getSentimentColor(journal.sentiment!.label),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Polarity Score: ${journal.sentiment!.compound}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
