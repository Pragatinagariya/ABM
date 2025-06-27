import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ABM2/add_hisab.dart';

class HisabList extends StatefulWidget {
  const HisabList({super.key});

  @override
  State<HisabList> createState() => _HisabListState();
}

class _HisabListState extends State<HisabList> {
  List<dynamic> hisabData = [];
  bool isLoading = true;
  double totalBalance = 0.0;

  Future<void> fetchHisab() async {
    final url = Uri.parse(
        "https://abm99.amisys.in/android/PHP/v2/hisab.php?clientcode=6d099&cmp=hnf");

    final response = await http.post(
      url,
      body: json.encode({"method": "read"}),
      headers: {"Content-Type": "application/json"},
    );

    final summaryResponse = await http.post(
      url,
      body: json.encode({"method": "summary"}),
      headers: {"Content-Type": "application/json"},
    );

    final jsonRes = json.decode(response.body);
    final jsonSummary = json.decode(summaryResponse.body);

    if (jsonRes["status"] == "success") {
      setState(() {
        hisabData = jsonRes["data"];
        isLoading = false;
      });
    }

    if (jsonSummary["status"] == "success") {
      setState(() {
        totalBalance = jsonSummary["summary"]["balance"];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHisab();
  }

  String getDay(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd').format(date);
  }

  String getMonth(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMM').format(date);
  }

  Map<String, List> groupByDate(List data) {
    Map<String, List> grouped = {};
    for (var item in data) {
      final date = item['entry_date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByDate(hisabData);

    return Scaffold(
      appBar: AppBar(
        title: Text("Hisab List"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  elevation: 2,
                  child: ListTile(
                    leading:
                        Icon(Icons.account_balance_wallet, color: Colors.blue),
                    title: Text("Total Balance",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      "₹${totalBalance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: totalBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: groupedData.entries.map((entry) {
                      final date = entry.key;
                      final items = entry.value;
                      final formattedDate = DateFormat('dd MMM yyyy')
                          .format(DateTime.parse(date));

                      double dailyTotal = 0.0;
                      for (var item in items) {
                        final amount =
                            double.tryParse(item['amount'].toString()) ?? 0.0;
                        dailyTotal +=
                            item['type'] == 'Received' ? amount : -amount;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "₹${dailyTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: dailyTotal >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((item) {
                            final isReceived = item['type'] == 'Received';
                            final amountColor =
                                isReceived ? Colors.green : Colors.red;
                            final amountSign = isReceived ? '+' : '-';

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        getDay(item['entry_date']),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800),
                                      ),
                                      Text(
                                        getMonth(item['entry_date']),
                                        style: TextStyle(
                                            color: Colors.blue.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Text(item['purpose']),
                                subtitle: item['remarks'] != null &&
                                        item['remarks'].isNotEmpty
                                    ? Text(item['remarks'])
                                    : null,
                                trailing: Text(
                                  '$amountSign₹${item['amount']}',
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHisab()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
