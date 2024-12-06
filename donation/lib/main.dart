import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

void main() {
  runApp(SakhwatApp());
}

class SakhwatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sakhwat Welfare Foundation',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Database database;
  int totalBalance = 0;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    database = await openDatabase(
      p.join(await getDatabasesPath(), 'welfare.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY, type TEXT, name TEXT, amount INTEGER, description TEXT, date TEXT)',
        );
      },
      version: 1,
    );
    _calculateTotalBalance();
  }

  Future<void> _calculateTotalBalance() async {
    final List<Map<String, dynamic>> donations = await database.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "donation"',
    );
    final List<Map<String, dynamic>> withdrawals = await database.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "withdrawal"',
    );

    setState(() {
      final int donationTotal = (donations.first['total'] ?? 0) as int;
      final int withdrawalTotal = (withdrawals.first['total'] ?? 0) as int;
      totalBalance = donationTotal - withdrawalTotal;
    });
  }

  Widget _buildDashboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            color: Colors.indigo[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    "Total Balance",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Rs. $totalBalance",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: totalBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDonationList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.query(
        'transactions',
        where: 'type = ?',
        whereArgs: ['donation'],
        orderBy: 'date DESC',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(child: Text("No donations available."));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(transaction['name']),
                subtitle: Text(
                  "Rs. ${transaction['amount']} (${transaction['date']})",
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithdrawalList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.query(
        'transactions',
        where: 'type = ?',
        whereArgs: ['withdrawal'],
        orderBy: 'date DESC',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(child: Text("No withdrawals available."));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(transaction['name']),
                subtitle: Text(
                  "Rs. ${transaction['amount']} (${transaction['date']})",
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildAddTransaction(String type) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text(
                type == "donation" ? "Add Donation" : "Add Withdrawal",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name / Purpose",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "This field cannot be empty" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount (Rs.)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? "Enter a valid amount" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await database.insert('transactions', {
                      'type': type,
                      'name': nameController.text,
                      'amount': int.parse(amountController.text),
                      'description': descriptionController.text,
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    });
                    _calculateTotalBalance();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$type added successfully!")),
                    );
                    nameController.clear();
                    amountController.clear();
                    descriptionController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.query('transactions', orderBy: 'date DESC'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!;
        if (transactions.isEmpty) {
          return Center(child: Text("No transactions available."));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(transaction['name']),
                subtitle: Text(
                  "${(transaction['type'] as String).toUpperCase()} - Rs. ${transaction['amount']} (${transaction['date']})",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _editTransaction(transaction);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteTransaction(transaction['id']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editTransaction(Map<String, dynamic> transaction) {
    final nameController = TextEditingController(text: transaction['name']);
    final amountController =
    TextEditingController(text: transaction['amount'].toString());
    final descriptionController =
    TextEditingController(text: transaction['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Transaction"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name / Purpose"),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await database.update(
                  'transactions',
                  {
                    'name': nameController.text,
                    'amount': int.parse(amountController.text),
                    'description': descriptionController.text,
                  },
                  where: 'id = ?',
                  whereArgs: [transaction['id']],
                );
                Navigator.pop(context);
                _calculateTotalBalance();
                setState(() {});
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(int id) async {
    await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    _calculateTotalBalance();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Transaction deleted")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sakhwat Welfare Foundation"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfScreen(database: database),
                ),
              );
            },
          ),
        ],
      ),
      body: currentIndex == 0
          ? _buildDashboard()
          : currentIndex == 1
          ? _buildAddTransaction("donation")
          : currentIndex == 2
          ? _buildAddTransaction("withdrawal")
          : _buildTransactionList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Ensures all icons are visible
        backgroundColor: Colors.white, // Sets the background color of the bar
        selectedItemColor: Colors.blue, // Highlights the selected item
        unselectedItemColor: Colors.grey, // Grays out unselected items
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold), // Bold label for selected item
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal), // Normal weight for unselected items
        elevation: 10, // Adds a shadow for a floating effect
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: "Add Donation",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle_outline),
            activeIcon: Icon(Icons.remove_circle),
            label: "Add Withdrawal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: "Transactions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism),
            label: "Donations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off_csred_outlined),
            activeIcon: Icon(Icons.money_off_csred),
            label: "Withdrawals",
          ),
        ],
      ),

    );
  }
}
class PdfScreen extends StatefulWidget {
  final Database database;

  PdfScreen({required this.database});

  @override
  _PdfScreenState createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _generatePdf() async {
    // Fetch transactions for the selected month
    final transactions = await widget.database.rawQuery(
      'SELECT * FROM transactions WHERE strftime("%Y-%m", date) = ?',
      [selectedMonth],
    );

    final pdf = pw.Document();

    // Calculate totals
    final donationTotal = transactions
        .where((t) => t['type'] == 'donation')
        .fold(0, (sum, t) => sum + (t['amount'] as int));
    final withdrawalTotal = transactions
        .where((t) => t['type'] == 'withdrawal')
        .fold(0, (sum, t) => sum + (t['amount'] as int));
    final balance = donationTotal - withdrawalTotal;

    // Add data to the PDF document
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Sakhwat Welfare Foundation",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                "Monthly Report - $selectedMonth",
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Type', 'Name', 'Amount (Rs.)', 'Description', 'Date'],
                data: transactions.map((t) {
                  return [
                    (t['type'] as String).toUpperCase(),
                    t['name'],
                    t['amount'],
                    t['description'] ?? '-',
                    t['date'],
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Total Donations: Rs. $donationTotal"),
              pw.Text("Total Withdrawals: Rs. $withdrawalTotal"),
              pw.Text("Final Balance: Rs. $balance"),
            ],
          );
        },
      ),
    );

    // Save the PDF to the device
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'monthly_report_$selectedMonth.pdf'));
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF file
    await OpenFile.open(file.path); // This now works correctly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF saved and opened from ${file.path}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generate PDF Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Month:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedMonth,
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
              items: List.generate(12, (index) {
                final date = DateTime(DateTime.now().year, index + 1);
                final formattedMonth = DateFormat('yyyy-MM').format(date);
                return DropdownMenuItem<String>(
                  value: formattedMonth,
                  child: Text(DateFormat('MMMM yyyy').format(date)),
                );
              }),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _generatePdf,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("Generate PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
