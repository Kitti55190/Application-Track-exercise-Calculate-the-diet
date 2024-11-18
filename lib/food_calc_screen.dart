import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'healthy_food_screen.dart';
import 'exercise_screen.dart';
import 'package:new_project/config/app_config.dart';

class FoodCalcScreen extends StatefulWidget {
  final String userId;

  FoodCalcScreen({required this.userId});

  @override
  _FoodCalcScreenState createState() => _FoodCalcScreenState();
}

class _FoodCalcScreenState extends State<FoodCalcScreen> {
  List<Map<String, dynamic>> selectedFoods = [];
  List<Map<String, dynamic>> selectedExercises = [];
  double totalCalories = 0;
  double totalExerciseCalories = 0;
  double tdee = 0;
  bool isLoading = true;
  late String tdeeUrl;

  @override
  void initState() {
    super.initState();
    tdeeUrl = AppConfig.getUserTdeeUrl(widget.userId);
    loadTdeeFromStorage();
  }

  Future<void> loadTdeeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTdee = prefs.getDouble('tdee_${widget.userId}');
    
    if (storedTdee != null) {
      setState(() {
        tdee = storedTdee;
        isLoading = false;
      });
    } else {
      fetchTdee();
    }
  }

  Future<void> fetchTdee() async {
    try {
      final response = await http.get(Uri.parse(tdeeUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newTdee = data['tdee'].toDouble();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tdee_${widget.userId}', newTdee);
        
        setState(() {
          tdee = newTdee;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  static Future<void> clearTdee(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tdee_$userId');
  }

  @override
  Widget build(BuildContext context) {
    double remainingCalories = tdee - totalCalories + totalExerciseCalories;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _buildMainStatsCard(tdee, remainingCalories),
                    SizedBox(height: 20),
                    _buildSelectedFoodList(),
                    SizedBox(height: 20),
                    _buildSelectedExerciseList(),
                    SizedBox(height: 20),
                    _buildAddFoodButton(remainingCalories),
                    SizedBox(height: 10),
                    _buildAddExerciseButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'บันทึกอาหารและออกกำลังกาย',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black.withOpacity(0.3)),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.green.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCard(double tdee, double remainingCalories) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พลังงานทั้งหมดที่ใช้ต่อวัน (TDEE)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            SizedBox(height: 16),
            Center(
              child: CircularPercentIndicator(
                radius: 100.0,
                lineWidth: 15.0,
                percent: (tdee > 0)
                    ? ((totalCalories - totalExerciseCalories) / tdee).clamp(0.0, 1.0)
                    : 0.0,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(totalCalories - totalExerciseCalories).toStringAsFixed(0)} / ${tdee.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                    Text('kcal', style: TextStyle(fontSize: 18, color: Colors.green[500])),
                  ],
                ),
                progressColor: Colors.green[700],
                backgroundColor: Colors.green[100]!,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1200,
                footer: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'เป้าหมายประจำวัน: ${remainingCalories.toStringAsFixed(0)} kcal ที่เหลือ',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFoodList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายการอาหารที่เลือก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            SizedBox(height: 12),
            selectedFoods.isEmpty
                ? Text('ยังไม่มีรายการอาหารที่เลือก', style: TextStyle(fontSize: 16, color: Colors.grey[600]))
                : Column(
                    children: selectedFoods.map((food) {
                      return ListTile(
                        leading: Icon(Icons.restaurant_menu, color: Colors.green[500]),
                        title: Text(food['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'แคลอรี่: ${food['calories']} | โปรตีน: ${food['protein']} | ไขมัน: ${food['fat']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                          onPressed: () {
                            setState(() {
                              totalCalories -= double.parse(food['calories'].toString());
                              selectedFoods.remove(food);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedExerciseList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายการออกกำลังกายที่เลือก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
            ),
            SizedBox(height: 12),
            selectedExercises.isEmpty
                ? Text(
                    'ยังไม่มีรายการออกกำลังกายที่เลือก', 
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])
                  )
                : Column(
                    children: selectedExercises.map((exercise) {
                      return ListTile(
                        leading: Icon(
                          _getExerciseIcon(exercise['name']), 
                          color: Colors.green[500]
                        ),
                        title: Text(
                          exercise['name'], 
                          style: TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'แคลอรี่ที่เผาผลาญ: ${exercise['calories']} kcal',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              'เวลา: ${exercise['duration']} นาที • ระยะทาง: ${exercise['distance']} กม.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                          onPressed: () {
                            setState(() {
                              totalExerciseCalories -= double.parse(
                                exercise['calories'].toString()
                              );
                              selectedExercises.remove(exercise);
                            });
                          },
                        ),
                        isThreeLine: true,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
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

  Widget _buildAddFoodButton(double remainingCalories) {
    return ElevatedButton(
      onPressed: remainingCalories > 0
          ? () async {
              final selectedFood = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HealthyFoodScreen()),
              );

              if (selectedFood != null) {
                double foodCalories = double.parse(selectedFood['calories'].toString());
                if (foodCalories <= remainingCalories) {
                  setState(() {
                    selectedFoods.add(selectedFood);
                    totalCalories += foodCalories;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('ไม่สามารถเพิ่มอาหารได้เนื่องจากเกินเป้าหมายแคลอรี่ที่เหลือ'),
                  ));
                }
              }
            }
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 24),
            SizedBox(width: 8),
            Text('เลือกอาหารเพิ่ม', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return ElevatedButton(
      onPressed: () async {
        final selectedExercise = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseScreen(userId: widget.userId)
          ),
        );

        if (selectedExercise != null) {
          setState(() {
            selectedExercises.add(selectedExercise);
            totalExerciseCalories += double.parse(
              selectedExercise['calories'].toString()
            );
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 24),
            SizedBox(width: 8),
            Text('เพิ่มการออกกำลังกาย', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        elevation: 4,
      ),
    );
  }
}
