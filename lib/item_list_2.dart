import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ABM2/globals.dart';
import 'package:flutter/painting.dart';

import 'package:ABM2/network_utils/api_manager.dart';
import 'package:ABM2/response/item_list_response.dart';
import 'package:ABM2/screens/custom_loader.dart';
import 'package:ABM2/utils/activity_util.dart';
import 'package:ABM2/utils/logger_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as ui show TextPainter, TextSpan;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sqflite/sqflite.dart';

import '../../globals.dart' as globals;

class ItemListNew extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String cmpcode;

  const ItemListNew({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.cmpcode,
  });

  @override
  State<ItemListNew> createState() => ItemListNewState();
}

class ItemListNewState extends State<ItemListNew> {
  List<ItemModel> _items = [];
  List<ItemModel> _filteredItems = [];
  final Set<String> _selectedItemIds = {}; // Track selected item IDs
  bool isLoading = true;
  String? errorMessage;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final bool _isListening = false;
  String _voiceInput = "";
  bool _isSearching = false;
  TextEditingController searchController = TextEditingController();
  Set<int> selectedItems = {};
  bool selectionMode = false;
  String nameFilter = '';
  String groupFilter = '';
  String rateFilter = '';
  String selectedFilter = '';
  String selectedNameRange = 'A-Z'; // Set default to 'A-Z'
  List<dynamic> filteredData = [];
  List<String> groupNames = [];
  File? _image;
  String? item;
  int pageNumber = 1;

  final ImagePicker _picker = ImagePicker();
  RangeValues rateRange = const RangeValues(0, 1000);
  int _columnCount = 2;
  FocusNode searchFocusNode = FocusNode();
  late Database _database;
  final List<File> _images = [];
  final List<bool> _selectedImages = [];
  final int _nextImageIndex = 1;
  int _nextIndex = 1; // Default to 1 if no images exist yet
  List<Map<String, dynamic>> _switchOptions = [];

  bool _isFieldVisible(String zKeyword) {
    final option = _switchOptions.firstWhere(
      (element) => element['z_keyword'] == zKeyword,
      orElse: () => {'z_keyvalue': 0},
    );
    return option['z_keyvalue'] == 1;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    pageNumber = 1;
    _items = [];
    _scrollController.addListener(() {
      // Trigger when reaching 90% of scroll extent
      if (_scrollController.offset >=
          _scrollController.position.maxScrollExtent) {
        if (_items.length >= (45 * pageNumber) && !isLoading) {
          setState(() {
            pageNumber++;
          });
          Logger.get().log("Api pageNumber >>>>>> $pageNumber");
          _fetchItemNames();
        }
      }
    });
    _fetchItemNames();
    _fetchGroupNames();
    _initializeDatabase();
    _initializeSpeechRecognition();
    _requestPermissions();
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
            final aSelected = _selectedItemIds.contains(a.iMItemName);
            final bSelected = _selectedItemIds.contains(b.iMItemName);
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

  void _fetchItemNames({String search = ''}) async {
    print('🔍 Search term: $search');

    final uri = Uri.parse(
      "http://103.159.85.77:4000/items?clientcode=$clientcode&cmp=$cmpcode&search=${Uri.encodeComponent(search)}&page=$pageNumber",
    );

    try {
      setState(() {
        isLoading = true;
      });

      final rawResponse = await http.get(uri);

      print('🌐 Raw HTTP Status: ${rawResponse.statusCode}');
      print('📄 Raw Response Body: ${rawResponse.body}');

      if (rawResponse.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage =
              // 'Server returned status code ${rawResponse.statusCode}';
              ' data Not found';
        });
        return;
      }

      final List<dynamic> jsonData = json.decode(rawResponse.body);

      List<ItemModel> items =
          jsonData.map((e) => ItemModel.fromJson(e)).toList();

      setState(() {
        isLoading = false;

        if (pageNumber == 1) {
          _items.clear();
        }

        _items.addAll(items);
        print('🧮 Total Items Fetched: ${_items.length}');

        _filteredItems = search.isEmpty
            ? _items
            : _items.where((item) {
                final itemName = item.iMItemName?.toLowerCase() ?? '';
                return itemName.contains(search.toLowerCase());
              }).toList();

        if (_filteredItems.isEmpty) {
          print('🚫 No items found for: $search');
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = '❗ Error occurred: $error';
        isLoading = false;
      });
      print('❗ Exception: $error');
    }
  }

  Future<File> downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image');
    }

    final Uint8List originalBytes = response.bodyBytes;
    final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    // Draw original image
    canvas.drawImage(originalImage, ui.Offset.zero, paint);

    // Set up watermark text style
    const watermarkText = 'WATERMARK';
    final textStyle = ui.TextStyle(
      color: const ui.Color.fromARGB(
          100, 255, 0, 0), // Light red, semi-transparent
      fontSize: 50,
      fontWeight: ui.FontWeight.bold,
    );

    // Create text painter once
    final textSpan = ui.TextSpan(text: watermarkText, style: TextStyle());
    final textPainter = ui.TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    // Repeat the watermark text across the image diagonally
    final stepX = textPainter.width + 60;
    final stepY = textPainter.height + 60;

    for (double y = -originalImage.height.toDouble();
        y < originalImage.height;
        y += stepY) {
      for (double x = -originalImage.width.toDouble();
          x < originalImage.width * 2;
          x += stepX) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.4); // Diagonal rotation
        textPainter.paint(canvas, ui.Offset.zero);
        canvas.restore();
      }
    }
    Future<File> downloadPlainImage(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final Uint8List imageBytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${imageUrl.split('/').last}';
      final file = File(filePath);

      await file.writeAsBytes(imageBytes);
      return file;
    }

    Future<File> downloadImageWithWatermark(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final Uint8List originalBytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();

      canvas.drawImage(originalImage, ui.Offset.zero, paint);

      const watermarkText = 'WATERMARK';
      final textStyle = ui.TextStyle(
        color: ui.Color.fromARGB(100, 255, 0, 0),
        fontSize: 50,
        fontWeight: ui.FontWeight.bold,
      );

      final textSpan = ui.TextSpan(text: watermarkText, style: TextStyle());
      final textPainter = ui.TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      final stepX = textPainter.width + 60;
      final stepY = textPainter.height + 60;

      for (double y = -originalImage.height.toDouble();
          y < originalImage.height;
          y += stepY) {
        for (double x = -originalImage.width.toDouble();
            x < originalImage.width * 2;
            x += stepX) {
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(-0.4);
          textPainter.paint(canvas, ui.Offset.zero);
          canvas.restore();
        }
      }

      final watermarkedImage = await recorder
          .endRecording()
          .toImage(originalImage.width, originalImage.height);
      final byteData =
          await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/watermarked_${imageUrl.split('/').last}';
      final file = File(filePath);

      await file.writeAsBytes(pngBytes);
      return file;
    }

    // End drawing
    final watermarkedImage = await recorder
        .endRecording()
        .toImage(originalImage.width, originalImage.height);
    final byteData =
        await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

    final pngBytes = byteData!.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${imageUrl.split('/').last}';
    final file = File(filePath);

    await file.writeAsBytes(pngBytes);
    return file;
  }

  Future<File> downloadImageWithCompanyIcon(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Decode original image
      final Uint8List originalBytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      // Load company icon from assets
      final ByteData iconData =
          await rootBundle.load('assets/images/icons/Pragati.png');
      final Uint8List iconBytes = iconData.buffer.asUint8List();
      final ui.Codec iconCodec = await ui.instantiateImageCodec(iconBytes);
      final ui.FrameInfo iconFrame = await iconCodec.getNextFrame();
      final ui.Image iconImage = iconFrame.image;

      // Prepare canvas
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();

      // Draw original image on canvas
      canvas.drawImage(originalImage, ui.Offset.zero, paint);

      // Compute icon position (bottom right)
      final double x = originalImage.width - iconImage.width - 20;
      final double y = originalImage.height - iconImage.height - 20;
      canvas.drawImage(iconImage, ui.Offset(x, y), paint);

      // Finalize canvas and convert to image
      final ui.Image finalImage = await recorder
          .endRecording()
          .toImage(originalImage.width, originalImage.height);
      final ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to file
      final dir =
          await getTemporaryDirectory(); // Or getApplicationDocumentsDirectory
      final fileName = 'icon_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      print("✅ Image saved with icon at: $filePath");

      return file;
    } catch (e) {
      print("❌ Error adding icon: $e");
      rethrow;
    }
  }

  Future<File> downloadImageWithWatermarkAndCompanyIcon(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final Uint8List originalBytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw the original image
      canvas.drawImage(originalImage, Offset.zero, paint);

      // Load company icon
      final ByteData iconData =
          await rootBundle.load('assets/images/icons/Pragati.png');
      final Uint8List iconBytes = iconData.buffer.asUint8List();
      final ui.Codec iconCodec = await ui.instantiateImageCodec(iconBytes);
      final ui.FrameInfo iconFrame = await iconCodec.getNextFrame();
      final ui.Image iconImage = iconFrame.image;

      // Draw watermark text repeatedly
      const watermarkText = 'WATERMARK';
      final textStyle = TextStyle(
        color: Colors.black.withValues(alpha: 0.3),
        fontSize: 40,
        fontWeight: FontWeight.bold,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: watermarkText, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      for (double y = 0; y < originalImage.height; y += 260) {
        for (double x = 0; x < originalImage.width; x += 320) {
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(-0.3); // diagonal tilt
          textPainter.paint(canvas, Offset.zero);
          canvas.restore();
        }
      }

      // Draw the company icon at the bottom right
      const double margin = 20;
      final double iconX = originalImage.width - iconImage.width - margin;
      final double iconY = originalImage.height - iconImage.height - margin;
      canvas.drawImage(iconImage, Offset(iconX, iconY), paint);

      final finalImage = await recorder
          .endRecording()
          .toImage(originalImage.width, originalImage.height);

      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/watermarked_icon_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      print('Image with full watermark and icon saved to $filePath');

      return file;
    } catch (e) {
      print('Error in full-image watermark: $e');
      rethrow;
    }
  }

  void _showFilterOptions(BuildContext context) {
    selectedFilter = "Name"; // Default to 'Name' filter

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Content of the Bottom Sheet
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          color: Colors.grey[300],
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Row(
                                  children: const [
                                    Text("Name"),
                                  ],
                                ),
                                onTap: () {
                                  setModalState(() => selectedFilter = "Name");
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text("Group"),
                                onTap: () {
                                  setModalState(() => selectedFilter = "Group");
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text("Rate"),
                                onTap: () {
                                  setModalState(() => selectedFilter = "Rate");
                                },
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  selectedFilter ?? "Select Filter",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (selectedFilter == "Name")
                                _buildNameFilter(setModalState),
                              if (selectedFilter == "Group")
                                _buildGroupFilter(setModalState),
                              if (selectedFilter == "Rate")
                                _buildRateFilter(setModalState),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Done button at the bottom
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters(); // Apply the filters when clicked
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Call the function to apply filters after bottom sheet is closed
      // _applyFilters();
    });
  }

  Widget _buildNameFilter(StateSetter setModalState) {
    return Column(
      children: [
        _buildNameOption(setModalState, "A-Z"),
        _buildNameOption(setModalState, "A-E"),
        _buildNameOption(setModalState, "F-J"),
        _buildNameOption(setModalState, "K-O"),
        _buildNameOption(setModalState, "P-T"),
        _buildNameOption(setModalState, "U-Z"),
        const SizedBox(height: 10),
        // Custom Range Filter
        _buildCustomRangeFilter(setModalState),
      ],
    );
  }

  Widget _buildCustomRangeFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter Custom Range :",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRangeTextField(setModalState, 'Start'),
            ),
            const Text(' to '),
            Expanded(
              child: _buildRangeTextField(setModalState, 'End'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeTextField(StateSetter setModalState, String label) {
    return TextField(
      controller: label == 'Start' ? startRangeController : endRangeController,
      onChanged: (value) {
        setModalState(() {
          // Update filter range logic here
          startRange = startRangeController.text;
          endRange = endRangeController.text;
          _applyCustomRangeFilter(startRange, endRange);
        });
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  TextEditingController startRangeController = TextEditingController();
  TextEditingController endRangeController = TextEditingController();

  String startRange = "";
  String endRange = "";

  void _applyCustomRangeFilter(String startRange, String endRange) {
    setState(() {
      filteredData = filteredData.where((item) {
        final itemName = item.iMItemName;
        if (itemName != null) {
          final firstLetter = itemName[0].toUpperCase();
          return firstLetter.compareTo(startRange.toUpperCase()) >= 0 &&
              firstLetter.compareTo(endRange.toUpperCase()) <= 0;
        }
        return false;
      }).toList();
      print(
          "Filtered data by custom range: $filteredData"); // Debugging: Check filtered data
    });
  }

  Widget _buildNameOption(StateSetter setModalState, String nameRange) {
    return RadioListTile<String>(
      title: Text(nameRange),
      value: nameRange,
      groupValue: selectedNameRange,
      onChanged: (value) {
        setModalState(() {
          selectedNameRange =
              value ?? 'A-Z'; // Update with the selected name range
        });
      },
    );
  }

  void filterByName(String name) {
    setState(() {
      filteredData = filteredData.where((item) {
        final itemName = item.iMItemName;
        return itemName != null &&
            itemName.toLowerCase().contains(name.toLowerCase());
      }).toList();
      print(
          "Filtered data by name: $filteredData"); // Debugging: Check filtered data
    });
  }

  void filterByRange(String range) {
    setState(() {
      filteredData = filteredData.where((item) {
        final itemName = item.iMItemName;
        if (itemName != null) {
          final firstLetter = itemName[0].toUpperCase();
          return _isNameInRange(firstLetter, range);
        }
        return false;
      }).toList();
      print(
          "Filtered data by range: $filteredData"); // Debugging: Check filtered data
    });
  }

  bool _isNameInRange(String firstLetter, String range) {
    switch (range) {
      case 'A-E':
        return firstLetter.compareTo('A') >= 0 &&
            firstLetter.compareTo('E') <= 0;
      case 'F-J':
        return firstLetter.compareTo('F') >= 0 &&
            firstLetter.compareTo('J') <= 0;
      case 'K-O':
        return firstLetter.compareTo('K') >= 0 &&
            firstLetter.compareTo('O') <= 0;
      case 'P-T':
        return firstLetter.compareTo('P') >= 0 &&
            firstLetter.compareTo('T') <= 0;
      case 'U-Z':
        return firstLetter.compareTo('U') >= 0 &&
            firstLetter.compareTo('Z') <= 0;
      case 'A-Z':
      default:
        return true; // 'A-Z' means all items are included
    }
  }

  Widget _buildGroupFilter(StateSetter setModalState) {
    return Column(
      children: [
        // Dropdown for group selection
        DropdownButton<String>(
          value: groupFilter == '' ? '--Select--' : groupFilter,
          // Default to '--Select--'
          hint: Text('Select Group'),
          // Placeholder text
          isExpanded: true,
          // Makes dropdown take the full width
          items: [
            '--Select--',
            ...groupNames
          ] // Add '--Select--' at the top of the list
              .map((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setModalState(() {
              groupFilter = newValue ??
                  '--Select--'; // Set selected agent or '--Select--'
            });
          },
        ),
      ],
    );
  }

  Future<void> _fetchGroupNames() async {
    try {
      final response = await http.get(Uri.parse(
          '${globals.uriname}item_list.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            // Extract 'AgentName', remove duplicates, and sort in ascending order
            groupNames = data
                .where((item) =>
                    item['IM_GroupName'] != null &&
                    item['IM_GroupName'].isNotEmpty)
                .map((item) => item['IM_GroupName'] as String)
                .toSet()
                .toList();

            // Sort the agent names in ascending order
            groupNames.sort();

            // Ensure agentFilter is set to '--Select--' initially
            groupFilter = '--Select--';

            print('Fetched agent names: $groupNames');
          });
        } else {
          print('No agent names found in the API response.');
        }
      } else {
        print(
            'Failed to load agent names. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching agent names: $e');
    }
  }

  Widget _buildRateFilter(StateSetter setModalState) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Select Rate Range",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Container to control the width of the slider
        SizedBox(
          width: MediaQuery.of(context).size.width *
              0.8, // Adjust the width as needed
          child: RangeSlider(
            values: rateRange,
            min: 0,
            // Min value
            max: 1000,
            // Max value
            divisions: 100,
            // Adjust for finer granularity
            labels: RangeLabels(
              rateRange.start.round().toString(),
              rateRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              // Update the rateRange using setModalState
              setModalState(() {
                rateRange = values;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Selected Range: ₹${rateRange.start.toStringAsFixed(0)} - ₹${rateRange.end.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void filterByRate(RangeValues rateRange) {
    setState(() {
      filteredData = filteredData.where((item) {
        final itemRate = double.tryParse(item.iMSRate1.toString()) ?? 0.0;

        // Ensure the rate exists and falls within the selected range
        return itemRate >= rateRange.start && itemRate <= rateRange.end;
      }).toList();

      print(
          "Filtered data by rate: $filteredData"); // Debugging: Check filtered data
    });
  }

  void _applyFilters() {
    setState(() {
      // Start with full data
      filteredData = List.from(_items);

      // Apply Name Filter if selectedNameRange is not empty
      if (selectedNameRange.isNotEmpty) {
        filterByRange(selectedNameRange);
      }

      // Apply Custom Range Filter if custom range (startRange and endRange) is set
      if (startRange.isNotEmpty && endRange.isNotEmpty) {
        _applyCustomRangeFilter(
            startRange, endRange); // Call to apply custom range filter
      }

      if (groupFilter != '--Select--' && groupFilter.isNotEmpty) {
        filteredData = filteredData.where((item) {
          return item.iMGroupName == groupFilter;
        }).toList();
      }

      // Apply Rate Filter
      filterByRate(rateRange);

      print("Filtered Data after applying filters: $filteredData");
    });
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      p.join(await getDatabasesPath(), 'z_settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE z_settings(id INTEGER PRIMARY KEY, z_page TEXT, z_flag TEXT, z_keyword TEXT, z_keyvalue INTEGER, z_remarks TEXT)',
        );
      },
      version: 1,
    );
    await _loadSwitchOptions();
  }

  Future<void> _loadSwitchOptions() async {
    final List<Map<String, dynamic>> options = await _database
        .query('z_settings', where: 'z_page = ?', whereArgs: ['Item']);
    if (options.isEmpty) {
      // Insert default values if table is empty
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Group Name',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Item Code',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Diaplay Name',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Sales Rate',
        'z_keyvalue': 1,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Purchase Rate',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Unit',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'HSN Code',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      await _database.insert('z_settings', {
        'z_page': 'Item',
        'z_flag': '',
        'z_keyword': 'Barcode',
        'z_keyvalue': 0,
        'z_remarks': ''
      });
      _loadSwitchOptions();
    } else {
      setState(() {
        _switchOptions = options.map((item) {
          return {
            'id': item['id'],
            'z_page': item['z_page'],
            'z_flag': item['z_flag'],
            'z_keyword': item['z_keyword'],
            'z_keyvalue': item['z_keyvalue'],
            'z_remarks': item['z_remarks'],
          };
        }).toList();
      });
    }
  }

  void _showListSettings(BuildContext context) async {
    // Fetch data from the 'z_settings' table for the 'Supplier' page
    List<Map<String, dynamic>> settings = await _database.query(
      'z_settings',
      where: 'z_page = ?',
      whereArgs: ['Item'],
    );

    // Show the settings in a dialog with switches
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('List Settings'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: settings.map((option) {
                  return SwitchListTile(
                    title: Text(option['z_keyword']),
                    // Display the setting name (e.g., "GST No")
                    value: option['z_keyvalue'] == 1,
                    // ON/OFF based on z_keyvalue
                    onChanged: (value) async {
                      // Update the visibility in the database immediately
                      await _updateVisibility(option['id'], value);

                      // Reload the settings from the database to get the latest state
                      List<Map<String, dynamic>> updatedSettings =
                          await _database.query(
                        'z_settings',
                        where: 'z_page = ?',
                        whereArgs: ['Item'],
                      );

                      // Update the local settings state in the dialog
                      setState(() {
                        // Update the local list with the new values
                        settings =
                            updatedSettings; // Directly replace with the updated list
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                    // Customize the active color
                    inactiveThumbColor: Colors.grey,
                    // Customize the inactive thumb color
                    inactiveTrackColor:
                        Colors.grey, // Customize the inactive track color
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateVisibility(int id, bool value) async {
    // Update the setting visibility in the database
    await _database.update(
      'z_settings',
      {'z_keyvalue': value ? 1 : 0},
      // Set the visibility value based on the switch state
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadSwitchOptions();
  }

  @override
  void dispose() {
    _database.close();
    _scrollController.dispose();
    super.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
  }

  void _initializeSpeechRecognition() async {
    // bool available = await _speechToText.initialize();
    // if (!available) {
    //   print("Speech recognition is not available");
    // }
  }

  void _startListening() async {
    bool available = await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _voiceInput = result.recognizedWords;
          searchController.text = _voiceInput; // Update search field
          filteredData = _items.where((item) {
            return item.iMItemName!
                .toLowerCase()
                .contains(_voiceInput.toLowerCase());
          }).toList();
        });
      },
      listenFor: Duration(seconds: 10), // How long to listen for
      localeId: 'en_US', // Adjust language locale if necessary
    );
    if (!available) {
      print("Speech recognition not available");
    }
  }

  void _requestPermissions() async {
    // Request microphone and storage permissions
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      print("Microphone permission granted");
    } else {
      print("Microphone permission denied");
    }
  }

  Future<void> _openCameras(String? itemid) async {
    if (itemid == null || itemid.isEmpty) {
      print("Error: itemid is null or empty");
      return;
    }

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _images.clear();
          _images.add(_image!); // Add to list
        });

        print("Image Captured at Path: ${_image!.path}");

        // Call upload function with the itemid
        await _uploadImage(itemid);
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> _uploadImage(String itemid) async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No images to upload.")),
      );
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final clientcode = globals.clientcode;
    final cmpcode = globals.cmpcode;
    final itemDir =
        path.join(appDir.path, clientcode, cmpcode, 'Images', 'Items');

    // Ensure the directory exists
    await Directory(itemDir).create(recursive: true);

    int nextIndex = _nextIndex;
    String fileName, savedImagePath;

    while (true) {
      fileName = '${itemid}_$nextIndex.jpg';
      savedImagePath = path.join(itemDir, fileName);

      if (File(savedImagePath).existsSync()) {
        nextIndex++;
        if (nextIndex > 1000) break; // Avoid infinite loop
      } else {
        break;
      }
    }

    print("Saving image at: $savedImagePath");

    for (var image in _images) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              "${globals.uriname}upload_image.php?clientcode=$clientcode&cmp=$cmpcode"),
        );

        request.fields['IM_ItemId'] = itemid;
        request.fields['index'] = nextIndex.toString();

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: fileName,
        ));

        var response = await request.send();

        if (response.statusCode == 200) {
          String responseBody = await response.stream.bytesToString();
          final responseData = json.decode(responseBody);

          if (responseData['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image uploaded successfully!")),
            );

            await image.copy(savedImagePath);
            print("Image saved locally at: $savedImagePath");

            setState(() {
              _nextIndex = nextIndex + 1;
              _images.clear();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Failed to upload image: ${responseData['message']}")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image.")),
          );
        }
      } catch (e) {
        print("Error uploading and saving image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<File> downloadImageWithWatermark(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image');
    }

    final Uint8List originalBytes = response.bodyBytes;
    final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    canvas.drawImage(originalImage, ui.Offset.zero, paint);

    const watermarkText = 'WATERMARK';
    final textStyle = ui.TextStyle(
      color: ui.Color.fromARGB(100, 255, 0, 0),
      fontSize: 50,
      fontWeight: ui.FontWeight.bold,
    );

    final textSpan = ui.TextSpan(text: watermarkText, style: TextStyle());
    final textPainter = ui.TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final stepX = textPainter.width + 60;
    final stepY = textPainter.height + 60;

    for (double y = -originalImage.height.toDouble();
        y < originalImage.height;
        y += stepY) {
      for (double x = -originalImage.width.toDouble();
          x < originalImage.width * 2;
          x += stepX) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.4);
        textPainter.paint(canvas, ui.Offset.zero);
        canvas.restore();
      }
    }

    final watermarkedImage = await recorder
        .endRecording()
        .toImage(originalImage.width, originalImage.height);
    final byteData =
        await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/watermarked_${imageUrl.split('/').last}';
    final file = File(filePath);

    await file.writeAsBytes(pngBytes);
    return file;
  }

  Future<File> downloadPlainImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image');
    }

    final Uint8List imageBytes = response.bodyBytes;
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${imageUrl.split('/').last}';
    final file = File(filePath);

    await file.writeAsBytes(imageBytes);
    return file;
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
                    setState(() {
                      filteredData = _items.where((item) {
                        return item.iMItemName!
                            .toLowerCase()
                            .contains(value.toLowerCase());
                      }).toList();
                    });
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
            : const Text('Item'),
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
          if (_isSearching)
            IconButton(
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              onPressed: () async {
                if (_isListening) {
                  _speechToText.stop();
                } else {
                  _startListening();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_selectedItemIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No items selected to share')),
                );
                return;
              }

              bool withWatermark = false;
              bool withCompanyIcon = false;
              bool plainImage = true;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return SafeArea(
                        child: SingleChildScrollView(
                          padding: MediaQuery.of(context).viewInsets,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Choose Sharing Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CheckboxListTile(
                                  title: const Text("Share Image (Plain)"),
                                  value: plainImage,
                                  onChanged: (value) {
                                    setState(() {
                                      plainImage = value!;
                                      if (plainImage) {
                                        withWatermark = false;
                                        withCompanyIcon = false;
                                      }
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title:
                                      const Text("Share Image with Watermark"),
                                  value: withWatermark,
                                  onChanged: (value) {
                                    setState(() {
                                      withWatermark = value!;
                                      if (withWatermark || withCompanyIcon) {
                                        plainImage = false;
                                      } else if (!withWatermark &&
                                          !withCompanyIcon) {
                                        plainImage = true;
                                      }
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text(
                                      "Share Image with Company Icon"),
                                  value: withCompanyIcon,
                                  onChanged: (value) {
                                    setState(() {
                                      withCompanyIcon = value!;
                                      if (withWatermark || withCompanyIcon) {
                                        plainImage = false;
                                      } else if (!withWatermark &&
                                          !withCompanyIcon) {
                                        plainImage = true;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(
                                        context); // Close the bottom sheet

                                    List<File> selectedFiles = [];

                                    for (var itemId in _selectedItemIds) {
                                      final item = _items.firstWhere(
                                        (item) =>
                                            item.iMItemId!.toString() == itemId,
                                      );

                                      final imageUrl =
                                          '${globals.uriname}${globals.clientcode}/${globals.xyz}/Images/Items/${item.iMItemId}_1.jpg';

                                      try {
                                        File file;

                                        // Priority: Watermark + Icon > Watermark > Icon > Plain
                                        if (withWatermark && withCompanyIcon) {
                                          print(
                                              'Downloading with both watermark and company icon');
                                          file =
                                              await downloadImageWithWatermarkAndCompanyIcon(
                                                  imageUrl);
                                        } else if (withWatermark) {
                                          print(
                                              'Downloading with watermark only');
                                          file =
                                              await downloadImageWithWatermark(
                                                  imageUrl);
                                        } else if (withCompanyIcon) {
                                          print(
                                              'Downloading with company icon only');
                                          file =
                                              await downloadImageWithCompanyIcon(
                                                  imageUrl);
                                        } else if (plainImage) {
                                          print('Downloading plain image');
                                          file = await downloadPlainImage(
                                              imageUrl);
                                        } else {
                                          print('No valid option selected');
                                          throw Exception(
                                              'No sharing option selected.');
                                        }

                                        selectedFiles.add(file);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    }

                                    if (selectedFiles.isNotEmpty) {
                                      await Share.shareFiles(
                                        selectedFiles
                                            .map((file) => file.path)
                                            .toList(),
                                        text: 'Check out these items!',
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'No valid images to share')),
                                      );
                                    }
                                  },
                                  child: const Text("Share"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              _showFilterOptions(context);
            },
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 1) {
                _showListSettings(
                    context); // When List Settings is selected, open it
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 1,
                child: Text('List Settings'), // This opens the data list
              ),
            ],
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
                    children: _selectedItemIds.map((itemId) {
                      final selectedItem = _items.firstWhere(
                        (item) => item.iMItemId!.toString() == itemId,
                      );

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
                                    '${globals.uriname}${globals.clientcode}/${globals.xyz}/Images/Items/${selectedItem.iMItemId}_1.jpg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/icons/00000000.jpg',
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
                                    selectedItem.iMItemName ?? 'Unknown',
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
                                icon: const Icon(Icons.close, size: 12),
                                padding: const EdgeInsets.all(0),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _selectedItemIds.remove(itemId);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                errorMessage != null
                    ? Center(
                        child: Text(
                        errorMessage!,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ))
                    : GridView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columnCount,
                          childAspectRatio: _getChildAspectRatio(),
                        ),
                        itemCount: filteredData.isNotEmpty
                            ? filteredData.length
                            : _items.length,
                        itemBuilder: (context, index) {
                          var item = filteredData.isNotEmpty
                              ? filteredData[index]
                              : _items[index];
                          return _buildItemCard(item);
                        },
                      ),
                isLoading ? const Center(child: CustomLoader()) : Container(),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showLayoutSelection(context);
        },
        child: const Icon(Icons.grid_view),
      ),
    );
  }

  // Function to get aspect ratio based on layout
  double _getChildAspectRatio() {
    // if (_columnCount == 1) return 2;
    // if (_columnCount == 2) return 1;
    // return 0.75;
    if (_columnCount == 1) return 2; // widescreen layout
    if (_columnCount == 2) return .8; // slightly taller
    return 0.75; // Tall rectangle
  }

// Function to show bottom sheet with layout options
  void _showLayoutSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _layoutIcon(Icons.view_agenda, 1),
              _layoutIcon(Icons.grid_view, 2),
              _layoutIcon(Icons.view_module, 3),
            ],
          ),
        );
      },
    );
  }

  // Widget to create layout selection icons
  Widget _layoutIcon(IconData icon, int columns) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _columnCount = columns;
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Icon(icon,
              size: 40,
              color: _columnCount == columns ? Colors.blue : Colors.grey),
          Text('$columns Column${columns > 1 ? 's' : ''}'),
        ],
      ),
    );
  }

  // Different designs for different layouts
  Widget _buildItemCard(ItemModel item) {
    switch (_columnCount) {
      case 1:
        return _buildSingleColumnCard(item);
      case 2:
        return _buildTwoColumnCard(item);
      case 3:
      default:
        return _buildThreeColumnCard(item);
    }
  }

  Widget _buildSingleColumnCard(ItemModel item) {
    final String itemId = item.iMItemId!.toString();
    final bool isSelected = _selectedItemIds.contains(itemId);

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Column
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedItemIds.remove(itemId);
                        } else {
                          _selectedItemIds.add(itemId);
                        }
                      });
                    },
                    child: SizedBox(
                      width: 100,
                      height: 80,
                      child: _buildImage(item),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                ' ${item.iMItemName ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (_isFieldVisible('Group Name'))
                                Text(
                                  ' (${item.iMGroupName ?? "N/A"})',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                        if (_isFieldVisible('Item Code'))
                          Text(
                            'Code: ${item ?? "N/A"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('Display Name'))
                          Text(
                            'Display Name: ${item.iMItemAlias ?? "N/A"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('Sales Rate'))
                          Text(
                            'Sales Rate: ${item.iMSRate1 ?? "0.0"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('Purchase Rate'))
                          Text(
                            'Purchase Rate: ${item.iMPRate1 ?? "0.0"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('Unit'))
                          Text(
                            'Unit: ${item.uMUnitCode ?? "N/A"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('HSN Code'))
                          Text(
                            'HSN: ${item.iMHSNCode ?? "0.0"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (_isFieldVisible('Barcode'))
                          Text(
                            'Barcode: ${item.iMExtra5 ?? "0.0"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 📸 Camera Icon
        Positioned(
          top: 28,
          right: 6,
          child: InkWell(
            onTap: () {
              _openCameras(itemId);
            },
            child: const Icon(Icons.camera_alt, size: 22, color: Colors.grey),
          ),
        ),

        // ✅ Show Check Icon if selected
        if (isSelected)
          Positioned(
            top: 0,
            bottom: 0,
            right: 4,
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 12,
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),

        // ✅ Show Company Logo when selected
        if (isSelected)
          Positioned(
            bottom: 4,
            left: 9,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.yellow, // use a visible color temporarily
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: Colors.black), // <- highlight position
              ),
              child: Image.asset(
                'assets/images/icons/app_icon.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTwoColumnCard(ItemModel item) {
    final String itemId = item.iMItemId!.toString();
    final bool isSelected = _selectedItemIds.contains(itemId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItemIds.remove(itemId);
          } else {
            _selectedItemIds.add(itemId);
          }

          selectionMode = _selectedItemIds.isNotEmpty;
        });
      },
      child: Stack(
        children: [
          // Card with watermark background if selected
          Stack(
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with overlay watermark and icon
                    Expanded(
                      child: Stack(
                        children: [
                          _buildImage(item),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.iMItemName ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (_isFieldVisible('Group Name'))
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          '(${item.iMGroupName ?? "N/A"})',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_isFieldVisible('Item Code'))
                      Text(
                        'Code: ${item.iMItemCode ?? "N/A"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('Display Name'))
                      Text(
                        'Display Name: ${item.iMItemAlias ?? "N/A"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('Sales Rate'))
                      Text(
                        'Sales Rate: ${item.iMSRate1 ?? "0.0"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('Purchase Rate'))
                      Text(
                        'Purchase Rate: ${item.iMPRate1 ?? "0.0"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('Unit'))
                      Text(
                        'Unit: ${item.uMUnitCode ?? "N/A"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('HSN Code'))
                      Text(
                        'HSN: ${item.iMHSNCode ?? "0.0"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    if (_isFieldVisible('Barcode'))
                      Text(
                        'Barcode: ${item.iMExtra5 ?? "0.0"}',
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),

              // Full-card watermark when selected
            ],
          ),

          // Camera icon
          Positioned(
            top: 28,
            right: 6,
            child: InkWell(
              onTap: () {
                _openCameras(itemId);
              },
              child: const Icon(Icons.camera_alt, size: 22, color: Colors.grey),
            ),
          ),

          // Company icon top-left when selected
          if (isSelected)
            Positioned(
              top: 4, // Position from the top
              bottom: 0, // Position from the bottom
              right: 4, // Position from the right
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 12,
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThreeColumnCard(ItemModel item) {
    final String itemId = item.iMItemId!.toString();
    final bool isSelected = _selectedItemIds.contains(itemId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItemIds.remove(itemId);
          } else {
            _selectedItemIds.add(itemId);
          }

          // Enable selection mode if any item is selected
          selectionMode = _selectedItemIds.isNotEmpty;
        });
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  SizedBox(height: 60, child: _buildImage(item)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            item.iMItemName!,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isFieldVisible('Group Name'))
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              '(${item.iMGroupName ?? "N/A"})',
                              // Added parentheses
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isFieldVisible('Item Code'))
                    Text(
                      'Code: ${item.iMItemCode ?? "N/A"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('Display Name'))
                    Text(
                      'Display Name: ${item.iMItemAlias ?? "N/A"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('Sales Rate'))
                    Text(
                      'Sales Rate: ${item.iMSRate1 ?? "0.0"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('Purchase Rate'))
                    Text(
                      'Purchase Rate: ${item.iMPRate1 ?? "0.0"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('Unit'))
                    Text(
                      'Unit: ${item.uMUnitCode ?? "N/A"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('HSN Code'))
                    Text(
                      'HSN: ${item.iMHSNCode ?? "0.0"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (_isFieldVisible('Barcode'))
                    Text(
                      'Barcode: ${item.iMExtra5 ?? "0.0"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 6,
            child: InkWell(
              onTap: () {
                // Handle camera click action
                _openCameras(itemId); // Pass the item
              },
              child: const Icon(Icons.camera_alt, size: 22, color: Colors.grey),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 4, // Position from the top
              bottom: 0, // Position from the bottom
              right: 4, // Position from the right
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 12,
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

// Sample image function to display item images
  Widget _buildImage(ItemModel item) {
    String imageUrl =
        '${globals.uriname}${globals.clientcode}/${globals.xyz}/Images/Items/${item.iMItemId}_1.jpg';

    print("Image URL: $imageUrl"); // Debugging line

    return GestureDetector(
      onTap: () {
        // Navigate to the other page when the image is tapped
      },
      child: Container(
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Image.network(
          '${globals.uriname}${globals.clientcode}/${globals.xyz}/Images/Items/${item.iMItemId}_1.jpg',
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/images/icons/00000000.jpg',
                fit: BoxFit.contain);
          },
        ),
      ),
    );
  }
}

class PhotoViewPage extends StatelessWidget {
  final String imageUrl;
  final String itemname;

  const PhotoViewPage(
      {super.key, required this.imageUrl, required this.itemname});

  // Function to download the image and return the local file path
  Future<File> _downloadImage(String url) async {
    // Get the directory to save the image
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/image.jpg'; // Save as .jpg

    // Download the image from the network
    final response = await http.get(Uri.parse(url));

    // Write the image to the file
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemname),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              // Download the image
              final file = await _downloadImage(imageUrl);

              // Share the image
              Share.shareFiles([file.path]);
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoViewGallery.builder(
          itemCount: 1,
          // If you have more images, increase this number
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(color: Colors.black),
          pageController: PageController(),
        ),
      ),
    );
  }
}
