import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// COLORS
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4E6);
const Color textDark = Color(0xFF1A1A1A);
const Color textGray = Color(0xFF6B7280);
const Color backgroundColor = Color(0xFFFAF7F2);
const Color cardWhite = Colors.white;
const Color greenAccent = Color(0xFF28A745);

class HotelOwnerRegistrationScreen extends StatefulWidget {
  const HotelOwnerRegistrationScreen({super.key});

  @override
  State<HotelOwnerRegistrationScreen> createState() => _HotelOwnerRegistrationScreenState();
}

class _HotelOwnerRegistrationScreenState extends State<HotelOwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  bool _isLoading = false;

  // Owner Details
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Hotel Details
  final _hotelNameController = TextEditingController();
  final _hotelDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _pricePerNightController = TextEditingController();

  // Hotel Features
  String _selectedCategory = 'Budget';
  List<String> _selectedAmenities = [];
  double _hotelRating = 4.0;

  // Images
  List<File> _hotelImages = [];
  File? _ownerIdProof;

  final List<String> _categories = ['Budget', 'Mid-Range', 'Luxury', 'Boutique', 'Resort'];
  final List<String> _amenitiesList = [
    'WiFi',
    'Parking',
    'Restaurant',
    'Swimming Pool',
    'Gym',
    'Spa',
    'Room Service',
    'Airport Shuttle',
    'Bar',
    'Conference Room',
    'Laundry',
    'Pet Friendly',
  ];

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _passwordController.dispose();
    _hotelNameController.dispose();
    _hotelDescriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _pricePerNightController.dispose();
    super.dispose();
  }

  Future<void> _pickHotelImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && images.length <= 10) {
        setState(() {
          _hotelImages = images.map((xFile) => File(xFile.path)).toList();
        });
      } else if (images.length > 10) {
        _showSnackBar('Please select maximum 10 images', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', isError: true);
    }
  }

  Future<void> _pickIdProof() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _ownerIdProof = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking ID proof: $e', isError: true);
    }
  }

  Future<List<String>> _uploadImages(List<File> images, String hotelId) async {
    List<String> imageUrls = [];
    try {
      for (int i = 0; i < images.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('hotels/$hotelId/images/image_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    } catch (e) {
      print('Error uploading images: $e');
    }
    return imageUrls;
  }

  Future<String?> _uploadIdProof(File idProof, String ownerId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('owners/$ownerId/id_proof.jpg');
      await ref.putFile(idProof);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading ID proof: $e');
      return null;
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    if (_hotelImages.isEmpty) {
      _showSnackBar('Please add at least one hotel image', isError: true);
      return;
    }

    if (_ownerIdProof == null) {
      _showSnackBar('Please upload your ID proof', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _ownerEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      // Upload ID proof
      final idProofUrl = await _uploadIdProof(_ownerIdProof!, userId);

      // Create hotel document
      final hotelRef = await _firestore.collection('hotels').add({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      });

      final hotelId = hotelRef.id;

      // Upload hotel images
      final imageUrls = await _uploadImages(_hotelImages, hotelId);

      // Update hotel document with all details
      await hotelRef.update({
        'ownerId': userId,
        'ownerName': _ownerNameController.text.trim(),
        'ownerEmail': _ownerEmailController.text.trim(),
        'ownerPhone': _ownerPhoneController.text.trim(),
        'ownerIdProof': idProofUrl,
        'hotelName': _hotelNameController.text.trim(),
        'description': _hotelDescriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'pricePerNight': double.parse(_pricePerNightController.text.trim()),
        'category': _selectedCategory,
        'amenities': _selectedAmenities,
        'rating': _hotelRating,
        'images': imageUrls,
        'isActive': false, // Will be activated after admin approval
        'totalBookings': 0,
        'reviews': [],
        'averageRating': _hotelRating,
      });

      // Create owner profile
      await _firestore.collection('hotel_owners').doc(userId).set({
        'name': _ownerNameController.text.trim(),
        'email': _ownerEmailController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
        'hotelId': hotelId,
        'idProofUrl': idProofUrl,
        'registeredAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'status': 'pending',
      });

      setState(() => _isLoading = false);

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Registration failed: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: greenAccent, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Registration Submitted!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your hotel registration is under review. You will be notified once it\'s approved.',
              style: TextStyle(color: textGray, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: _buildCurrentStep(),
                      ),
                    ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: () => Navigator.pop(context),
              color: textDark,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hotel Registration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'List your property with us',
                  style: TextStyle(
                    fontSize: 12,
                    color: textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: primaryOrange, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Owner', Icons.person),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Hotel', Icons.hotel),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Details', Icons.info),
          _buildStepLine(2),
          _buildStepIndicator(3, 'Review', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCompleted
                ? greenAccent
                : isActive
                    ? primaryOrange
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive || isCompleted ? Colors.white : textGray,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? primaryOrange : textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? greenAccent : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildOwnerDetailsStep();
      case 1:
        return _buildHotelBasicStep();
      case 2:
        return _buildHotelDetailsStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOwnerDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Owner Information', Icons.person),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _ownerNameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ownerEmailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val!.isEmpty) return 'Required';
            if (!val.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ownerPhoneController,
          label: 'Phone Number',
          hint: '+91 XXXXX XXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val!.isEmpty) return 'Required';
            if (val.length < 10) return 'Invalid phone number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          icon: Icons.lock_outline,
          isPassword: true,
          validator: (val) {
            if (val!.isEmpty) return 'Required';
            if (val.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildIdProofSection(),
      ],
    );
  }

  Widget _buildHotelBasicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hotel Basic Information', Icons.hotel),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _hotelNameController,
          label: 'Hotel Name',
          hint: 'Enter your hotel name',
          icon: Icons.business,
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _hotelDescriptionController,
          label: 'Description',
          hint: 'Describe your hotel...',
          icon: Icons.description,
          maxLines: 4,
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Street Address',
          hint: 'Building, Street',
          icon: Icons.location_on_outlined,
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'City',
                icon: Icons.location_city,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _stateController,
                label: 'State',
                hint: 'State',
                icon: Icons.map,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pincodeController,
          label: 'Pincode',
          hint: 'XXXXXX',
          icon: Icons.pin_drop,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val!.isEmpty) return 'Required';
            if (val.length != 6) return 'Invalid pincode';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHotelDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hotel Details & Amenities', Icons.star),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _pricePerNightController,
          label: 'Price Per Night (₹)',
          hint: '0',
          icon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
          validator: (val) => val!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        _buildCategorySelector(),
        const SizedBox(height: 24),
        _buildRatingSelector(),
        const SizedBox(height: 24),
        _buildAmenitiesSelector(),
        const SizedBox(height: 24),
        _buildImagePicker(),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Review Your Information', Icons.preview),
        const SizedBox(height: 24),
        _buildReviewCard(
          'Owner Details',
          [
            'Name: ${_ownerNameController.text}',
            'Email: ${_ownerEmailController.text}',
            'Phone: ${_ownerPhoneController.text}',
            'ID Proof: ${_ownerIdProof != null ? 'Uploaded ✓' : 'Not uploaded'}',
          ],
          Icons.person,
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          'Hotel Information',
          [
            'Name: ${_hotelNameController.text}',
            'Category: $_selectedCategory',
            'Price: ₹${_pricePerNightController.text}/night',
            'Location: ${_cityController.text}, ${_stateController.text}',
            'Images: ${_hotelImages.length} uploaded',
          ],
          Icons.hotel,
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          'Amenities',
          _selectedAmenities.isEmpty ? ['No amenities selected'] : _selectedAmenities,
          Icons.featured_play_list,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: lightOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryOrange, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryOrange),
            filled: true,
            fillColor: cardWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ID Proof (Aadhaar/PAN/Driving License)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickIdProof,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _ownerIdProof == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, color: primaryOrange, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload ID proof',
                        style: TextStyle(color: textGray),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _ownerIdProof!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: greenAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotel Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryOrange : cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryOrange : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotel Star Rating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            return InkWell(
              onTap: () => setState(() => _hotelRating = rating.toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  rating <= _hotelRating ? Icons.star : Icons.star_border,
                  color: primaryOrange,
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amenitiesList.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? lightOrange : cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryOrange : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, color: primaryOrange, size: 16),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        color: isSelected ? primaryOrange : textDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotel Images (Max 10)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickHotelImages,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
            ),
            child: _hotelImages.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: primaryOrange, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add hotel images',
                        style: TextStyle(color: textGray),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '${_hotelImages.length} image(s) selected ✓',
                      style: const TextStyle(
                        color: greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
        if (_hotelImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hotelImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _hotelImages[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(String title, List<String> items, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: textGray, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryOrange),
          SizedBox(height: 20),
          Text(
            'Submitting your registration...',
            style: TextStyle(color: textGray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryOrange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _submitRegistration();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep < 3 ? 'Continue' : 'Submit Registration',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}