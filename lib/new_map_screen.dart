import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NewMapScreen extends StatefulWidget {
  final String userId;

  const NewMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NewMapScreenState createState() => _NewMapScreenState();
}

class _NewMapScreenState extends State<NewMapScreen> {
  LatLng _currentLocation = LatLng(13.7563, 100.5018);
  late final MapController _mapController;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<StepCount>? _stepCountStreamSubscription;
  bool _isTracking = false;
  int _steps = 0;
  int? _lastStepCount;
  double _distance = 0.0;
  double _calories = 0.0;
  Duration _elapsedTime = Duration();
  Timer? _timer;
  DateTime? _startTime;

  final Color primaryGreen = Color(0xFF2E7D32);
  final Color secondaryGreen = Color(0xFF81C784);
  final Color accentGreen = Color(0xFF00C853);

  String _selectedActivity = 'เดิน';
  final Map<String, double> _caloriesMultiplier = {
    'เดิน': 0.04,
    'ปั่นจักรยาน': 0.03,
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th');
    _mapController = MapController();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await _checkPermissions();
    await _checkSensorAvailability();
    await _initializePositionStream();
  }
  Future<void> _checkPermissions() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == LocationPermission.denied) {
        _showError('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
        return;
      }
    }

    if (await Permission.activityRecognition.isDenied) {
      PermissionStatus status = await Permission.activityRecognition.request();
      if (status.isDenied) {
        _showError('ไม่ได้รับอนุญาตให้เข้าถึงการนับก้าว');
        return;
      }
    }
  }

  Future<void> _checkSensorAvailability() async {
    try {
      StreamSubscription<StepCount> subscription = Pedometer.stepCountStream.listen(
        (_) {},
        onError: (error) {
          print('Pedometer test error: $error');
          _showError('อุปกรณ์ของคุณอาจไม่รองรับการนับก้าว');
        },
      );
      await subscription.cancel();
    } catch (e) {
      print('Sensor availability check error: $e');
      _showError('ไม่สามารถตรวจสอบเซนเซอร์นับก้าวได้');
    }
  }

  Future<void> _initializePositionStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('กรุณาเปิดใช้งาน Location Services');
      return;
    }

    setState(() {
      _isLoading = false;
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        if (_isTracking && mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _mapController.move(_currentLocation, _mapController.zoom);
          });
        }
      },
      onError: (error) {
        print('Position Stream Error: $error');
        _showError('เกิดข้อผิดพลาดในการติดตามตำแหน่ง');
      },
    );
  }

  void _initializeStepCounter() {
    _steps = 0;
    _lastStepCount = null;

    _stepCountStreamSubscription?.cancel();
    _stepCountStreamSubscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        if (_isTracking && mounted) {
          print('Step event received: ${event.steps}');
          setState(() {
            if (_lastStepCount == null) {
              _lastStepCount = event.steps;
              return;
            }
            
            int stepsDiff = event.steps - _lastStepCount!;
            if (stepsDiff > 0) {
              _steps += stepsDiff;
              _distance = _steps * 0.0008;
              _calories = _steps * _caloriesMultiplier[_selectedActivity]!;
              
              print('Steps updated: $_steps, Distance: $_distance, Calories: $_calories');
            }
            _lastStepCount = event.steps;
          });
        }
      },
      onError: (error) {
        print('Step Counter Error: $error');
        _showError('เกิดข้อผิดพลาดในการนับก้าว');
      },
    );
  }
  void _startTracking() {
    print('Starting tracking...');
    _initializeStepCounter();
    setState(() {
      _isTracking = true;
      _steps = 0;
      _distance = 0.0;
      _calories = 0.0;
      _elapsedTime = Duration();
      _lastStepCount = null;
      _startTime = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _stopTracking() async {
    print('Stopping tracking...');
    setState(() {
      _isTracking = false;
      _timer?.cancel();
    });
    await _saveToDatabase();
  }

  Future<void> _saveToDatabase() async {
    try {
      final now = DateTime.now();
      
      final trackingData = {
        'name': _selectedActivity,
        'calories': _calories.round(),
        'duration': _elapsedTime.inMinutes,
        'dateTime': now.toIso8601String(),
        'steps': _steps,
        'distance': _distance,
      };
      
      print('Preparing to save exercise data: ${jsonEncode(trackingData)}');

      final response = await http.post(
        Uri.parse('http://192.168.159.195:3000/api/users/${widget.userId}/exercises'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(trackingData),
      );

      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกข้อมูลการออกกำลังกายสำเร็จ'),
              backgroundColor: primaryGreen,
            ),
          );
        }
      } else {
        throw Exception('Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving exercise data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActivitySelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _selectedActivity == 'เดิน' ? Icons.directions_walk : Icons.directions_bike,
                color: primaryGreen,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'กิจกรรม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          DropdownButton<String>(
            value: _selectedActivity,
            icon: Icon(Icons.arrow_drop_down, color: primaryGreen),
            elevation: 4,
            style: TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            underline: Container(height: 0),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedActivity = newValue;
                  _calories = _steps * _caloriesMultiplier[newValue]!;
                });
              }
            },
            items: ['เดิน', 'ปั่นจักรยาน'].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          onPressed: _isTracking ? null : _startTracking,
          color: accentGreen,
          text: 'เริ่มต้น',
          icon: Icons.play_arrow,
        ),
        _buildControlButton(
          onPressed: _isTracking ? _stopTracking : null,
          color: Colors.red[600]!,
          text: 'หยุด',
          icon: Icons.stop,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'ปิด',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isTracking) {
          await _stopTracking();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'บันทึกการออกกำลังกาย',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryGreen,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryGreen, Colors.white],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildActivitySelector(),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: _currentLocation,
                                zoom: 17.0,
                                minZoom: 5.0,
                                maxZoom: 18.0,
                                interactiveFlags: InteractiveFlag.all,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: ['a', 'b', 'c'],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentLocation,
                                      builder: (ctx) => Icon(
                                        Icons.location_pin,
                                        color: primaryGreen,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactStatItem(
                              Icons.directions_walk,
                              '$_steps',
                              'ก้าว',
                              primaryGreen,
                            ),
                            _buildCompactStatItem(
                              Icons.straighten,
                              '${_distance.toStringAsFixed(2)}',
                              'กม.',
                              secondaryGreen,
                            ),
                            _buildCompactStatItem(
                              Icons.local_fire_department,
                              '${_calories.toStringAsFixed(0)}',
                              'แคล',
                              accentGreen,
                            ),
                            _buildCompactStatItem(
                              Icons.timer,
                              '${_elapsedTime.inMinutes}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                              'นาที',
                              primaryGreen,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20, left: 16, right: 16),
                        child: _buildControlButtons(),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _stepCountStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}