import 'package:flutter/material.dart';
import 'dart:convert';
import 'globals.dart' as globals;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FullScreenImage extends StatefulWidget {
  final String imagePath;
  final Function(File) onRetake; // The callback to return the updated image

  const FullScreenImage({
    super.key,
    required this.imagePath,
    required this.onRetake,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late File _currentImage;
  final int _textPosition = 2; // Default to top-center
bool _showTextOverlay = false;


  @override
  void initState() {
    super.initState();
    _currentImage = File(widget.imagePath);
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImage.path,
      aspectRatio:
          const CropAspectRatio(ratioX: 1, ratioY: 1), // Adjust as needed
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentImage = File(croppedFile.path);
      });
    }
  }

  Future<void> _retakeImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? newImage = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1080,
                    maxHeight: 1080,
                  );
                  if (newImage != null) {
                    setState(() {
                      _currentImage = File(newImage.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? newImage = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1080,
                    maxHeight: 1080,
                  );
                  if (newImage != null) {
                    setState(() {
                      _currentImage = File(newImage.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveImage() {
    widget.onRetake(_currentImage); // Pass the cropped image back to the parent
    Navigator.of(context).pop();
  }

  void _shareImage() {
    try {
      Share.shareXFiles(
        [XFile(_currentImage.path)],
      );
    } catch (error) {
      // Handle any errors that occur during the sharing process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
Future<void> _mergeImageAtPosition(int position) async {
  try {
    // Fetch overlay image from API
    final response = await http.get(Uri.parse('https://abm99.amisys.in/logo.jpg'));

    if (response.statusCode == 200) {
      Uint8List overlayBytes = response.bodyBytes; // Convert response body to Uint8List

      // Decode overlay image
      img.Image? overlay = img.decodeImage(overlayBytes);
      if (overlay == null) throw Exception("Failed to decode overlay image.");

      // Read the original image
      Uint8List originalBytes = await _currentImage.readAsBytes();
      img.Image? original = img.decodeImage(originalBytes);
      if (original == null) throw Exception("Failed to decode original image.");

      // Resize overlay to fit a portion of the original image (adjust size if needed)
      overlay = img.copyResize(overlay, width: original.width ~/ 4, height: original.height ~/ 4);

      // Determine position based on the input number
      int dstX = 0, dstY = 0;
      switch (position) {
        case 1: // Top Left
          dstX = 0;
          dstY = 0;
          break;
        case 2: // Top Center
          dstX = (original.width - overlay.width) ~/ 2;
          dstY = 0;
          break;
        case 3: // Top Right
          dstX = original.width - overlay.width;
          dstY = 0;
          break;
        case 4: // Middle Left
          dstX = 0;
          dstY = (original.height - overlay.height) ~/ 2;
          break;
        case 5: // Middle Center
          dstX = (original.width - overlay.width) ~/ 2;
          dstY = (original.height - overlay.height) ~/ 2;
          break;
        case 6: // Middle Right
          dstX = original.width - overlay.width;
          dstY = (original.height - overlay.height) ~/ 2;
          break;
        case 7: // Bottom Left
          dstX = 0;
          dstY = original.height - overlay.height;
          break;
        case 8: // Bottom Center
          dstX = (original.width - overlay.width) ~/ 2;
          dstY = original.height - overlay.height;
          break;
        case 9: // Bottom Right
          dstX = original.width - overlay.width;
          dstY = original.height - overlay.height;
          break;
        default:
          throw Exception("Invalid position value. Use 1 to 9.");
      }

      // Merge overlay onto original image
      img.Image mergedImage = img.compositeImage(original, overlay, dstX: dstX, dstY: dstY);

      // Save merged image temporarily
      final mergedFilePath = _currentImage.path.replaceFirst('.jpg', '_merged.jpg');
      File mergedFile = File(mergedFilePath);
      await mergedFile.writeAsBytes(img.encodeJpg(mergedImage));

      // Update the displayed image
      setState(() {
        _currentImage = mergedFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image merged at position $position successfully!")),
      );
    } else {
      throw Exception("Failed to fetch overlay image from API.");
    }
  } catch (e) {
    print("Error merging image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error merging image: $e")),
    );
  }
}
Future<void> _addTextToImageAndSave(File imageFile, String overlayText) async {
  try {
    // Read the original image
    Uint8List originalBytes = await imageFile.readAsBytes();
    img.Image? original = img.decodeImage(originalBytes);
    if (original == null) throw Exception("Failed to decode original image.");

    // Define the text position
    int textX = original.width ~/ 2 - 100;
    int textY = (_textPosition == 1)
        ? original.height ~/ 5
        : (_textPosition == 2)
            ? original.height - (original.height ~/ 5)
            : original.height ~/ 2;

    // Define color (red color in this case)
    // final textColor = img.ColorInt8.rgb(255, 0, 0);
    // img.drawString(original, text,
    //  font: img.arial24,
    //   x: dstX, 
    //   y: dstY, 
    // color: textColor);
    final textColor = img.ColorInt8.rgb(255, 0, 0);

    // Draw the text string on the image
    img.drawString(original, font: img.arial24, x: textX, y: textY, overlayText, color: textColor);

    // Save the modified image
    final modifiedFilePath = imageFile.path.replaceFirst('.jpg', '_text.jpg');
    File modifiedFile = File(modifiedFilePath);
    await modifiedFile.writeAsBytes(img.encodeJpg(original));

    // Update the _currentImage to the modified image with text
    setState(() {
      _currentImage = modifiedFile;
      _showTextOverlay = false; // Hide overlay after saving
    });
  } catch (e) {
    throw Exception("Failed to add text to image: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: 1,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(_currentImage),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: PageController(),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareImage,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: _cropImage,
              child: const Text('Crop'),
            ),
          ),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.5 -
                50, // Center horizontally
            child: ElevatedButton(
              onPressed: _retakeImage,
              child: const Text('Retake'),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _saveImage,
              child: const Text('Save'),
            ),
          ),
          Positioned(
              bottom: 70, // Adjust positioning as needed
              right: 20,
              child: ElevatedButton(
                onPressed: () => _mergeImageAtPosition(3), // Use a lambda function
                child: const Text('Merge'),
              ),
            ),
            Positioned(
                  bottom: 70, // Adjust positioning as needed
                  right: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showTextOverlay = true;
                        _addTextToImageAndSave(_currentImage, "Your Overlay Text");
                      });
                    },
                    
                    child: const Text('Text'),
                  ),
                ),
        if (_showTextOverlay)
  Positioned(
    top: _textPosition == 1 ? MediaQuery.of(context).size.height * 0.2 : null,
    bottom: _textPosition == 2 ? MediaQuery.of(context).size.height * 0.2 : null,
    left: MediaQuery.of(context).size.width * 0.5 - 100, // Center horizontally
    child: GestureDetector(
      onTap: () {
        setState(() {
          _showTextOverlay = false; // Hide text on tap
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.black54, // Semi-transparent background
        child: Text(
          'Your Overlay Text',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
      ),
    ),
  ),

        ],
      ),
    );
  }
}

class ItemDetail extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itemid;
  final String itemname;

  const ItemDetail({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itemid,
    required this.itemname,
  });

  @override
  State<ItemDetail> createState() => _ItemDetailState();
}

class _ItemDetailState extends State<ItemDetail> {
  List userData = [];
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  XFile? _pickedFile;
  final List<File> _images = [];
  List<bool> _selectedImages = [];
  final int _nextImageIndex = 1;
  int _nextIndex = 1; // Default to 1 if no images exist yet

  @override
  void initState() {
    super.initState();

    // If getRecord() is async, use async initialization
    getRecord(); // If getRecord() doesn't need to wait before loading images

    // Ensure itemid is valid and load images
    if (widget.itemid.isNotEmpty) {
      _loadExistingImages(widget.itemid);
    } else {
      print("Error: itemid is null or empty.");
    }
  }

  Future<void> getRecord() async {
    String uri =
        "${globals.uriname}item_read.php?IM_ItemId=${widget.itemid}&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";
    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body); // Decode the JSON response
        } catch (e) {
          print('JSON decoding error: $e');
          return; // Early return on error
        }

        // Check if the response is a list
        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse; // Update userData state
            // Initialize controllers based on userData length
            _controllers.clear(); // Clear previous controllers
            for (var item in userData) {
              _controllers
                  .add(TextEditingController(text: item["IM_ItemId"] ?? "N/A"));
              _controllers.add(
                  TextEditingController(text: item["IM_ItemCode"] ?? "N/A"));
              _controllers.add(
                  TextEditingController(text: item["IM_ItemName"] ?? "N/A"));
              _controllers.add(
                  TextEditingController(text: item["IM_ItemAlias"] ?? "N/A"));
              _controllers.add(
                  TextEditingController(text: item["IM_GroupName"] ?? "N/A"));
            }
          });
        } else {
          print('Unexpected response format: ${jsonResponse.runtimeType}');
        }
      } else {
        print(
            'Request failed with status: ${response.statusCode}'); // Handle non-200 responses
      }
    } catch (e) {
      print('Request error: $e'); // Handle request errors
    }
  }

  Future<void> _loadExistingImages(String itemid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final clientcode = globals.clientcode;
    final cmpcode = globals.cmpcode;
    // final itemDir = path.join(appDir.path, 'Images', username, 'Items');
    final itemDir =
        path.join(appDir.path, clientcode, cmpcode, 'Images', 'Items');

    final directory = Directory(itemDir);
    if (directory.existsSync()) {
      final imageFiles = directory
          .listSync()
          .where((file) =>
              file.path.contains('${itemid}_') && file.path.endsWith('.jpg'))
          .map((file) => File(file.path))
          .toList();

      int highestIndex = 0;

      // Get the highest existing index from the saved images
      for (var file in imageFiles) {
        final fileName = path.basename(file.path);
        final indexStr = fileName.split('_').last.replaceAll('.jpg', '');
        final index = int.tryParse(indexStr) ?? 0;
        if (index > highestIndex) {
          highestIndex = index;
        }
      }

      setState(() {
        // Add the images to the list to display them
        _images.addAll(imageFiles);
        _selectedImages = List.generate(_images.length, (index) => false);
        _nextIndex = highestIndex + 1; // Set the next index for the new images
      });
    } else {
      print("Directory does not exist for itemid $itemid");
    }
  }
 Future<void> _saveImagesToCloudAndDevice(String itemid) async {
    if (_images.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final clientcode = globals.clientcode;
      final cmpcode = globals.cmpcode;
      final itemDir =
          path.join(appDir.path, clientcode, cmpcode, 'Images', 'Items');

      // Ensure the directory exists
      final directory = await Directory(itemDir).create(recursive: true);

      int nextIndex = _nextIndex;
      print(nextIndex);

      String fileName;
      String savedImagePath;
      while (true) {
        fileName = '${itemid}_$nextIndex.jpg';
        savedImagePath = path.join(directory.path, fileName);

        if (File(savedImagePath).existsSync()) {
          // Skip this image since it already exists
          nextIndex++;
          continue;
        } else {
          break;
        }
      }

      print(savedImagePath);

      for (int i = 0; i < _images.length; i++) {
        var image = _images[i];
        try {
          // Step 1: Upload the image to the cloud
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
                "${globals.uriname}upload_image.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
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

              // Save the image locally at the app folder
              await image.copy(savedImagePath);

              print("Image saved locally at: $savedImagePath");
                
              // Increment the index for the next image
              // nextIndex++;

              // Update the next index in the state
              setState(() {
                _nextIndex = nextIndex;
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No images to upload.")),
      );
    }
  }
Future<void> updateImage(String savedImagePath, String itemid, int index) async {
  final clientcode = globals.clientcode;
  final cmpcode = globals.cmpcode;

  try {
    // Update the image on the server
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${globals.uriname}update_image.php?IM_ItemId=$itemid&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
    );

    request.fields['IM_ItemId'] = itemid;
    request.fields['index'] = index.toString();

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      savedImagePath,
      filename: "${itemid}_$index.jpg",
    ));

    var response = await request.send();
    String responseBody = await response.stream.bytesToString();

    final responseData = json.decode(responseBody);

    if (response.statusCode == 200 && responseData['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image updated successfully!")),
      );

      // Step to update image locally on the device
      final appDir = await getApplicationDocumentsDirectory();
      final itemDir =
          path.join(appDir.path, clientcode, cmpcode, 'Images', 'Items');
      final localImagePath = path.join(itemDir, "${itemid}_$index.jpg");

      // Overwrite the local image with the new image path
      await File(savedImagePath).copy(localImagePath);

      print("Image updated locally at: $localImagePath");

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Failed to update image: ${responseData['message']}")),
      );
    }
  } catch (e) {
    print("Error uploading image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
// Helper function to get the current number of images for this item
  Future<int> _getCurrentImageIndex(String itemid, Directory directory) async {
    try {
      final imageFiles = directory
          .listSync()
          .where((file) =>
              file.path.contains(itemid) && file.path.endsWith('.jpg'))
          .toList();

      return imageFiles
          .length; // Return the number of images already saved for this item
    } catch (e) {
      print("Error getting current image index: $e");
      return 0; // If error, assume no images saved yet
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Capture Image'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _openGallery();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCamera() async {
    await Permission.camera.request(); // Request camera permission

    if (await Permission.camera.isGranted) {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera); // Pick an image from the camera
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        // Check if the file is a .jpg or .jpeg
        if (!pickedFile.path.endsWith('.jpg') &&
            !pickedFile.path.endsWith('.jpeg')) {
          _showConvertDialog(imageFile);
        } else {
          // Check file size (limit to 2MB)
          await _checkFileSizeAndProcess(imageFile);
        }
      }
    } else {
      // If permission is denied, show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission denied")),
      );
    }
  }

  Future<void> _openGallery() async {
    await Permission.storage.request(); // Request storage permission

    if (await Permission.storage.isGranted) {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery); // Pick an image from the gallery

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        // Check if the file is a .jpg or .jpeg
        if (!pickedFile.path.endsWith('.jpg') &&
            !pickedFile.path.endsWith('.jpeg')) {
          _showConvertDialog(imageFile);
        } else {
          // Check file size (limit to 2MB)
          await _checkFileSizeAndProcess(imageFile);
        }
      }
    } else {
      // If permission is denied, show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery permission denied")),
      );
    }
  }

  void _showConvertDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Convert Image'),
          content: const Text(
              'The selected file is not a JPG or JPEG image. Would you like to convert it to JPG?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                await _convertToJpg(imageFile);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _convertToJpg(File imageFile) async {
    try {
      // Load the image
      final image = img.decodeImage(imageFile.readAsBytesSync());

      if (image != null) {
        // Convert to JPG
        final jpgImage = img.encodeJpg(image);

        // Create a new file with .jpg extension
        final newFile =
            File(imageFile.path.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '.jpg'));
        await newFile.writeAsBytes(jpgImage);

        // Process the new JPG file
        await _checkFileSizeAndProcess(newFile);
      }
    } catch (e) {
      print("Error converting to JPG: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to convert image to JPG.")),
      );
    }
  }

  Future<void> _checkFileSizeAndProcess(File imageFile) async {
    // Check file size (limit to 2MB)
    final fileSize = await imageFile.length();

    if (fileSize > 5 * 1024 * 1024) {
      // If the file size is greater than 2MB, show a dialog asking to reduce size
      _showReduceSizeDialog(imageFile);
    } else {
      // If the file size is valid, add the image to the list
      setState(() {
        _images.add(imageFile);
        _selectedImages.add(false);
      });

      // Call the function to save the images to cloud and device
      await _saveImagesToCloudAndDevice(widget.itemid);
    }
  }

  void _showReduceSizeDialog(File imageFile) {
    // Get the file size in bytes
    final int fileSizeInBytes = imageFile.lengthSync();

    // Convert bytes to megabytes
    final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reduce Image Size'),
          content: Text(
              'The file size is ${fileSizeInMB.toStringAsFixed(2)} MB and exceeds 5MB. '
              'Would you like to reduce the size to under 5MB?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                await _reduceImageSize(imageFile);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reduceImageSize(File imageFile) async {
    try {
      final image = img.decodeImage(imageFile.readAsBytesSync());

      if (image != null) {
        // Resize image to reduce size to less than 2MB
        const maxSize = 5 * 1024 * 1024; // 2MB
        int quality = 100;
        List<int> resizedImage = img.encodeJpg(image, quality: quality);
        while (resizedImage.length > maxSize && quality > 10) {
          quality -= 5; // Reduce quality until the image is under 5MB
          resizedImage = img.encodeJpg(image, quality: quality);
        }

        // Create a new file with the reduced size
        final newFile = File(imageFile.path
            .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '_reduced.jpg'));
        await newFile.writeAsBytes(resizedImage);

        // Process the reduced size image
        setState(() {
          _images.add(newFile);
          _selectedImages.add(false);
        });

        // Call the function to save the images to cloud and device
        await _saveImagesToCloudAndDevice(widget.itemid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image size reduced and saved.")),
        );
      }
    } catch (e) {
      print("Error reducing image size: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to reduce image size.")),
      );
    }
  }

  // This function is used to replace the original image with the cropped image
  void _replaceImageWithCropped(File croppedImage, int index) {
    setState(() {
      _images[index] = croppedImage; // Replace the image at the given index
      _selectedImages[index] = false; // Unselect the image
    });
  }

  void _cancelSelection() {
    setState(() {
      for (int i = 0; i < _selectedImages.length; i++) {
        _selectedImages[i] = false;
      }
    });
  }
Future<void> _deleteSelectedImages() async {
  List<Map<String, String>> filesToDelete = [];
  bool hasLocalDeletionError = false;

  // Get the application documents directory
  final appDir = await getApplicationDocumentsDirectory();
  final clientcode = globals.clientcode;
  final cmpcode = globals.cmpcode;
  final itemDir = path.join(appDir.path, clientcode, cmpcode, 'Images', 'Items');

  // Iterate through selected images
  for (int idx = 0; idx < _selectedImages.length; idx++) {
    if (_selectedImages[idx]) {
      final filePath = path.join(itemDir, '${widget.itemid}_${idx + 1}.jpg');
      final imageFile = File(filePath);

      try {
        // Delete file from local storage
        if (await imageFile.exists()) {
          await imageFile.delete();
          print("File deleted locally: $filePath");

          // Prepare the data for server request after successful local deletion
          filesToDelete.add({
            'IM_ItemId': widget.itemid,
            'index': (idx + 1).toString(),
          });
        } else {
          print("File not found locally: $filePath");
        }
      } catch (e) {
        print("Error deleting image locally: $e");
        hasLocalDeletionError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting image locally: $e")),
        );
      }
    }
  }

  // Proceed to server deletion only if no errors occurred during local deletion
  if (filesToDelete.isNotEmpty && !hasLocalDeletionError) {
    try {
      // Send a request to delete from server
      var response = await http.post(
        Uri.parse("${globals.uriname}delete_image.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
        body: {'files': json.encode(filesToDelete)},
      );

      if (response.statusCode == 200) {
        String responseBody = response.body;

        // Check for concatenated JSON objects and handle them
        var jsonObjects = responseBody.split('}{');
        if (jsonObjects.length > 1) {
          jsonObjects = jsonObjects.map((e) => e.contains('{') ? e : '{$e').toList();
          jsonObjects = jsonObjects.map((e) => e.contains('}') ? e : '$e}').toList();
        }

        for (var jsonObject in jsonObjects) {
          try {
            var jsonResponse = json.decode(jsonObject);

            if (jsonResponse['status'] == 'success') {
              print('Image deleted from server successfully: ${jsonResponse['message']}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Image deleted successfully!")),
              );

              // Update the UI after successful deletion
              setState(() {
                for (int idx = 0; idx < _selectedImages.length; idx++) {
                  if (_selectedImages[idx]) {
                    _images.removeAt(idx);
                    _selectedImages.removeAt(idx);
                    idx--; // Adjust index after removal
                  }
                }
              });
            } else {
              print('Failed to delete image on server: ${jsonResponse['message']}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Server deletion failed: ${jsonResponse['message']}")),
              );
            }
          } catch (e) {
            print('Error parsing JSON object: $e');
          }
        }
      } else {
        print('Failed to delete image(s) from server');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete image(s) from server.")),
        );
      }
    } catch (e) {
      print('Error while making server request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: $e")),
      );
    }
  } else if (!hasLocalDeletionError) {
    print('No files selected for deletion or already deleted locally');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No files selected for deletion.")),
    );
  }
}

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose(); // Dispose of each controller
    }
    super.dispose();
  }

  Future<void> _shareSelectedImages() async {
    List<XFile> selectedImages = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i]) {
        selectedImages.add(XFile(_images[i].path)); // Add only selected images
      }
    }

    if (selectedImages.isNotEmpty) {
      try {
        await Share.shareFiles(
          selectedImages.map((file) => file.path).toList(),
        );
      } catch (e) {
        print("Error sharing images: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to share selected images.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No selected images to share.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Theme.of(context).primaryColor,
        title: Text(
          widget.itemname,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showImageOptions,
          ),
        ],
      ),
      body: userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView.builder(
                itemCount:
                    userData.length + 1, // Additional item for image preview
                itemBuilder: (context, index) {
                  if (index < userData.length) {
                    final item = userData[index];
                    return Card(
                      margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_ItemName"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Name',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_ItemAlias"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Alias',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_PRate1"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Purchase Rate',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_SRate1"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Sales Rate',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_GroupName"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Group',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["UM_Unit"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Unit',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["IM_HSNCode"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'HSN',
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Show captured or selected image previews
                    // The widget code remains the same as provided
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _images.asMap().entries.map((entry) {
                          int idx = entry.key;
                          File image = entry.value;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  _selectedImages[idx] = !_selectedImages[idx];
                                });
                              },
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(
                                      imagePath: image.path,
                                      onRetake: (File newCroppedImage) async {
                                        setState(() {
                                          // Update the image in the list
                                          _images[idx] = newCroppedImage;
                                          _selectedImages[idx] = false;
                                        });

                                        // Call the API with the updated image path and other parameters
                                        await updateImage(newCroppedImage.path, widget.itemid, idx + 1);
                                      },
                                   ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Image.file(
                                    image,
                                    width: 150,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  if (_selectedImages[idx])
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.check_circle,
                                          color: Colors.red),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    // Check if any images are selected
                    if (_selectedImages.any((isSelected) => isSelected)) {
                      _cancelSelection(); // Call to cancel selection if images are selected
                    } else {
                      Navigator.of(context)
                          .pop(); // Navigate back if no images are selected
                    }
                  },
                  child: const Text('Cancel'), // Button label
                ),
              ),
            ),
            // Display the Delete button only if images are selected
            if (_selectedImages.any((isSelected) => isSelected) &&
                _selectedImages.isNotEmpty) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      // Show confirmation dialog before deleting images
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text(
                                'Are you sure you want to delete the selected images?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  _deleteSelectedImages(); // Proceed to delete images
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      // Check if any images are selected
                      if (_selectedImages.any((isSelected) => isSelected)) {
                        _shareSelectedImages(); // Call to cancel selection if images are selected
                      } else {
                        Navigator.of(context)
                            .pop(); // Navigate back if no images are selected
                      }
                    },
                    child: const Text('Share'), // Button label
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
