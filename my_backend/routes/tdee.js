const express = require('express');
const User = require('../models/user'); // โมเดลผู้ใช้
const router = express.Router();

// API สำหรับดึงค่า TDEE ของผู้ใช้
router.get('/user/:id/tdee', async (req, res) => {
  console.log(`Request received for user ID: ${req.params.id}`); // ตรวจสอบว่ามีการรับคำขอจาก client
  
  try {
    const user = await User.findById(req.params.id); // ดึงข้อมูลผู้ใช้ตาม ID
    if (!user) {
      console.log('ไม่พบผู้ใช้'); // แจ้งเตือนหากไม่พบผู้ใช้
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }

    console.log(`TDEE ของผู้ใช้: ${user.tdee}`); // แสดงค่า TDEE ของผู้ใช้ใน console
    res.json({ tdee: user.tdee });  // ส่งค่า TDEE ของผู้ใช้กลับไป
  } catch (error) {
    console.error('Error fetching user data:', error); // แสดง error ใน console
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในระบบ', error: error.message });
  }
});

module.exports = router;
