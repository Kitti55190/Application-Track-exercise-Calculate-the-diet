import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:new_project/config/app_config.dart';


class ExerciseScreen extends StatelessWidget {
  final String userId;

  final Color primaryGreen = Color(0xFF4CAF50);
  final Color secondaryGreen = Color(0xFF81C784);
  final Color backgroundColor = Color(0xFFF5F9F5);

  ExerciseScreen({required this.userId}) {
    initializeDateFormatting('th');
  }

  Future<List<Map<String, dynamic>>> fetchExercises() async {
    try {
      final url = AppConfig.getUserExercisesUrl(userId);
      print('Fetching exercises from: $url');
      
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final Map<String, Map<String, dynamic>> dailyExercises = {};

        for (var exercise in data) {
          final dateTime = DateTime.parse(exercise['dateTime']).toLocal();
          final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);

          if (!dailyExercises.containsKey(dateKey)) {
            dailyExercises[dateKey] = {
              'name': 'หลายกิจกรรม',
              'calories': 0,
              'duration': 0,
              'steps': 0,
              'distance': 0.0,
              'dateTime': dateTime.toIso8601String(),
              'activities': <Map<String, dynamic>>[]
            };
          }

          final dailyExercise = dailyExercises[dateKey]!;

          dailyExercise['calories'] += exercise['calories'] ?? 0;
          dailyExercise['duration'] += exercise['duration'] ?? 0;
          dailyExercise['steps'] += exercise['steps'] ?? 0;
          dailyExercise['distance'] += (exercise['distance'] ?? 0.0);

          if (dailyExercise['activities'].isEmpty && (exercise['name']?.toString() ?? '').isNotEmpty) {
            dailyExercise['name'] = exercise['name'];
          } else if (dailyExercise['activities'].length > 1) {
            dailyExercise['name'] = 'หลายกิจกรรม';
          }

          dailyExercise['activities'].add({
            'name': exercise['name'] ?? 'ไม่ระบุกิจกรรม',
            'calories': exercise['calories'] ?? 0,
            'duration': exercise['duration'] ?? 0,
            'steps': exercise['steps'] ?? 0,
            'distance': exercise['distance'] ?? 0.0,
          });
        }

        final sortedExercises = dailyExercises.values.toList()
          ..sort((a, b) => DateTime.parse(b['dateTime']).compareTo(DateTime.parse(a['dateTime'])));

        return sortedExercises;
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      throw Exception('Failed to load exercises: $e');
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'ไม่ระบุเวลา';

    try {
      final date = DateTime.parse(dateStr).toLocal();
      final thaiDateFormat = DateFormat('d MMMM yyyy', 'th');
      return thaiDateFormat.format(date);
    } catch (e) {
      return 'ไม่ระบุเวลา';
    }
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('หลายกิจกรรม')) {
      return Icons.sports;
    } else if (name.contains('วิ่ง') || name.contains('run')) {
      return Icons.directions_run;
    } else if (name.contains('จักรยาน') || name.contains('bike')) {
      return Icons.directions_bike;
    } else if (name.contains('เดิน') || name.contains('walk')) {
      return Icons.directions_walk;
    }
    return Icons.fitness_center;
  }

  Widget _buildActivityDetails(Map<String, dynamic> activity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getExerciseIcon(activity['name']),
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(
            activity['name'],
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Spacer(),
          Text(
            '${activity['duration']} นาที',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(width: 16),
          Text(
            '${activity['calories']} แคล',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        title: Text(
          'ประวัติการออกกำลังกาย',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    color: secondaryGreen,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีรายการออกกำลังกาย',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final activities = List<Map<String, dynamic>>.from(exercise['activities'] ?? []);

              return GestureDetector(
                onTap: () {
                  print('Exercise tapped: ${exercise['name']}');
                  Navigator.pop(context, {
                    'name': exercise['name'],
                    'calories': exercise['calories'],
                    'duration': exercise['duration'],
                    'dateTime': exercise['dateTime'],
                    'steps': exercise['steps'],
                    'distance': exercise['distance']
                  });
                },
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: secondaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getExerciseIcon(exercise['name']),
                                color: primaryGreen,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDate(exercise['dateTime']),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    exercise['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              Icons.timer,
                              '${exercise['duration']}',
                              'นาที',
                            ),
                            _buildStatItem(
                              Icons.local_fire_department,
                              '${exercise['calories']}',
                              'แคล',
                              color: Colors.orange,
                            ),
                            if (exercise['steps'] > 0)
                              _buildStatItem(
                                Icons.directions_walk,
                                '${exercise['steps']}',
                                'ก้าว',
                              ),
                            if (exercise['distance'] > 0)
                              _buildStatItem(
                                Icons.straighten,
                                '${exercise['distance'].toStringAsFixed(2)}',
                                'กม.',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? Colors.grey[600]),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesDetail(List<Map<String, dynamic>> activities) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายละเอียดกิจกรรม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Divider(),
          ...activities.map((activity) => _buildActivityDetails(activity)),
        ],
      ),
    );
  }
}
