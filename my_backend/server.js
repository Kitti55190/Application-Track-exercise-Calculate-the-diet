const cors = require('cors');
const express = require('express');
const mongoose = require('mongoose');
const config = require('./config/config');
require('dotenv').config();

const app = express();

// ใช้ express.json() สำหรับแปลงข้อมูลใน request body เป็น JSON
app.use(express.json());
app.use(cors());

// Enhanced logging middleware สำหรับการตรวจสอบ headers และ request body
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Headers:', req.headers);
  if (req.method === 'POST') {
    console.log('Request body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// ตั้งค่า CORS เพื่อรองรับการเชื่อมต่อจากที่อยู่อื่น ๆ
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// ใช้ express.urlencoded() สำหรับการรับข้อมูลแบบ URL-encoded
app.use(express.urlencoded({ extended: true }));

// Routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

const usersRoutes = require('./routes/users');
app.use('/api/users', usersRoutes);

const mealRoutes = require('./routes/meal');
app.use('/api/meals', mealRoutes);

const registerSurveyRoutes = require('./routes/register_survey'); 
app.use('/api/register-survey', registerSurveyRoutes);

const tdeeRoutes = require('./routes/tdee');
app.use('/api/tdee', tdeeRoutes);

// Route ทดสอบว่า API ทำงานได้หรือไม่
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working' });
});

// เชื่อมต่อกับ MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB connected...'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Middleware สำหรับจัดการเส้นทางที่ไม่พบ (404)
app.use((req, res, next) => {
  console.log(`404 Not Found: ${req.method} ${req.url}`);
  res.status(404).json({ message: 'เส้นทางที่คุณร้องขอไม่มีในระบบ' });
});

// Middleware สำหรับจัดการข้อผิดพลาด
app.use((err, req, res, next) => {
  console.error('Error:', err);
  const statusCode = err.statusCode || 500;
  const message = err.message || 'เกิดข้อผิดพลาดในระบบ';
  res.status(statusCode).json({ 
    status: 'error',
    statusCode,
    message
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '192.168.159.195', () => {
  console.log(`Server running on http://192.168.159.195:${PORT}`);
});
