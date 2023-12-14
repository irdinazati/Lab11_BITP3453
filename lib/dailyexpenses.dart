import 'package:flutter/material.dart';
import 'Controller/request_controller.dart';
import 'Controller/sqlite_db.dart';
import 'Model/expense.dart';

/*void main() {
  runApp(DailyExpensesApp(username:''));
}*/

class DailyExpensesApp extends StatelessWidget {
  final String username;
  DailyExpensesApp({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExpenseList(username:username),
    );
  }
}

class ExpenseList extends StatefulWidget {
  final String username;
  ExpenseList({required this.username});

  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {

  final List<Expense> expenses = [];
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  double totalAmount = 0.0; // To store the total spending.

  void _addExpense() async{
    String description = descriptionController.text.trim();
    String amount = amountController.text.trim();
    if (description.isNotEmpty && amount.isNotEmpty) {
      Expense exp =
      Expense(double.parse(amount), description, txtDateController.text);
      if (await exp.save()){
        setState(() {
          //final double expenseAmount = double.parse(amount);
          expenses.add(exp);//(Expense(description, amount));
          descriptionController.clear();
          amountController.clear();
          calculateTotal();
        });
      } else{
        _showMessage("Failed to save Expenses data");

      }
    }
  }

  void calculateTotal() {
    totalAmount = 0;
    for (Expense ex in expenses) {
      totalAmount += ex.amount;
    }
    totalAmountController.text = totalAmount.toString();
  }

// Navigate to edit screen
  void _editExpense(int index) async {
    final editedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(
          expense: expenses[index],
          onSave: (editedExpense) {
            setState(() {
              totalAmount -= expenses[index].amount; // Deduct the original amount
              totalAmount += editedExpense.amount; // Add the edited amount
              expenses[index] = editedExpense;
              totalAmountController.text = totalAmount.toString();
            });
          },
        ),
      ),
    );

    // Check if the user made changes before updating the date-time
    if (editedExpense != null && editedExpense.dateTime != expenses[index].dateTime) {
      // Show date and time picker
      _selectDateAndTime(index);
    }
  }

// Select date and time
  void _selectDateAndTime(int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null) {
      setState(() {
        String newDateTime =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day} "
            "${pickedTime.hour}:${pickedTime.minute}:00";

        totalAmountController.text = totalAmount.toString();
        expenses[index].dateTime = newDateTime;
      });
    }
  }

  void _removeExpense(int index) async {
    if (expenses[index].id != null) {
      bool deleteSuccess = await expenses[index].delete();

      if (deleteSuccess) {
        setState(() {
          totalAmount -= expenses[index].amount;
          totalAmountController.text = totalAmount.toString();
          expenses.removeAt(index); // Remove from the list immediately
        });
      } else {
        // Handle deletion failure if needed
        print("Failed to delete expense.");
      }
    }
  }

  void _showMessage(String msg){
    if (mounted) {
      //make sure this context is still mounted/exist
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
        ),
      );
    }
  }

  _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedDate != null && pickedTime != null){
      setState(() {
        txtDateController.text =
        "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}"
            "${pickedTime.hour}:${pickedTime.minute}:00";
      });
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _showMessage("Welcome ${widget.username}");

      RequestController req = RequestController(
          path: "/api/timezone/Asia/Kuala_Lumpur",
          server: "http://worldtimeapi.org");
      req.get().then((value) {
        dynamic res = req.result();
        txtDateController.text =
            res["datetime"].toString().substring(0, 19).replaceAll('T', ' ');
      });
      expenses.addAll(await Expense.loadAll());

      setState(() {
        calculateTotal();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Expenses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount(RM)',
              ),
            ),
          ),
          Padding(
            //new textfield for the date and time
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.datetime,
              controller: txtDateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                  labelText: 'Date and Time'),
            ),
          ),

          Padding(
            //new textfield for the date and time
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: totalAmountController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Total Spend(RM):'),
            ),
          ),

          ElevatedButton(
            onPressed: _addExpense,
            child: Text('Add Expense'),
          ),

          Container(
            child: _buildListView(),
          )
        ],
      ),
    );
  }

  Widget _buildListView(){
    return Expanded(
      child: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index){
          return Dismissible(
            key: UniqueKey(),
            background: Container(
              color: Colors.red,
              child: Center(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            onDismissed: (direction) {
              setState(() {
                totalAmount -= expenses[index].amount;
                totalAmountController.text = totalAmount.toString();
                expenses.removeAt(index); // Remove from the list immediately
              });
            },
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(expenses[index].desc),
                subtitle: Row(
                  children: [
                    Text('Amount: ${expenses[index].amount}'),
                    const Spacer(),
                    Text('Date: ${expenses[index].dateTime}')
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeExpense(index),
                ),
                onLongPress: (){
                  _editExpense(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }


}

class EditExpenseScreen extends StatelessWidget {
  final Expense expense;
  final Function(Expense) onSave;

  EditExpenseScreen({required this.expense, required this.onSave});


  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Initialize the controllers with the current expense details
    descController.text = expense.desc;
    amountController.text = expense.amount.toString();
    dateTimeController.text = expense.dateTime;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Expense'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount(RM)',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            //child: GestureDetector(
            // onTap: () {
            //  _selectDateAndTime(context);
            // },
            child: TextField(
              controller: dateTimeController,
              readOnly: true,
              onTap: () {
                _selectDateAndTime(context);
              },
              decoration: InputDecoration(
                labelText: 'Date and Time',
              ),
            ),
            //),

          ),
          ElevatedButton(
            onPressed: () async  {
              // Save the edited expense details
              Expense updatedExpense = Expense.edit(
                  expense.id,
                  double.parse(amountController.text),
                  descController.text,
                  dateTimeController.text);
              onSave(
                  updatedExpense
              );

              if (await updatedExpense.update()){
                print("success");
              }
              else{
                print("not success");
              };
              // Navigate back to the ExpenseList screen
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null) {
      String newDateTime =
          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day} "
          "${pickedTime.hour}:${pickedTime.minute}:00";

      dateTimeController.text = newDateTime;
    }
  }
}

