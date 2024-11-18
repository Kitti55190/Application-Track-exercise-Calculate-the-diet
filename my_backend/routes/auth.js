const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/user'); // โมเดลผู้ใช้
const router = express.Router();

// Route สำหรับเข้าสู่ระบบ
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // ตรวจสอบอีเมลและรหัสผ่าน
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    // ส่งข้อมูลผู้ใช้กลับไปที่ client
    res.json({
      message: 'เข้าสู่ระบบสำเร็จ',
      user: {
        _id: user._id,
        email: user.email,
        age: user.age,
        tdee: user.tdee,  // ส่งค่า TDEE ของผู้ใช้กลับไป
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในระบบ' });
  }
});

module.exports = router;
