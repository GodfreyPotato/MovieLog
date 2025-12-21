import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:movie_log/helper/db_helper.dart';
import 'package:movie_log/util/media_query.dart';
import 'package:movie_log/util/format.dart';
import 'package:path_provider/path_provider.dart';

class Addmoviescreen extends StatefulWidget {
  const Addmoviescreen({super.key});

  @override
  State<Addmoviescreen> createState() => _AddmoviescreenState();
}

class _AddmoviescreenState extends State<Addmoviescreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _commentController = TextEditingController();
  final _customGenreController = TextEditingController();
  double _rating = 5.0;
  String? _imagePath;
  String? _selectedGenre;
  File? file;

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _commentController.dispose();
    _customGenreController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload an image!'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Process the form data

      //lipat image sa ibang storage
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();

      // Create a stable filename
      final fileName = file!.path.split('/').last;

      // Copy the file to app directory
      final savedFile = await file!.copy('${appDir.path}/$fileName');

      //selected is ung hindi existing genre  #genre, title, img, message,rate
      if (_selectedGenre == 'Other') {
        int? okay = await DbHelper.insertMovie({
          'img': savedFile.path,
          'genre': _customGenreController.text.toLowerCase().trim(),
          'title': _titleController.text,
          'message': _commentController.text,
          'rate': _rating,
        });
        //if nag error sa pag insert sa new genre, mag cacause ng error
        if (okay == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New genre should be unique from other genre.'),
              backgroundColor: Color(0xFFC62828),
            ),
          );
        }
        return;
      } else {
        //this will trigger if selected genre exist in the dropdown
        await DbHelper.insertMovieGenreSpecified({
          'img': savedFile.path,
          'genreId': int.parse(_selectedGenre!),
          'title': _titleController.text,
          'message': _commentController.text,
          'rate': _rating,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movie added to watch list!'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      // Navigate back or clear form
    }

    Navigator.pop(context, true);
  }

  void _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      file = File(result.files.single.path!);
      setState(() {
        _imagePath = file!.path;
      });
      print("HERE FILE PATH: ${file!.path}");
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecting image cancelled")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Movie",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Upload Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC62828).withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              size: 50,
                              color: Color(0xFFC62828),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Upload Movie Poster",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap to select image",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(file!, fit: BoxFit.cover),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Title Field
            _buildLabel("Title", Icons.movie_creation),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hintText: "Enter movie title",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a movie title';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Genre Dropdown
            _buildLabel("Genre", Icons.category),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: FutureBuilder(
                future: DbHelper.fetchGenres(),
                builder: (context, ss) {
                  if (ss.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC62828),
                      ),
                    );
                  }

                  if (!ss.hasData) {
                    return DropdownButtonFormField<String>(
                      value: _selectedGenre,
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: "Select a genre",
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFC62828),
                      ),
                      items: const [
                        // DropdownMenuItem(value: 'Action', child: Text('Action')),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other: Please Specify'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGenre = value;
                          if (value != 'Other') {
                            _customGenreController.clear();
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a genre';
                        }
                        return null;
                      },
                    );
                  }
                  List genres = ss.data!;

                  return DropdownButtonFormField<String>(
                    value: _selectedGenre,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                      hintText: "Select a genre",
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFC62828),
                    ),
                    items: [
                      ...genres.map(
                        (e) => DropdownMenuItem(
                          value: e['id'].toString(),
                          child: Text(titleCase(e['genre_title'])),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other: Please Specify'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGenre = value;
                        if (value != 'Other') {
                          _customGenreController.clear();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a genre';
                      }
                      return null;
                    },
                  );
                },
              ),
            ),

            // Custom Genre Field (shows when "Other" is selected)
            if (_selectedGenre == 'Other') ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _customGenreController,
                hintText: "Please specify the genre",
                validator: (value) {
                  if (_selectedGenre == 'Other' &&
                      (value == null || value.isEmpty)) {
                    return 'Please specify the genre';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Rating Section
            _buildLabel("Rating", Icons.star),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFA726).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFA726),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${_rating.toStringAsFixed(1)} / 5.0",
                    style: const TextStyle(
                      color: Color(0xFFFFA726),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Comment Field
            _buildLabel("Comment", Icons.comment),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _commentController,
              hintText: "Share your thoughts about this movie...",
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please add a comment';
                }

                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC62828), Color(0xFFD32F2F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC62828).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Add To Watch List",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC62828), size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
