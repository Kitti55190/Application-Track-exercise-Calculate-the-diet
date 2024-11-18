import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// กำหนดค่าสีหลักของแอพ
class AppColors {
  static const primary = Color(0xFF1B5E20);  // เขียวเข้ม
  static const primaryLight = Color(0xFFC8E6C9);  // เขียวอ่อน
  static const surface = Color(0xFFE8F5E9);  // พื้นหลังอ่อนๆ
  static const white70 = Colors.white70;
  static const white = Colors.white;
}

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  int _steps = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  int _elapsedTime = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _fetchTodayExercises();
  }

  Future<void> _fetchTodayExercises() async {
    try {
      final today = DateTime.now();
      final url = 'http://192.168.159.195:3000/api/users/${widget.userId}/exercises';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> exercises = json.decode(response.body);
        
        // กรองเฉพาะข้อมูลของวันนี้
        final todayExercises = exercises.where((exercise) {
          final exerciseDate = DateTime.parse(exercise['dateTime']);
          return exerciseDate.year == today.year &&
                 exerciseDate.month == today.month &&
                 exerciseDate.day == today.day;
        }).toList();

        if (todayExercises.isNotEmpty) {
          setState(() {
            _steps = todayExercises.fold<int>(0, (sum, exercise) => 
              sum + (int.parse(exercise['steps']?.toString() ?? '0')));
              
            _distance = todayExercises.fold<double>(0.0, (sum, exercise) => 
              sum + (double.parse(exercise['distance']?.toString() ?? '0.0')));
              
            _calories = todayExercises.fold<double>(0.0, (sum, exercise) => 
              sum + (double.parse(exercise['calories']?.toString() ?? '0.0')));
              
            _elapsedTime = todayExercises.fold<int>(0, (sum, exercise) => 
              sum + (int.parse(exercise['duration']?.toString() ?? '0')));
          });
        }
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึงข้อมูลได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight],
            stops: [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTodayExercises,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: 24),
                            _buildStepsCard(colorScheme),
                            SizedBox(height: 24),
                            _buildSummaryCard(colorScheme),
                            SizedBox(height: 24),
                            _buildInfoSection(screenSize, context, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สวัสดี 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white70,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy', 'th').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: AppColors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "จำนวนก้าววันนี้",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.analytics_outlined),
                  label: Text("สถิติ"),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: 24),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: (_steps / 10000).clamp(0.0, 1.0)),
              duration: Duration(seconds: 2),
              builder: (context, double value, child) {
                return CircularPercentIndicator(
                  radius: 130.0,
                  lineWidth: 15.0,
                  animation: false,
                  percent: value,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat("#,##0").format(_steps),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "ก้าว",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                );
              },
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    "เป้าหมาย: 10,000 ก้าว",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "สรุปการออกกำลังกายวันนี้",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  Icons.timer_outlined,
                  "${_elapsedTime}",
                  "นาที",
                  colorScheme,
                ),
                _buildDivider(),
                _buildSummaryItem(
                  Icons.local_fire_department_outlined,
                  "${_calories.toStringAsFixed(0)}",
                  "แคลอรี่",
                  colorScheme,
                ),
                _buildDivider(),
                _buildSummaryItem(
                  Icons.directions_walk_outlined,
                  "${_distance.toStringAsFixed(2)}",
                  "กิโลเมตร",
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildInfoSection(
    Size screenSize,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "เกร็ดความรู้",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCard(
              'ท่าออกกำลังกายง่ายๆที่บ้าน',
              Icons.fitness_center_outlined,
              screenSize,
              context,
              'exercise',
              AppColors.primary,
            ),
            _buildInfoCard(
              'นอนหลับอย่างมีประสิทธิ์ภาพ',
              Icons.nightlight_outlined,
              screenSize,
              context,
              'sleep',
              AppColors.primary,
            ),
            _buildInfoCard(
              'อาหารเสริม',
              Icons.restaurant_outlined,
              screenSize,
              context,
              'nutrition',
              AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Size screenSize,
    BuildContext context,
    String type,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        String info = "";
        if (type == 'exercise') {
          info = "นี่คือ 10 ท่าออกกำลังกายง่ายๆ ที่คุณสามารถทำได้ที่บ้าน:\n"
              "1. ท่ากระโดดตบ (Jumping Jack)\n"
              "2. ท่าสควอท (Squat)\n"
              "3. ท่าวิดพื้น (Push Up)\n"
              "4. ท่าแพลงก์ (Plank)\n"
              "5. ท่าซิทอัพ (Sit Up)\n"
              "6. ท่าปั่นจักรยานอากาศ (Air Cycling)\n"
              "7. ท่ายกขาค้าง (Legs Up)\n"
              "8. ท่าเก้าอี้ล่องหน (Wall Sit)\n"
              "9. ท่า V-Ups\n"
              "10. ท่า Russian Twist\n"
              "ควรทำวอร์มอัพก่อนออกกำลังกายและคูลดาวน์หลังออกกำลังกายทุกครั้งเพื่อป้องกันการบาดเจ็บ.";
        } else if (type == 'sleep') {
          info = "การนอนหลับอย่างมีประสิทธิภาพเป็นสิ่งสำคัญต่อสุขภาพโดยรวม ต่อไปนี้คือแนวทางที่ช่วยให้นอนหลับได้อย่างมีคุณภาพ:\n"
              "1. ระยะเวลา: นอนหลับ 7-9 ชั่วโมงต่อคืน\n"
              "2. คุณภาพการนอน: มีความต่อเนื่อง ไม่ตื่นระหว่างการนอนหลับ\n"
              "3. วิธีปฏิบัติเพื่อการนอนที่มีคุณภาพ: สร้างบรรยากาศที่เงียบ เย็น และมืด\n"
              "4. หลีกเลี่ยงการใช้อุปกรณ์อิเล็กทรอนิกส์ก่อนนอน\n"
              "5. ผลลัพธ์ของการนอนที่มีคุณภาพ: ร่างกายผ่อนคลาย ไม่ปวดเมื่อย.";
        } else if (type == 'nutrition') {
          info = "อาหารเสริมที่จำเป็นต่อร่างกายมีหลายประเภท โดยแต่ละชนิดมีประโยชน์แตกต่างกัน ดังนี้:\n"
              "1. วิตามินบี: จำเป็นต่อการใช้พลังงานและการทำงานของระบบประสาท\n"
              "2. วิตามินซี: เสริมสร้างระบบภูมิคุ้มกัน\n"
              "3. วิตามินดี: สำคัญต่อสุขภาพกระดูกและระบบภูมิคุ้มกัน\n"
              "4. แคลเซียม: เสริมสร้างความแข็งแรงของกระดูกและฟัน\n"
              "5. ธาตุเหล็กและสังกะสี: จำเป็นต่อการสร้างเม็ดเลือดแดง\n"
              "ข้อควรระวัง: ควรปรึกษาแพทย์หรือผู้เชี่ยวชาญก่อนรับประทานอาหารเสริม.";
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InfoDetailScreen(type: type, info: info)),
        );
      },
      child: Container(
        width: screenSize.width * 0.28,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// InfoDetailScreen class
class InfoDetailScreen extends StatelessWidget {
  final String type;
  final String info;

  InfoDetailScreen({required this.type, required this.info});

  List<Map<String, String>> _parseInfo(String info) {
    final List<String> lines = info.split('\n');
    List<Map<String, String>> items = [];
    String currentTitle = '';
    String currentDescription = '';

    for (String line in lines) {
      if (line.contains(':')) {
        if (currentTitle.isNotEmpty) {
          items.add({
            'title': currentTitle,
            'description': currentDescription.trim(),
          });
        }
        final parts = line.split(':');
        currentTitle = parts[0];
        currentDescription = parts.length > 1 ? parts[1] : '';
      } else if (line.startsWith(RegExp(r'\d+\.'))) {
        if (currentTitle.isNotEmpty) {
          items.add({
            'title': currentTitle,
            'description': currentDescription.trim(),
          });
        }
        final parts = line.split('.');
        currentTitle = parts[1].trim();
        currentDescription = parts.length > 2 ? parts[2].trim() : '';
      } else {
        currentDescription += ' ' + line;
      }
    }
    
    if (currentTitle.isNotEmpty) {
      items.add({
        'title': currentTitle,
        'description': currentDescription.trim(),
      });
    }
    
    return items;
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'exercise':
        return Icons.fitness_center_outlined;
      case 'sleep':
        return Icons.nightlight_outlined;
      case 'nutrition':
        return Icons.restaurant_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getTitle(String type) {
    switch (type) {
      case 'exercise':
        return 'การออกกำลังกาย';
      case 'sleep':
        return 'การนอนหลับ';
      case 'nutrition':
        return 'อาหารเสริม';
      default:
        return type;
    }
  }

  Color _getBackgroundColor(int index) {
    final List<Color> colors = [
      Color(0xFFE8F5E9),  // เขียวอ่อนมาก
      Color(0xFFC8E6C9),  // เขียวอ่อน
      Color(0xFFA5D6A7),  // เขียวปานกลาง
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final items = _parseInfo(info);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getTypeIcon(type), size: 24),
            SizedBox(width: 8),
            Text(
              'รายละเอียด ${_getTitle(type)}',
              style: TextStyle(color: AppColors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildInfoCard(
                  items[index]['title'] ?? '',
                  items[index]['description'] ?? '',
                  index,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBackgroundColor(index),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
