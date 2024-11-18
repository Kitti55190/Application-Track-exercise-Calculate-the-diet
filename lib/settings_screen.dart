import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Color primaryGreen = Color(0xFF4CAF50);
  final Color secondaryGreen = Color(0xFF81C784);
  final Color lightGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildSettingsContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryGreen,
      elevation: 4,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'การตั้งค่า',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryGreen, secondaryGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Icon(
                  Icons.eco,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Center(
                child: Icon(
                  Icons.settings,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return Container(
      color: lightGreen,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ข้อมูลสุขภาพ'),
            _buildSettingsCard(
              context,
              [
                _buildSettingsTile(
                  icon: Icons.person,
                  iconColor: primaryGreen,
                  title: 'ข้อมูลส่วนตัว',
                  subtitle: 'ส่วนสูง, น้ำหนัก, และอื่นๆ',
                  onTap: () {
                    // TODO: Navigate to profile screen
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.favorite,
                  iconColor: Colors.red[400]!,
                  title: 'เป้าหมายสุขภาพ',
                  subtitle: 'กำหนดเป้าหมายการออกกำลังกาย',
                  onTap: () {
                    // TODO: Navigate to health goals
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.notifications_active,
                  iconColor: Colors.orange[600]!,
                  title: 'การแจ้งเตือน',
                  trailing: Switch(
                    value: true,
                    activeColor: primaryGreen,
                    onChanged: (bool value) {
                      // TODO: Implement notifications toggle
                    },
                  ),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSectionTitle('การตั้งค่าทั่วไป'),
            _buildSettingsCard(
              context,
              [
                _buildSettingsTile(
                  icon: Icons.cloud_upload,
                  iconColor: secondaryGreen,
                  title: 'ซิงค์ข้อมูล',
                  subtitle: 'อัพเดทล่าสุด: วันนี้ 10:00',
                  onTap: () {
                    // TODO: Implement sync
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  iconColor: primaryGreen,
                  title: 'ภาษา',
                  subtitle: 'ไทย',
                  onTap: () {
                    // TODO: Implement language change
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  iconColor: secondaryGreen,
                  title: 'รูปแบบวันที่',
                  subtitle: 'วว/ดด/ปปปป',
                  onTap: () {
                    // TODO: Implement date format change
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSectionTitle('ความปลอดภัย'),
            _buildSettingsCard(
              context,
              [
                _buildSettingsTile(
                  icon: Icons.lock,
                  iconColor: primaryGreen,
                  title: 'เปลี่ยนรหัสผ่าน',
                  onTap: () {
                    // TODO: Implement password change
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  iconColor: secondaryGreen,
                  title: 'การยืนยันตัวตนสองชั้น',
                  trailing: Switch(
                    value: false,
                    activeColor: primaryGreen,
                    onChanged: (bool value) {
                      // TODO: Implement two-factor authentication
                    },
                  ),
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  iconColor: primaryGreen,
                  title: 'นโยบายความเป็นส่วนตัว',
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildLogoutButton(context),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null 
        ? Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ) 
        : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text(
          'ออกจากระบบ',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _showLogoutConfirmation(context),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ยืนยันการออกจากระบบ',
            style: TextStyle(color: primaryGreen),
          ),
          content: Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              child: Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
