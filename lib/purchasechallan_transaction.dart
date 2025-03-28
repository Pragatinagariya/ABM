import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'purchasechallan_transaction_read.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image/image.dart' as img; // Image package for conversion
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
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
          toolbarColor: globals.themeColor,
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
        text: 'Check out this image!',
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
        ],
      ),
    );
  }
}


class PurchaseChallanTransaction extends StatefulWidget {
 
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itid;
  final String invoice;
  final Map<String, dynamic> item; // ✅ Add item parameter
  const PurchaseChallanTransaction({
   
    super.key,
     
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itid,
    required this.item,
    required this.invoice,
  }); // Accept username in constructor

  @override
  State<PurchaseChallanTransaction> createState() =>
      PurchaseChallanTransactionState();
}





class PurchaseChallanTransactionState
    extends State<PurchaseChallanTransaction> {
      
  List Data = [];
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  XFile? _pickedFile;
  final List<File> _images = [];
  List<bool> _selectedImages = [];
  final int _nextImageIndex = 1;
  late Map<String, dynamic> item;
  int _nextIndex = 1; // Default to 1 if no images exist yet
File? _image;

  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    if (Data.isNotEmpty) {
      item = Data.first; // Assign first item (Modify this as needed)
    } else {
      item = {}; // Prevent null errors
    }

    // If getRecord() is async, use async initialization
    getRecord(); // If getRecord() doesn't need to wait before loading images

    // Ensure itemid is valid and load images
    if (widget.itid.isNotEmpty) {
      _loadExistingImages(widget.itid);
    } else {
      print("Error: itemid is null or empty.");
    }
  }

  Future<void> getRecord() async {
    String uri =
        "${globals.uriname}purchasechallan_transaction.php?IT_Id=${widget.itid}&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"; // Pass username in the query
    try {
      var response = await http.get(Uri.parse(uri));
      print('Raw response body: ${response.body}');
      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
          print('Parsed JSON Response: $jsonResponse');
        } catch (e) {
          print('JSON decoding error: $e');
          return;
        }
        if (jsonResponse is List) {
          setState(() {
            Data = jsonResponse;
            print("State updated with ${Data.length} items");
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }
  Future<void> _loadExistingImages(String itid) async {
    final appDir = await getApplicationDocumentsDirectory();
    final clientcode = globals.clientcode;
    final cmpcode = globals.cmpcode;
    final itemDir =
        path.join(appDir.path, clientcode, cmpcode, 'Images', 'Purchase_challan');
    final directory = Directory(itemDir);
    if (directory.existsSync()) {
      final imageFiles = directory
          .listSync()
          .where((file) =>
              file.path.contains('${itid}_') && file.path.endsWith('.jpg'))
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
      print("Directory does not exist for itid $itid");
    }
  }
Widget _buildTextRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(width: 5),
        Text(
          value ?? 'N/A',
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ],
    ),
  );
}

  Future<void> _saveImagesToCloudAndDevice(String itid) async {
    if (_images.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final clientcode = globals.clientcode;
      final cmpcode = globals.cmpcode;
      final itemDir =
          path.join(appDir.path, clientcode, cmpcode, 'Images', 'Purchase_challan');

      // Ensure the directory exists
      final directory = await Directory(itemDir).create(recursive: true);

      int nextIndex = _nextIndex;
      print(nextIndex);

      String fileName;
      String savedImagePath;
      while (true) {
        fileName = '${itid}_$nextIndex.jpg';
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
                "${globals.uriname}image_PC.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
          );

          request.fields['IT_Id'] = itid;
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
Future<void> updateImage(String savedImagePath, String itid, int index) async {
  final clientcode = globals.clientcode;
  final cmpcode = globals.cmpcode;

  try {
    // Update the image on the server
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${globals.uriname}update_image_PC.php?IT_Id=$itid&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
    );

    request.fields['IT_Id'] = itid;
    request.fields['index'] = index.toString();

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      savedImagePath,
      filename: "${itid}_$index.jpg",
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
          path.join(appDir.path, clientcode, cmpcode, 'Images', 'Purchase_challan');
      final localImagePath = path.join(itemDir, "${itid}_$index.jpg");

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
  Future<int> _getCurrentImageIndex(String itid, Directory directory) async {
    try {
      final imageFiles = directory
          .listSync()
          .where((file) =>
              file.path.contains(itid) && file.path.endsWith('.jpg'))
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

    if (fileSize > 2 * 1024 * 1024) {
      // If the file size is greater than 2MB, show a dialog asking to reduce size
      _showReduceSizeDialog(imageFile);
    } else {
      // If the file size is valid, add the image to the list
      setState(() {
        _images.add(imageFile);
        _selectedImages.add(false);
      });

      // Call the function to save the images to cloud and device
      await _saveImagesToCloudAndDevice(widget.itid);
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
              'The file size is ${fileSizeInMB.toStringAsFixed(2)} MB and exceeds 2MB. '
              'Would you like to reduce the size to under 2MB?'),
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
        const maxSize = 2 * 1024 * 1024; // 2MB
        int quality = 100;
        List<int> resizedImage = img.encodeJpg(image, quality: quality);
        while (resizedImage.length > maxSize && quality > 10) {
          quality -= 5; // Reduce quality until the image is under 2MB
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
        await _saveImagesToCloudAndDevice(widget.itid);

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
  final itemDir = path.join(appDir.path, clientcode, cmpcode, 'Images', 'Purchase_challan');

  // Iterate through selected images
  for (int idx = 0; idx < _selectedImages.length; idx++) {
    if (_selectedImages[idx]) {
      final filePath = path.join(itemDir, '${widget.itid}_${idx + 1}.jpg');
      final imageFile = File(filePath);

      try {
        // Delete file from local storage
        if (await imageFile.exists()) {
          await imageFile.delete();
          print("File deleted locally: $filePath");

          // Prepare the data for server request after successful local deletion
          filesToDelete.add({
            'IT_Id': widget.itid,
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
        Uri.parse("${globals.uriname}delete_image_PC.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}"),
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
 Future<void> _openCameras(Map<String, dynamic> selectedItem) async {
  try {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      print("Image Captured at Path: ${_image!.path}");

      // Save image locally
      await _saveImageLocally(_image!);

      // Upload image with correct item ID
      await _uploadImage(_image!, selectedItem);
    } else {
      print("No image selected.");
    }
  } catch (e) {
    print("Error capturing image: $e");
  }
}

Future<void> _saveImageLocally(File image) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = "${item["IT_Id"]}_${item["IT_ItemId"]}.jpg";
    final localPath = "${directory.path}/$fileName";

    await image.copy(localPath);
    print("Image saved at Local Path: $localPath");
  } catch (e) {
    print("Error saving image: $e");
  }
}

Future<void> _uploadImage(File image, Map<String, dynamic> selectedItem) async {
  try {
    if (selectedItem == null || selectedItem["IT_ItemId"] == null) {
      print("Error: IT_ItemId is null!");
      return;
    }

    final uploadUrl = "https://abm99.amisys.in/android/PHP/v2/per_item_image.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";

    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Add fields to request (IT_Id, IT_ItemId, and index)
    request.fields['IT_Id'] = widget.itid.toString(); // Ensure it's a string
    request.fields['IT_ItemId'] = selectedItem["IT_ItemId"].toString();
    // request.fields['index'] = "1"; // Update index if needed

    // Add file to request
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    print("Uploading Image to: $uploadUrl");

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Upload successful!");
      print(await response.stream.bytesToString());
    } else {
      print("Upload failed with status: ${response.statusCode}");
      print(await response.stream.bytesToString());
    }
  } catch (e) {
    print("Error uploading image: $e");
  }
}
String formatDate(String dateTimeStr) {
  try {
    DateTime dateTime = DateTime.parse(dateTimeStr).toLocal(); // Convert to local time
    return DateFormat('yyyy-MM-dd').format(dateTime); // Output: 2024-04-29
  } catch (e) {
    return "Invalid Date";
  }
}
Widget buildCalendarWidget(String? date) {
  DateTime? parsedDate;
  if (date != null && date.isNotEmpty) {
    try {
      parsedDate = DateFormat("dd-MM-yyyy").parse(date);
    } catch (e) {
      parsedDate = null;
    }
  }

  if (parsedDate == null) {
    return Text(
      "N/A",
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  String month = DateFormat.MMM().format(parsedDate); // Month (Apr)
  String day = parsedDate.day.toString(); // Day (01)
  String year = parsedDate.year.toString(); // Year (2024)

  return Container(
    width: 55,
    height: 98, // Reduced width for compact look
    padding: EdgeInsets.all(5), // Reduced padding
    decoration: BoxDecoration(
      color: Colors.white, // Background color
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade400, width: 0.8), // Thinner border
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), // Lighter shadow
          blurRadius: 3,
          spreadRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 📌 Mini Header with Month
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Colors.blue, // Header background
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Text(
            month, // Display Month (e.g., Apr)
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 1),

        // 📌 Mini Circular Date
        Container(
          width: 45, // Rectangle width
          height: 29, // Rectangle height
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 60, 60), // Highlight color
            // borderRadius: BorderRadius.circular(4), // Slightly rounded corners
          ),
          child: Text(
            day, // Display Day (01)
            style: TextStyle(
              color: Colors.white,
              fontSize: 18, // Readable font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),


        SizedBox(height: 1),

        // 📌 Year
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue, // Header background
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          child: Text(
            year, // Display Month (e.g., Apr)
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: globals.themeColor,
        title: Text(
          widget.invoice,
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
      body:  Data.isEmpty
    ? const Center(child: CircularProgressIndicator())
    : ListView.builder(
        itemCount: Data.length + 2, // +2 to account for pinned card and extra data
        itemBuilder: (context, index) {
          if (index == 0) {
            // Pinned Card at the Top
            final item = Data[index];
            return Card(
  margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
  child: Padding(
    padding: const EdgeInsets.all(10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Column: Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCalendarWidget(item["IM_Date"]),
          ],
        ),
        const SizedBox(width: 10), // Space between columns

        // Second Column: Invoice No, Customer Name, Transport, Agent
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice No
              
            Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: 'Challan No: ',
        style: const TextStyle(fontSize: 14, color: Colors.grey), // Label style
      ),
      TextSpan(
        text: item["IM_InvoiceNo"] ?? "N/A",
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), // Value style
      ),
    ],
  ),
),

              const SizedBox(height: 5),

              // Customer Name
              Tooltip(
                message:item['CustName'] ?? 'N',
              child: Text(
                item["CustName"] ?? 'No',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              ),
              const SizedBox(height: 5),

              // Transport
              Row(
                children: [
                  const Text(
                    'Transport: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Expanded(
                    child: Tooltip(
  message: item["IM_Transport"] ?? 'No name', // Full text on hover/tap
  child: Text(
    item["IM_Transport"] ?? 'No name',
    style: const TextStyle(fontSize: 14),
    overflow: TextOverflow.ellipsis,
  ),
),

                  ),
                ],
              ),

              // Agent
              Row(
                children: [
                  const Text(
                    'Agent: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      item["AgentName"] ?? 'No name',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Third Column: Bill Amount, Share, Print
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bill Amount
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee, color: Colors.red, size: 15),
                Text(
                  (double.tryParse(item["IM_BillAmt"] ?? '0.00') ?? 0.0) % 1 == 0
                      ? '${item["IM_BillAmt"]?.split('.')[0]}'
                      : '₹ ${item["IM_BillAmt"]}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Share Icon
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // _sharePDF(item["IM_Id"]);
              },
            ),

            // Print Icon
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // _generatePDF(item["IM_Id"]);
              },
            ),
          ],
        ),
      ],
    ),
  ),
);
          } else if (index <= Data.length) {
            // Existing List Data (Shifted by 1)
            final item = Data[index - 1];
            return GestureDetector(
              onTap: () {},
              
                  child: Card(
  margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
  elevation: 3, // Adds shadow effect
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10), // Rounded corners
  ),
  child: Padding(
    padding: const EdgeInsets.all(10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // First Column: Image & Item Name
        Expanded(
          flex: 2, // Adjust width ratio
          child: Column(
  children: [
    // Item Image
    Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  ),
  // Use ClipRRect to clip the network image with rounded corners
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      'https://abm99.amisys.in/android/PHP/v2/6d002/kit/Images/purchasechallan/${item["IT_Id"]}/${item["IT_ItemId"]}.jpg',
      fit: BoxFit.fill,
      // Placeholder while image loads
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      // Fallback if image fails to load
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/icons/00000000.jpg',
          fit: BoxFit.cover,
        );
      },
    ),
  ),
),
    const SizedBox(height: 4), // Space between image & text
    // Item Name
    SizedBox(
      width: 80, // Same width as the image to align properly
      child: Text(
        "${item["IM_ItemName"] ?? 'N/A'}",
        textAlign: TextAlign.center, // Center align text
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2, // Prevent text from overflowing too much
      ),
    ),
  ],
)

            
        ),

        // Second Column: Meters, Rate, Discount, Discount Amount, GST
        SizedBox(width:10),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextRow("Mtrs:", item["IT_Mtrs"]),
              _buildTextRow("Rate:", "₹ ${item["IT_Rate"]}"),
              _buildTextRow("Dis:", "${item["IT_DisPer"]}%"),
              _buildTextRow("Dis Amt:", "₹ ${item["IT_DisAmt"]}"),
              _buildTextRow("GST:", "${item["IT_GSTPer"]}%"),
              _buildTextRow("HSN:", "${item["HM_HSNCode"]}"),
            ],
          ),
        ),

        // Third Column: HSN Code
       Expanded(
  flex: 1,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center, // Align items in the center vertically
    children: [
      // Move Total Amount upward
      Padding(
        padding: const EdgeInsets.only(bottom: 64), // Adjust spacing
        child: Text(
          "₹ ${item["IT_SubTotal"]}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      // Camera Icon below Total Amount
     IconButton(
          icon: const Icon(
            Icons.camera_alt,
            size: 20,
            color: Colors.grey,
          ),
          
          onPressed: () {
    _openCameras(item); // Pass the item
  },
        ),
      
    ],
  ),
),


      ],
    ),
  ),
),

// Utility function for text rows

                );
              }else {
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
                                        await updateImage(newCroppedImage.path, widget.itid, idx + 1);
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: globals.themeColor,
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
                      backgroundColor: globals.themeColor,
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
                      backgroundColor: globals.themeColor,
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
