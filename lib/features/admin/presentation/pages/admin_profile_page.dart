import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/widgets/image_file_picker_field.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../presentation/widgets/admin_navigation_bar.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _avatar;
  bool _avatarChanged = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = ref.read(authenticationProvider).user;
    _firstName.text = user?.firstName ?? '';
    _middleName.text = user?.middleName ?? '';
    _lastName.text = user?.lastName ?? '';
    _email.text = user?.email ?? '';
    _phone.text = user?.phone ?? '';
    _avatar = user?.avatar;
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final changes = <String, dynamic>{
        'first_name': _firstName.text.trim(),
        'middle_name': _middleName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        if (_avatarChanged) 'avatar': _avatar,
        if (_password.text.isNotEmpty) 'password': _password.text,
      };
      await ref
          .read(authenticationProvider.notifier)
          .updateCurrentAdminProfile(changes);
      _password.clear();
      _avatarChanged = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authenticationProvider).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account profile'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.darkGreen,
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 4),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ImageFilePickerField(
                          label: 'Profile photo',
                          imageData:
                              _avatarChanged &&
                                  _avatar?.startsWith('data:image/') == true
                              ? _avatar
                              : null,
                          existingImage: _avatarChanged ? null : _avatar,
                          onChanged: (value) => setState(() {
                            _avatar = value;
                            _avatarChanged = true;
                          }),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            user?.role.toUpperCase() ?? 'ADMIN',
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _field(_firstName, 'First name', required: true),
                        _field(_middleName, 'Middle name'),
                        _field(_lastName, 'Last name', required: true),
                        _field(
                          _email,
                          'Email address',
                          required: true,
                          validator: (value) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Enter a valid email address',
                        ),
                        _field(
                          _phone,
                          'Phone number',
                          required: true,
                          validator: (value) =>
                              RegExp(r'^\+?[0-9]{7,15}$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Use 7 to 15 digits, optionally starting with +',
                        ),
                        _field(
                          _password,
                          'New password (leave blank to keep current)',
                          obscure: true,
                          validator: (value) =>
                              (value?.isEmpty ?? true) ||
                                  (value?.length ?? 0) >= 8
                              ? null
                              : 'Password must be at least 8 characters',
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Saving…' : 'Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool obscure = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator:
          validator ??
          (value) => required && (value?.trim().isEmpty ?? true)
              ? '$label is required'
              : null,
    ),
  );

  String _message(Object error) => error is ApiException
      ? switch (error.statusCode) {
          401 => 'Your session expired. Sign in again.',
          403 => 'You are not allowed to update this profile.',
          409 => 'That email or phone number is already in use.',
          422 => error.message,
          _ => 'Could not update your profile. Please try again.',
        }
      : 'Could not update your profile. Please try again.';
}
