import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/exceptions/api_exception.dart';
import '../../../data/services/product_inquiry_service.dart';
import '../../../services/storage_service.dart';

class GetMoreInfoModal extends StatefulWidget {
  final int productId;
  final String sku;
  final String productTitle;

  const GetMoreInfoModal({
    super.key,
    required this.productId,
    required this.sku,
    required this.productTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required int productId,
    required String sku,
    required String productTitle,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: GetMoreInfoModal(
          productId: productId,
          sku: sku,
          productTitle: productTitle,
        ),
      ),
    );
  }

  @override
  State<GetMoreInfoModal> createState() => _GetMoreInfoModalState();
}

class _GetMoreInfoModalState extends State<GetMoreInfoModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _inquiryService = ProductInquiryService();

  final List<XFile?> _imageSlots = [null];
  bool _isSubmitting = false;

  static const int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _prefillUserDetails();
  }

  Future<void> _prefillUserDetails() async {
    final user = await StorageService.getUserData();
    if (!mounted || user == null) return;

    setState(() {
      if (_nameController.text.isEmpty) {
        _nameController.text = user.name;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = user.email;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildCartStyleButton({
    required String label,
    IconData? icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final enabled = onTap != null && !isLoading;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? Colors.orange : Colors.grey[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showImageSourcePicker(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Capture from Camera'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;
    await _pickImage(index, source);
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() {
      _imageSlots[index] = file;
    });
  }

  void _addImageRow() {
    if (_imageSlots.length >= _maxImages) return;
    setState(() {
      _imageSlots.add(null);
    });
  }

  void _deleteImageSlot(int index) {
    setState(() {
      if (_imageSlots.length > 1) {
        _imageSlots.removeAt(index);
      } else {
        _imageSlots[index] = null;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final images = _imageSlots.whereType<XFile>().toList();
    if (images.length > _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 5 images.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _inquiryService.submitInquiry(
        sku: widget.sku,
        productTitle: widget.productTitle,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        message: _messageController.text.trim(),
        images: images,
      );

      if (!mounted) return;

      final successMessage =
          response['message']?.toString().trim() ??
          'Your inquiry has been submitted successfully.';
      Navigator.of(context).pop();
      Fluttertoast.showToast(msg: successMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: e.message);
    } catch (_) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Unable to submit inquiry. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Get More Info',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF151D51),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyField('Product SKU', widget.sku),
                    const SizedBox(height: 12),
                    _buildReadOnlyField('Product Title', widget.productTitle),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Name*'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email*'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Phone Number*'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: _inputDecoration('Message*'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload Image (Max 5 images — gallery or camera)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF151D51),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_imageSlots.length, _buildImageUploadRow),
                    const SizedBox(height: 12),
                    if (_imageSlots.length < _maxImages)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildCartStyleButton(
                          label: '+ Add Image',
                          onTap: _addImageRow,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildCartStyleButton(
                        label: 'Submit',
                        onTap: _isSubmitting ? null : _submit,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
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

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF151D51),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadRow(int index) {
    final image = _imageSlots[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImageSourcePicker(index),
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(
                  image == null ? 'Choose Image' : 'Change Image',
                ),
              ),
            ),
            if (image != null) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image.path),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (image != null || _imageSlots.length > 1) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _deleteImageSlot(index),
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                tooltip: image != null ? 'Remove image' : 'Remove row',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
