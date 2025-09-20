// presentation/screens/report/report_submission_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/cross_platform_image.dart';
import '../../widgets/image_annotation_editor.dart';
import 'enhanced_report_detail_screen.dart';

class ReportSubmissionScreen extends StatefulWidget {
  const ReportSubmissionScreen({super.key});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = AppConstants.reportCategories.first;
  bool _isUrgent = false;
  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];
  bool _showDuplicateSuggestions = true; // wizard step gate

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  void _getCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition == null) {
      await locationProvider.getCurrentLocation();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        // Limit to 5 images total
        final remainingSlots = 5 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _annotateImage(int index) async {
    try {
      final bytes = await _selectedImages[index].readAsBytes();
      if (!mounted) return;
      final annotated = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageAnnotationEditor(imageBytes: bytes),
          fullscreenDialog: true,
        ),
      );
      if (annotated != null) {
        // Replace the image with an in-memory annotated version by writing to a temp XFile-like path.
        // For simplicity, store back as a memory image using a data URI-like hack for demo.
        final temp = XFile.fromData(annotated, name: 'annotated_$index.png');
        setState(() => _selectedImages[index] = temp);
      }
    } catch (e) {
      _showErrorSnackBar('Annotation failed: $e');
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickMultipleImages();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Require sign-in for submissions
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      context.push('/sign-in?from=/submit-report');
      return;
    }

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentPosition == null) {
      _showErrorSnackBar(
        'Location is required. Please enable location services.',
      );
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);

    try {
      final reportProvider = Provider.of<ReportProvider>(
        context,
        listen: false,
      );

      // Convert File paths to strings for demo purposes
      final imageUrls = _selectedImages.map((file) => file.path).toList();

      await reportProvider.submitReport(
        context: context,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
        address: locationProvider.currentAddress ?? 'Address not available',
        imageUrls: imageUrls,
        isUrgent: _isUrgent,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to submit report: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Report Submitted!'),
        content: const Text(
          'Thank you for reporting this issue. Your report has been submitted and will be reviewed by the community.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('View Reports'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  Widget _buildDuplicateSuggestionsCard() {
    final rp = Provider.of<ReportProvider>(context, listen: false);
    final loc = Provider.of<LocationProvider>(context, listen: false);
    final all = rp.reports;

    // Simple proximity + keyword match
    final lat = loc.currentPosition?.latitude;
    final lng = loc.currentPosition?.longitude;

    bool isNearby(double a, double b) => (a - b).abs() < 0.005; // ~500m
    bool keywordHit(ReportModel r) {
      final t = _titleController.text.toLowerCase();
      if (t.isEmpty) return false;
      return r.title.toLowerCase().contains(t.split(' ').first);
    }

    final suggestions = all
        .where((r) {
          if (lat == null || lng == null) return false;
          final near = isNearby(r.latitude, lat) && isNearby(r.longitude, lng);
          return near || keywordHit(r);
        })
        .take(5)
        .toList();

    if (suggestions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No likely duplicates near your location. Continue to submit.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Possible Duplicates Nearby',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'We found a few similar reports near your location. If one matches, you can upvote it instead of creating a new one.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...suggestions.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${r.category} • ${r.status.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Open detail preview; user can decide to go back or not
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EnhancedReportDetailScreen(report: r),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showDuplicateSuggestions = false),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Looks good, continue'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Submit Report'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: quick duplicate suggestions
                    if (_showDuplicateSuggestions)
                      _buildDuplicateSuggestionsCard(),
                    if (_showDuplicateSuggestions) const SizedBox(height: 16),
                    // Location info
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        if (locationProvider.isLoading) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Getting your location...'),
                                ],
                              ),
                            ),
                          );
                        }

                        if (locationProvider.error != null) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        color: AppTheme.errorRed,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Location Error'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(locationProvider.error!),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _getCurrentLocation,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.successGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Report Location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        locationProvider.currentAddress ??
                                            'Location detected',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category selection
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: AppConstants.reportCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Title field
                    Text(
                      'Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Brief description of the issue',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: AppConstants.maxTitleLength,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 10) {
                          return 'Title must be at least 10 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description field
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText:
                            'Provide detailed information about the issue',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      maxLength: AppConstants.maxDescriptionLength,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Image upload section
                    Text(
                      'Photos (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (_selectedImages.isEmpty)
                            Column(
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48,
                                  color: AppTheme.mediumGray,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add photos to help illustrate the issue',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.mediumGray),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showImagePickerDialog,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Add Photos'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryBlue,
                                    backgroundColor: AppTheme.lightGray,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                // Image grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: CrossPlatformImage(
                                            imageFile: _selectedImages[index],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 
                                                  0.6,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _annotateImage(index),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 
                                                  0.6,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Annotate',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Add more photos button
                                if (_selectedImages.length < 5)
                                  OutlinedButton.icon(
                                    onPressed: _showImagePickerDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add More Photos'),
                                  ),
                                if (_selectedImages.length >= 5)
                                  Text(
                                    'Maximum 5 photos allowed',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.mediumGray),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Urgency toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: _isUrgent
                                  ? AppTheme.errorRed
                                  : AppTheme.mediumGray,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mark as Urgent',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Only use for safety hazards requiring immediate attention',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.mediumGray),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isUrgent,
                              onChanged: (value) {
                                setState(() {
                                  _isUrgent = value;
                                });
                              },
                              activeThumbColor: AppTheme.errorRed,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            // If duplicate step is showing, prompt to confirm next rather than submit
                            if (_showDuplicateSuggestions) {
                              setState(() => _showDuplicateSuggestions = false);
                            } else {
                              _submitReport();
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _showDuplicateSuggestions
                                ? 'Next'
                                : 'Submit Report',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
