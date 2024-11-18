import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_project/config/app_config.dart';


enum MealCategory { healthySalad, lowCalorie, highProtein }

String getCategoryDisplayName(MealCategory category) {
  switch (category) {
    case MealCategory.healthySalad:
      return 'สลัดเพื่อสุขภาพ';
    case MealCategory.lowCalorie:
      return 'อาหารแคลอรี่ต่ำ';
    case MealCategory.highProtein:
      return 'โปรตีนสูง';
    default:
      return 'ไม่ทราบหมวดหมู่';
  }
}

MealCategory? getCategoryFromString(String category) {
  switch (category) {
    case 'สลัดเพื่อสุขภาพ':
      return MealCategory.healthySalad;
    case 'อาหารแคลอรี่ต่ำ':
      return MealCategory.lowCalorie;
    case 'โปรตีนสูง':
      return MealCategory.highProtein;
    default:
      return null;
  }
}

class HealthyFoodScreen extends StatefulWidget {
  @override
  _HealthyFoodScreenState createState() => _HealthyFoodScreenState();
}

class _HealthyFoodScreenState extends State<HealthyFoodScreen> {
  late Future<List<Map<String, dynamic>>> futureMeals;

  @override
  void initState() {
    super.initState();
    futureMeals = fetchMealsFromMongo();
  }

  Future<List<Map<String, dynamic>>> fetchMealsFromMongo() async {
    final response = await http.get(Uri.parse(AppConfig.mealsUrl));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load meals');
    }
  }

  Future<void> _addMealToMongo(Map<String, dynamic> meal) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.addMealUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(meal),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกเมนูสำเร็จ'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          futureMeals = fetchMealsFromMongo();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteMeal(String id) async {
    try {
      final response = await http.delete(Uri.parse(AppConfig.getMealUrl(id)));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบเมนูสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          futureMeals = fetchMealsFromMongo();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateMealInMongo(String id, Map<String, dynamic> updatedMeal) async {
    try {
      final response = await http.put(
        Uri.parse(AppConfig.getMealUrl(id)),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedMeal),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตเมนูสำเร็จ'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          futureMeals = fetchMealsFromMongo();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปเดต'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddMealDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    MealCategory? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เพิ่มเมนูอาหารใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'ชื่อเมนูอาหาร'),
                ),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(labelText: 'จำนวนแคลอรี่'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: proteinController,
                  decoration: InputDecoration(labelText: 'จำนวนโปรตีน (g)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: fatController,
                  decoration: InputDecoration(labelText: 'จำนวนไขมัน (g)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<MealCategory>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'เลือกหมวดหมู่'),
                  items: MealCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(getCategoryDisplayName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('เพิ่มเมนู'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    caloriesController.text.isNotEmpty &&
                    proteinController.text.isNotEmpty &&
                    fatController.text.isNotEmpty &&
                    selectedCategory != null) {
                  final newMeal = {
                    'name': nameController.text,
                    'calories': int.parse(caloriesController.text),
                    'protein': int.parse(proteinController.text),
                    'fat': int.parse(fatController.text),
                    'category': getCategoryDisplayName(selectedCategory!),
                  };
                  _addMealToMongo(newMeal);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditMealDialog(BuildContext context, Map<String, dynamic> meal) {
    final nameController = TextEditingController(text: meal['name']);
    final caloriesController = TextEditingController(text: meal['calories'].toString());
    final proteinController = TextEditingController(text: meal['protein'].toString());
    final fatController = TextEditingController(text: meal['fat'].toString());
    MealCategory? selectedCategory = getCategoryFromString(meal['category']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แก้ไขเมนูอาหาร'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'ชื่อเมนูอาหาร'),
                ),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(labelText: 'จำนวนแคลอรี่'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: proteinController,
                  decoration: InputDecoration(labelText: 'จำนวนโปรตีน (g)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: fatController,
                  decoration: InputDecoration(labelText: 'จำนวนไขมัน (g)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<MealCategory>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'เลือกหมวดหมู่'),
                  items: MealCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(getCategoryDisplayName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('บันทึก'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    caloriesController.text.isNotEmpty &&
                    proteinController.text.isNotEmpty &&
                    fatController.text.isNotEmpty &&
                    selectedCategory != null) {
                  final updatedMeal = {
                    'name': nameController.text,
                    'calories': int.parse(caloriesController.text),
                    'protein': int.parse(proteinController.text),
                    'fat': int.parse(fatController.text),
                    'category': getCategoryDisplayName(selectedCategory!),
                  };
                  _updateMealInMongo(meal['_id'], updatedMeal);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เมนูอาหารเพื่อสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureMeals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!)));
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            final meals = snapshot.data!;
            final categorizedMeals = _categorizeMeals(meals);
            return ListView.builder(
              itemCount: categorizedMeals.length,
              itemBuilder: (context, index) {
                final category = categorizedMeals.keys.elementAt(index);
                final categoryMeals = categorizedMeals[category]!;
                return _buildCategorySection(category, categoryMeals);
              },
            );
          } else {
            return Center(child: Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey)));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  Map<MealCategory, List<Map<String, dynamic>>> _categorizeMeals(List<Map<String, dynamic>> meals) {
    final categorizedMeals = <MealCategory, List<Map<String, dynamic>>>{};
    for (final meal in meals) {
      final category = getCategoryFromString(meal['category'] as String? ?? 'ไม่ระบุ') ?? MealCategory.healthySalad;
      if (!categorizedMeals.containsKey(category)) {
        categorizedMeals[category] = [];
      }
      categorizedMeals[category]!.add(meal);
    }
    return categorizedMeals;
  }

  Widget _buildCategorySection(MealCategory category, List<Map<String, dynamic>> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            getCategoryDisplayName(category),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getCategoryColor(category)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(category).withOpacity(0.2),
                  child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                ),
                title: Text(meal['name'] as String? ?? 'ไม่มีชื่อ', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แคลอรี่: ${meal['calories']?.toString() ?? 'ไม่ระบุ'} kcal', style: TextStyle(color: Colors.orange)),
                    Text('โปรตีน: ${meal['protein']?.toString() ?? 'ไม่ระบุ'} g', style: TextStyle(color: Colors.yellow[800])),
                    Text('ไขมัน: ${meal['fat']?.toString() ?? 'ไม่ระบุ'} g', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditMealDialog(context, meal);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteMeal(meal['_id']);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(meal);
                },
              ),
            );
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  IconData _getCategoryIcon(MealCategory category) {
    switch (category) {
      case MealCategory.healthySalad:
        return Icons.eco;
      case MealCategory.lowCalorie:
        return Icons.fitness_center;
      case MealCategory.highProtein:
        return Icons.egg_alt;
      default:
        return Icons.food_bank;
    }
  }

  Color _getCategoryColor(MealCategory category) {
    switch (category) {
      case MealCategory.healthySalad:
        return Colors.green;
      case MealCategory.lowCalorie:
        return Colors.orange;
      case MealCategory.highProtein:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
