const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
  name: String,
  calories: Number,
  duration: Number,
  dateTime: { type: Date, default: Date.now },
  steps: { type: Number, default: 0 },
  distance: { type: Number, default: 0 }
});

const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  age: Number,
  weight: Number,
  height: Number,
  bmi: Number,
  bmr: Number,
  tdee: Number,
  gender: String,
  exercises: [exerciseSchema]
});

module.exports = mongoose.model('User', userSchema);