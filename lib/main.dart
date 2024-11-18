import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'food_calc_screen.dart';
import 'home_screen.dart';
import 'new_map_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'survey_screen.dart';
import 'register_result_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Thai locale data
  await initializeDateFormatting('th_TH', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // ปิด debug banner
      title: 'Running App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Kanit', // ถ้าคุณใช้ font Kanit
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: Colors.greenAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          elevation: 0,
        ),
      ),
      locale: const Locale('th', 'TH'),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterResultScreen(),
        '/survey': (context) => SurveyScreen(),
        '/home': (context) => MainScreen(userId: 'your-user-id-here'),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final Color primaryGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(userId: widget.userId),
      NewMapScreen(userId: widget.userId),
      FoodCalcScreen(userId: widget.userId),
      SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          onTap: _onItemTapped,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'หน้าหลัก'),
            _buildNavItem(Icons.map_outlined, Icons.map, 'แผนที่'),
            _buildNavItem(Icons.restaurant_outlined, Icons.restaurant, 'คำนวณอาหาร'),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'ตั้งค่า'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(outlinedIcon),
      activeIcon: Icon(filledIcon),
      label: label,
    );
  }
}