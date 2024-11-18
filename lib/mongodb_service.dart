import 'package:mongo_dart/mongo_dart.dart';

class MongoDBService {
  final Db _db = Db('mongodb://localhost:27017/your_database_name'); // กำหนด URL ของ MongoDB

  Future<void> connect() async {
    await _db.open();
    print("Connected to MongoDB");
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    var collection = _db.collection('your_collection_name'); // เปลี่ยนเป็นชื่อ collection ที่ต้องการ
    await collection.insert(data);
    print("Data inserted");
  }

  Future<List<Map<String, dynamic>>> getData() async {
    var collection = _db.collection('your_collection_name');
    return await collection.find().toList();
  }

  Future<void> close() async {
    await _db.close();
    print("Disconnected from MongoDB");
  }
}
