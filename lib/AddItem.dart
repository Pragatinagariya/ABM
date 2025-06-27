import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'dart:async';
import 'dart:io';

class ItemListPage extends StatefulWidget {
  final String clientcode;
  final String username;
  final String clientname;
  final String clientMap;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> savedItems; // Passed as a parameter

  const ItemListPage(
      {required this.clientcode,
      required this.username,
      required this.clientname,
      required this.clientMap,
      required this.orders,
      required this.savedItems,
      super.key});

  @override
  _ItemListPageState createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Set<String> _selectedItemIds = {}; // Track selected item IDs
  bool isLoading = true;
  bool _isSearching = false;
  String? errorMessage;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  String? _selectedItemName;
  String? _selectedItemId;
  late ScrollController _scrollController;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int pageNumber = 1;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _fetchItemNames();

    // Fetch previously selected items from passed arguments if any
    Future.delayed(Duration.zero, () {
      final selectedItems = ModalRoute.of(context)?.settings.arguments
          as List<Map<String, dynamic>>?;
      if (selectedItems != null && selectedItems.isNotEmpty) {
        setState(() {
          // Mark these items as selected
          for (var item in selectedItems) {
            _selectedItemIds.add(item['itemName']);
          }

          // Sort the items to show selected ones at the top
          _filteredItems.sort((a, b) {
            final aSelected = _selectedItemIds.contains(a['IM_ItemName']);
            final bSelected = _selectedItemIds.contains(b['IM_ItemName']);
            if (aSelected && !bSelected) {
              return -1; // Move selected items up
            } else if (!aSelected && bSelected) {
              return 1; // Move unselected items down
            }
            return 0; // Keep order the same if both are selected/unselected
          });
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !isLoadingMore &&
        hasMoreData) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      isLoadingMore = true;
      pageNumber++; // Move to next page
    });
    _fetchItemNames();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int _lastScannedTime = 0; // Store last scanned timestamp
  String _lastScannedBarcode = ''; // Store last scanned barcode

  Future<void> fetchItemData(String barcode) async {
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Ignore if the same barcode is scanned within 1 second
    if (barcode == _lastScannedBarcode &&
        (currentTime - _lastScannedTime) < 1000) {
      print("Duplicate scan ignored: $barcode");
      return;
    }

    _lastScannedTime = currentTime;
    _lastScannedBarcode = barcode;

    final String apiUrl = '${uriname}barcode.php';

    Map<String, String> body = {
      "clientcode": clientcode,
      "cmp": cmpcode,
      "barcode": barcode,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          String itemName = result['IM_name'];
          String itemRate = result['IM_SRate1'];
          String itemId = result['IM_id'].toString();

          if (_selectedItemIds.contains(itemId)) {
            showSnackBar('Item "$itemName" already added.');
            return;
          }

          final newItem = {
            'itemId': itemId,
            'itemName': itemName,
            'rate': itemRate.toString(),
            'quantity': '',
            'totalAmount': (double.parse(itemRate.toString()) * 1).toString(),
          };

          setState(() {
            _selectedItemIds.add(itemId);
          });

          // widget.orders.add(newItem);
          widget.savedItems.add(newItem);

          showSnackBar('Item: $itemName, Rate: ₹$itemRate added.');
        } else {
          showSnackBar('Error: ${result['message']}');
        }
      } else {
        showSnackBar('Failed to load data');
      }
    } catch (e) {
      showSnackBar('An error occurred: $e');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _fetchItemNames({String search = ''}) async {
    final uri =
        "${uriname}item_list_2.php?clientcode=$clientcode&cmp=$cmpcode&search=${Uri.encodeComponent(search)}&page=$pageNumber";

    print("Request URL: $uri");

    if (pageNumber == 1) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response =
          await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          if (pageNumber == 1) _items.clear();

          final newItems =
              data.map((item) => item as Map<String, dynamic>).toList();
          _items.addAll(newItems);

          hasMoreData =
              newItems.length >= 10; // If less than limit, no more data

          _filteredItems = _items;

          print('Items loaded: ${_items.length}');

          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load items: ${response.statusCode}';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Request timed out. Please try again.';
        isLoading = false;
        isLoadingMore = false;
      });
      print('Error: Request timed out');
    } on SocketException catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'No internet connection. Please check your network.';
        isLoading = false;
        isLoadingMore = false;
      });
      print('Error: No internet connection');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'An error occurred: $error';
        isLoading = false;
        isLoadingMore = false;
      });
      print('Error: $error');
    }
  }

  void _saveSelectedItems() {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedItems = _items.where((item) {
      final itemId = item['IM_ItemId'].toString();
      return _selectedItemIds.contains(itemId);
    }).map((item) {
      return {
        'itemName': item['IM_ItemName'],
        'rate': item['IM_SRate1'],
        'rate2': item['IM_SRate2'],
        'itemId': item['IM_ItemId'],
      };
    }).toList();

    // Add selected items to the passed orders and savedItems list
    for (var item in selectedItems) {
      final newItem = {
        'itemId': item['itemId'],
        'itemName': item['itemName'],
        'rate': item['rate'].toString(),
        'rate2': item['rate2'].toString(),
        'quantity': '',
        'totalAmount': (double.parse(item['rate'].toString()) * 1).toString(),
      };

      widget.orders.add(newItem);
      widget.savedItems.add(newItem); // Use passed savedItems
    }

    // Return selected items to the previous screen
    Navigator.pop(context, widget.savedItems); // Return updated selected items
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected items added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: _isSearching
            ? SizedBox(
                width: 250,
                height: 38,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode, // Set the focus node
                  onChanged: (value) {
                    pageNumber = 1;
                    _items.clear();
                    _filteredItems.clear();
                    _fetchItemNames(search: value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          searchController.clear();
                          _filteredItems = _items;
                        });
                        searchFocusNode.unfocus(); // Unfocus when cleared
                      },
                    ),
                  ),
                ),
              )
            : const Text('Add Item'),
        actions: [
          !_isSearching
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                    // Trigger focus to open keyboard
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusScope.of(context).requestFocus(searchFocusNode);
                    });
                  },
                )
              : Container(),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              // Navigate to the barcode scanner page
              var res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SimpleBarcodeScannerPage()),
              );

              // If a result (barcode) is returned, call the fetch function
              if (res != null) {
                print("Scanned Result: $res");
                fetchItemData(res); // Call the API with the scanned barcode
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedItemIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: SizedBox(
                height: 90, // Adjust height for the new design
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Display previously selected items from savedItems
                      ...widget.savedItems.map((savedItem) {
                        final itemId = savedItem['itemId'].toString();

                        final selectedItem = _items.firstWhere(
                          (item) => item['IM_ItemId'].toString() == itemId,
                          orElse: () =>
                              {}, // Provide an empty map if item is not found
                        );

                        if (selectedItem.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '$uriname$clientcode/$xyz/Images/Items/${selectedItem["IM_ItemId"]}_1.jpg',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/icons/00000000.jpg', // Default image
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        selectedItem['IM_ItemName'] ??
                                            'Unknown',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -20,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 19),
                                    padding: const EdgeInsets.all(0),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        widget.savedItems.removeWhere(
                                            (savedItem) =>
                                                savedItem['itemId'] == itemId);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container(); // Return empty container if item not found
                        }
                      }),

                      // Display currently selected items from _selectedItemIds
                      ..._selectedItemIds.map((itemId) {
                        final selectedItem = _items.firstWhere(
                          (item) => item['IM_ItemId'].toString() == itemId,
                          orElse: () =>
                              {}, // Provide an empty map if item is not found
                        );

                        if (selectedItem.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '$uriname$clientcode/$xyz/Images/Items/${selectedItem["IM_ItemId"]}_1.jpg',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/icons/00000000.jpg', // Default image
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        selectedItem['IM_ItemName'] ??
                                            'Unknown',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -20,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 19, color: Colors.black),
                                    padding: const EdgeInsets.all(0),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _selectedItemIds.remove(
                                            itemId); // Remove from selected items
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container(); // Return empty container if item not found
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: (_filteredItems.length / 2).ceil() +
                            1, // +1 for loading indicator
                        itemBuilder: (context, index) {
                          if (index == (_filteredItems.length / 2).ceil()) {
                            return hasMoreData
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  )
                                : const SizedBox.shrink();
                          }

                          final item1 = _filteredItems[index * 2];
                          final item2 = index * 2 + 1 < _filteredItems.length
                              ? _filteredItems[index * 2 + 1]
                              : null;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildItemCard(item1)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: item2 != null
                                      ? _buildItemCard(item2)
                                      : const SizedBox(), // to maintain spacing
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ElevatedButton(
            onPressed: _saveSelectedItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final String itemId = item['IM_ItemId'].toString();
    final bool isSelected = _selectedItemIds.contains(itemId);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedItemIds.remove(itemId);
            } else {
              _selectedItemIds.add(itemId);
            }
          });
        },
        child: Stack(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Image.network(
                        item["IM_ItemId"] != null &&
                                item["IM_ItemId"].isNotEmpty
                            ? '$uriname$clientcode/$xyz/Images/Items/${item["IM_ItemId"]}_1.jpg'
                            : 'assets/images/icons/00000000.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/images/icons/00000000.jpg',
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['IM_ItemName'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate: ₹${item['IM_SRate1']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Rate2: ₹${item['IM_SRate2']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 12,
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
