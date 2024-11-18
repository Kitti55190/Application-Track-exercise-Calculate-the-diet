import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // เพิ่มสำหรับการส่งข้อมูลไปที่ backend
import 'dart:convert'; // สำหรับ encode ข้อมูลเป็น JSON

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool _isMale = false; // เพิ่มเพศสำหรับคำนวณ BMR
  bool _termsAccepted = false;

  // ฟังก์ชันคำนวณ BMI
  double _calculateBMI() {
    final weight = double.parse(_weightController.text);
    final height = double.parse(_heightController.text) / 100; // แปลงเป็นเมตร
    return weight / (height * height); // BMI = น้ำหนัก / ส่วนสูง^2
  }

  // ฟังก์ชันคำนวณ BMR
  double _calculateBMR() {
    final weight = double.parse(_weightController.text);
    final height = double.parse(_heightController.text);
    final age = int.parse(_ageController.text);
    return _isMale 
      ? 88.36 + (13.4 * weight) + (4.8 * height) - (5.7 * age)  // BMR ผู้ชาย
      : 447.6 + (9.2 * weight) + (3.1 * height) - (4.3 * age);  // BMR ผู้หญิง
  }

  // ฟังก์ชันคำนวณ TDEE
  double _calculateTDEE() {
    final bmr = _calculateBMR();
    const activityMultiplier = 1.55;  // ปรับตามระดับกิจกรรม (เช่น ระดับกลาง)
    return bmr * activityMultiplier;
  }

  // ฟังก์ชันส่งข้อมูลไปที่ Backend
  Future<void> _submitSurvey() async {
    final url = Uri.parse('http://192.168.1.34:3000/api/survey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'age': int.parse(_ageController.text),
        'weight': double.parse(_weightController.text),
        'height': double.parse(_heightController.text),
        'bmi': _calculateBMI(),  // คำนวณค่า BMI ก่อนส่ง
        'bmr': _calculateBMR(),  // คำนวณค่า BMR ก่อนส่ง
        'tdee': _calculateTDEE(), // คำนวณค่า TDEE ก่อนส่ง
      }),
    );

    if (response.statusCode == 200) {
      print('Data saved successfully');
    } else {
      print('Failed to save data: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ระบุข้อมูลเพื่อเริ่มต้นใช้งาน'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField(
                  controller: _ageController,
                  label: 'อายุ (ปี)',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอายุ';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _weightController,
                  label: 'น้ำหนัก (กก.)',
                  icon: Icons.fitness_center,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกน้ำหนัก';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _heightController,
                  label: 'ส่วนสูง (ซม.)',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกส่วนสูง';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitSurvey();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Center(
                    child: Text(
                      'บันทึกข้อมูล',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}
