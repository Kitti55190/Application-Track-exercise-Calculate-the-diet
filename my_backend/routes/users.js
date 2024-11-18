const express = require('express');
const router = express.Router();
const User = require('../models/user');

// Middleware สำหรับตรวจสอบ request body
const validateExercise = (req, res, next) => {
  const { name, calories, duration } = req.body;
  
  console.log('Validating exercise data:', req.body);
  
  if (!name || calories == null || duration == null) {
    return res.status(400).json({ 
      message: 'ข้อมูลไม่ครบถ้วน',
      required: ['name', 'calories', 'duration'],
      received: req.body 
    });
  }
  next();
};

// ดึงรายการการออกกำลังกายของผู้ใช้
router.get('/:userId/exercises', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('exercises');
    if (!user) {
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }
    
    // จัดกลุ่มข้อมูลตามวันที่
    const exercisesByDate = user.exercises.reduce((acc, exercise) => {
      const date = new Date(exercise.dateTime);
      const dateKey = date.toISOString().split('T')[0]; // ใช้เฉพาะส่วนวันที่ YYYY-MM-DD
      
      if (!acc[dateKey]) {
        acc[dateKey] = {
          name: exercise.name,
          calories: exercise.calories,
          duration: exercise.duration,
          steps: exercise.steps || 0,
          distance: exercise.distance || 0,
          dateTime: date,
          activities: [exercise]
        };
      } else {
        acc[dateKey].calories += exercise.calories;
        acc[dateKey].duration += exercise.duration;
        acc[dateKey].steps += exercise.steps || 0;
        acc[dateKey].distance += exercise.distance || 0;
        acc[dateKey].activities.push(exercise);
        
        // ถ้ามีหลายกิจกรรม ให้แสดงเป็น "หลายกิจกรรม"
        acc[dateKey].name = acc[dateKey].activities.length > 1 ? 'หลายกิจกรรม' : exercise.name;
      }
      
      return acc;
    }, {});
    
    // แปลงเป็น array และจัดเรียงตามวันที่จากใหม่ไปเก่า
    const sortedExercises = Object.values(exercisesByDate).sort((a, b) => {
      return new Date(b.dateTime) - new Date(a.dateTime);
    });
    
    console.log('Sending aggregated exercises data:', sortedExercises);
    res.json(sortedExercises);
  } catch (error) {
    console.error('Error fetching exercises:', error);
    res.status(500).json({ 
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล', 
      error: error.message 
    });
  }
});

// เพิ่มการออกกำลังกายให้ผู้ใช้
router.post('/:userId/exercises', validateExercise, async (req, res) => {
  try {
    const { name, calories, duration, dateTime, steps, distance } = req.body;
    console.log('Received exercise data:', req.body);

    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }

    // สร้างข้อมูลการออกกำลังกาย
    const exercise = {
      name,
      calories: Math.round(calories),
      duration: parseInt(duration),
      dateTime: dateTime ? new Date(dateTime) : new Date(),
      steps: steps || 0,
      distance: distance || 0
    };
    console.log('Created exercise object:', exercise);
    
    // เพิ่มข้อมูลลงใน exercises array
    user.exercises.push(exercise);
    
    // บันทึกข้อมูล
    await user.save();
    
    console.log('Successfully saved exercise:', exercise);
    
    res.status(201).json({ 
      message: 'เพิ่มการออกกำลังกายสำเร็จ', 
      exercise 
    });
  } catch (error) {
    console.error('Error saving exercise:', error);
    res.status(500).json({ 
      message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล', 
      error: error.message 
    });
  }
});

// ลบการออกกำลังกาย
router.delete('/:userId/exercises/:exerciseId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }

    // ค้นหาและลบ exercise
    const exerciseIndex = user.exercises.findIndex(
      ex => ex._id.toString() === req.params.exerciseId
    );

    if (exerciseIndex === -1) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลการออกกำลังกาย' });
    }

    // ลบข้อมูล
    user.exercises.splice(exerciseIndex, 1);
    await user.save();

    res.json({ message: 'ลบข้อมูลการออกกำลังกายสำเร็จ' });
  } catch (error) {
    console.error('Error deleting exercise:', error);
    res.status(500).json({ 
      message: 'เกิดข้อผิดพลาดในการลบข้อมูล', 
      error: error.message 
    });
  }
});

module.exports = router;