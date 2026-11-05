import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_sheet.dart';
import 'report_submitted_screen.dart';

/// Creates a new report, or edits [existing] if one is given.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing});

  final Incident? existing;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final _customLocationController = TextEditingController();
  final _locationDetailController = TextEditingController();

  String? _category;
  String? _location;
  String _urgency = 'medium';
  bool _isAnonymous = false;
  XFile? _photo; // a newly picked photo
  Uint8List? _photoBytes; // its preview
  String? _existingPhotoUrl; // photo already saved (when editing)
  bool _triedSubmit = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    context.read<IncidentProvider>().clearSubmitError();

    // Fill the form when editing
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _category = existing.category;
      _otherCategoryController.text = existing.otherCategory ?? '';
      if (AppConstants.campusLocations.contains(existing.location)) {
        _location = existing.location;
      } else {
        _location = kSomewhereElse;
        _customLocationController.text = existing.location;
      }
      _locationDetailController.text = existing.locationDetail ?? '';
      _urgency = existing.urgency;
      _isAnonymous = existing.isAnonymous;
      _existingPhotoUrl = existing.photoUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    _customLocationController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  // ---------- Photo ----------

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the camera or gallery.")),
      );
    }
  }

  void _removePhoto() => setState(() {
    _photo = null;
    _photoBytes = null;
    _existingPhotoUrl = null;
  });

  // ---------- Location ----------

  Future<void> _chooseLocation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => LocationPickerSheet(selected: _location),
    );
    if (result != null) setState(() => _location = result);
  }

  // ---------- Submit ----------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _triedSubmit = true);

    final formValid = _formKey.currentState!.validate();
    if (!formValid || _category == null || _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the highlighted fields.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final provider = context.read<IncidentProvider>();

    final location = _location == kSomewhereElse
        ? _customLocationController.text.trim()
        : _location!;
    final detail = _locationDetailController.text.trim();
    final otherCategory = _category == 'other'
        ? _otherCategoryController.text
        : null;

    if (_isEditing) {
      final saved = await provider.updateIncident(
        existing: widget.existing!,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category!,
        otherCategory: otherCategory,
        location: location,
        locationDetail: detail.isEmpty ? null : detail,
        urgency: _urgency,
        isAnonymous: _isAnonymous,
        newPhoto: _photo,
        keepExistingPhoto: _existingPhotoUrl != null,
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Changes saved')));
        Navigator.of(context).pop();
      }
      return;
    }

    final incident = await provider.submitIncident(
      reporter: user,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category!,
      otherCategory: otherCategory,
      location: location,
      locationDetail: detail.isEmpty ? null : detail,
      urgency: _urgency,
      isAnonymous: _isAnonymous,
      photo: _photo,
    );

    if (incident != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReportSubmittedScreen(incident: incident),
        ),
      );
    }
  }

  // ---------- Small validators ----------

  static String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please add a short title';
    if (text.length < 5) return 'Title is too short';
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please describe the problem';
    if (text.length < 10) {
      return 'Add a little more detail (at least 10 characters)';
    }
    return null;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit report' : 'Report an issue'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const _SectionLabel('What kind of problem is it?'),
            const SizedBox(height: 10),
            _CategoryGrid(
              selected: _category,
              onSelected: (id) => setState(() => _category = id),
            ),
            if (_triedSubmit && _category == null)
              const _ErrorText('Please choose a category'),
            if (_category == 'other') ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Describe the type of problem',
                controller: _otherCategoryController,
                hint: 'e.g. Insects in the dormitory',
                maxLength: 40,
                validator: (v) =>
                    _required(v, 'Please say what kind of problem it is'),
              ),
            ],
            const SizedBox(height: 20),
            AppTextField(
              label: 'Short title',
              controller: _titleController,
              hint: 'e.g. No water in the 2nd floor bathrooms',
              maxLength: 60,
              textInputAction: TextInputAction.next,
              validator: _validateTitle,
            ),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Description',
              controller: _descriptionController,
              hint: 'What happened, since when, and who is affected?',
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              maxLength: 500,
              validator: _validateDescription,
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Location'),
            const SizedBox(height: 8),
            _LocationButton(
              value: _location,
              hasError: _triedSubmit && _location == null,
              onTap: _chooseLocation,
            ),
            if (_triedSubmit && _location == null)
              const _ErrorText('Please choose where it is'),
            if (_location == kSomewhereElse) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Where is it?',
                controller: _customLocationController,
                hint: 'Type the place',
                validator: (v) => _required(v, 'Please type the place'),
              ),
            ],
            const SizedBox(height: 12),
            AppTextField(
              label: 'Exact spot (optional)',
              controller: _locationDetailController,
              hint: 'e.g. 2nd floor, near the stairs',
              maxLength: 80,
            ),
            const SizedBox(height: 8),
            const _SectionLabel('How urgent is it?'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 4),
                  ),
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                ),
                segments: AppConstants.urgencyLevels.entries
                    .map(
                      (e) => ButtonSegment(value: e.key, label: Text(e.value)),
                    )
                    .toList(),
                selected: {_urgency},
                onSelectionChanged: (s) => setState(() => _urgency = s.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use Emergency only when people are at risk right now.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Photo (optional)'),
            const SizedBox(height: 8),
            _PhotoBox(
              bytes: _photoBytes,
              networkUrl: _existingPhotoUrl,
              onPick: _pickPhoto,
              onRemove: _removePhoto,
            ),
            const SizedBox(height: 20),
            Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: scheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                secondary: Icon(
                  Icons.visibility_off_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                title: const Text(
                  'Report anonymously',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Your name is hidden from other students. Campus staff can still see it.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (provider.submitError != null) ...[
              InfoBanner(
                message: provider.submitError!,
                type: InfoBannerType.error,
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Submit report',
              onPressed: _submit,
              isLoading: provider.isSubmitting,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------- Small private widgets used only on this screen ----------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: FontWeight.w500),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: AppConstants.categories.map((category) {
        final isSelected = category.id == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          child: Material(
            color: isSelected ? scheme.primary : scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? scheme.primary : scheme.outline,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(category.id),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.value,
    required this.hasError,
    required this.onTap,
  });

  final String? value;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? scheme.error : scheme.outline,
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 20,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? 'Choose a campus location',
                style: TextStyle(
                  fontSize: 16,
                  color: value == null
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.bytes,
    required this.networkUrl,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // A new photo wins over the saved one
    final Widget? image = bytes != null
        ? Image.memory(
            bytes!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : networkUrl != null
        ? Image.network(
            networkUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : null;

    if (image != null) {
      return Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 28,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(height: 6),
            Text(
              'Take or upload a photo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'A photo helps staff understand the problem',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
