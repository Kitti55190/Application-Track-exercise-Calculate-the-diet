const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/user'); // สมมติว่าโมเดลผู้ใช้คือ User
const router = express.Router();

router.post('/', async (req, res) => {
  const { name, email, password, age, weight, height, gender, bmi, bmr, tdee } = req.body;
  
  try {
    const hashedPassword = await bcrypt.hash(password, 12);

    const newUser = new User({
      name,
      email,
      password: hashedPassword,
      age,
      weight,
      height,
      gender,
      bmi,
      bmr,
      tdee
    });

    await newUser.save();
    res.status(201).json({ message: 'ลงทะเบียนและบันทึกข้อมูลสำรวจสำเร็จ', user: newUser });
  } catch (error) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาด', error: error.message });
  }
});

module.exports = router;
