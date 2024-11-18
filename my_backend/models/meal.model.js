const mongoose = require('mongoose');

// สร้าง Schema สำหรับเมนูอาหาร
const mealSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  calories: {
    type: Number,
    required: true
  },
  protein: {
    type: Number,
    required: true
  },
  fat: {
    type: Number,
    required: true
  },
  category: {
    type: String,
    enum: ['สลัดเพื่อสุขภาพ', 'อาหารแคลอรี่ต่ำ', 'โปรตีนสูง'], // หมวดหมู่ที่เราสามารถกำหนดได้
    required: true
  }
});

// สร้างโมเดล
const Meal = mongoose.model('Meal', mealSchema);

module.exports = Meal;
