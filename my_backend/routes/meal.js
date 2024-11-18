const express = require('express');
const router = express.Router();
const Meal = require('../models/meal.model');

// เพิ่มเมนูอาหาร
router.post('/add', async (req, res) => {
  try {
    const newMeal = new Meal(req.body);
    await newMeal.save();
    res.status(201).json({ message: 'เพิ่มเมนูสำเร็จ', meal: newMeal });
  } catch (error) {
    res.status(400).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มเมนู', error: error.message });
  }
});

// ลบเมนูอาหาร
router.delete('/:id', async (req, res) => {
  try {
    const meal = await Meal.findByIdAndDelete(req.params.id);
    if (!meal) {
      return res.status(404).json({ message: 'ไม่พบเมนูที่ต้องการลบ' });
    }
    res.status(200).json({ message: 'ลบเมนูเรียบร้อยแล้ว', deletedMeal: meal });
  } catch (error) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการลบเมนู', error: error.message });
  }
});

// ดึงข้อมูลเมนูอาหารทั้งหมด
router.get('/', async (req, res) => {
  try {
    const meals = await Meal.find();
    res.status(200).json(meals);
  } catch (error) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลเมนู', error: error.message });
  }
});

// อัปเดตเมนูอาหาร
router.put('/:id', async (req, res) => {
  try {
    const updatedMeal = await Meal.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!updatedMeal) {
      return res.status(404).json({ message: 'ไม่พบเมนูที่ต้องการอัปเดต' });
    }
    res.status(200).json({ message: 'อัปเดตเมนูเรียบร้อยแล้ว', meal: updatedMeal });
  } catch (error) {
    res.status(400).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตเมนู', error: error.message });
  }
});

module.exports = router;