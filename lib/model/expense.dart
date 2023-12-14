import 'package:shared_preferences/shared_preferences.dart';

import '../Controller/request_controller.dart';
import '../Controller/sqlite_db.dart';

class Expense{
  static const String SQLiteTable = "expense";
  int? id;
  String desc;
  double amount;
  String dateTime;
  Expense(this.amount, this.desc, this.dateTime);
  Expense.edit(this.id,this.amount, this.desc, this.dateTime);

  Expense.fromJson(Map<String, dynamic> json)
      : desc = json ['Desc'] as String,
        amount = double.parse (json['Amount'] as dynamic),
        dateTime = json['dateTime'] as String,
        id = json['id'] as int?;

  //toJson will be automically called by jsonEncode when necessary

  Map<String, dynamic> toJson() =>
      {'Desc' : desc, 'Amount' : amount, 'dateTime' : dateTime, 'id' : id};

  Future<bool> save() async {
    //save to local SQlite
    await SQLiteDB().insert(SQLiteTable, toJson());
    /*//API Operation
    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());
    await req.post();*/

    final prefs = await SharedPreferences.getInstance();
    String? server = prefs.getString('ip');
    RequestController req = RequestController(path: "/api/expenses.php",
        server:"http://$server" );
    req.setBody(toJson());
    if (req.status() == 200) {
      return true;
    }
    else
    {
      if (await SQLiteDB().insert(SQLiteTable, toJson()) !=0) {
        return true;
      } else{
        return false;
      }
    }
  }

  Future<bool> update() async {
    //save to local SQlite
    await SQLiteDB().update(SQLiteTable, 'id', toJson());

    final prefs = await SharedPreferences.getInstance();
    String? server = prefs.getString('ip');
    RequestController req = RequestController(path: "/api/expenses.php",
        server:"http://$server" );
    req.setBody(toJson());
    await req.put();

    if (req.status() == 200){
      return true;
    }
    else
    {
      if (await SQLiteDB().update(SQLiteTable,'id', toJson()) !=0) {
        return true;
      } else{
        return false;
      }
    }
  }

  Future<bool> delete() async {

    // Save to local SQLite
    await SQLiteDB().delete(SQLiteTable, 'id', toJson());


    /* // API Operation
        RequestController req = RequestController(path: "/api/expenses.php");
        req.setBody({'id': id});
        await req.delete();*/

    final prefs = await SharedPreferences.getInstance();
    String? server = prefs.getString('ip');
    RequestController req = RequestController(path: "/api/expenses.php",
        server:"http://$server" );
    req.setBody(toJson());
    await req.delete();


    if (req.status() == 200) {
      return true;
    } else {
      if (await SQLiteDB().insert(SQLiteTable, toJson()) != 0) {
        return true;
      } else {
        return false;
      }
    }

  }

  static Future<List<Expense>> loadAll() async{

    //API Operation
    List<Expense> result = [];
    /*RequestController req = RequestController(path: "/api/expenses.php");
    await req.get();*/

    final prefs = await SharedPreferences.getInstance();
    String? server = prefs.getString('ip');
    RequestController req = RequestController(path: "/api/expenses.php", server:"http://$server" );
    await req.get();

    if (req.status() == 200 && req.result() != null){
      for (var item in req.result()) {
        result.add(Expense.fromJson(item));
      }
    }
    else
    {
      List<Map<String, dynamic>> result = await SQLiteDB().queryAll(SQLiteTable);
      List<Expense> expenses = [];
      for (var item in result) {
        result.add(Expense.fromJson(item)as Map<String, dynamic>);
      }
    }
    return result;
  }
}




