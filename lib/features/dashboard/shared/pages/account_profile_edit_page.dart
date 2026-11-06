import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/dashboard_cache_invalidation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/image_file_picker_field.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../presentation/providers/farmer_dashboard_provider.dart';
import '../../presentation/providers/farmer_workspace_provider.dart';
import '../providers/shopping_dashboard_provider.dart';

class AccountProfileEditPage extends ConsumerStatefulWidget {
  const AccountProfileEditPage({super.key});

  @override
  ConsumerState<AccountProfileEditPage> createState() =>
      _AccountProfileEditPageState();
}

class _AccountProfileEditPageState
    extends ConsumerState<AccountProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final AuthUser _user;
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  String? _avatarData;
  bool _avatarChanged = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _user = ref.read(authenticationProvider).user!;
    _firstName = TextEditingController(text: _user.firstName);
    _middleName = TextEditingController(text: _user.middleName);
    _lastName = TextEditingController(text: _user.lastName);
    _email = TextEditingController(text: _user.email);
    _phone = TextEditingController(text: _user.phone ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final changes = <String, dynamic>{};
    _addChange(changes, 'first_name', _firstName.text.trim(), _user.firstName);
    _addChange(
      changes,
      'middle_name',
      _middleName.text.trim(),
      _user.middleName,
    );
    _addChange(changes, 'last_name', _lastName.text.trim(), _user.lastName);
    _addChange(changes, 'email', _email.text.trim(), _user.email);
    _addChange(changes, 'phone', _phone.text.trim(), _user.phone ?? '');
    if (_avatarChanged) changes['avatar'] = _avatarData;
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile has no changes.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(authenticationProvider.notifier)
          .updateCurrentUserProfile(changes);
      final updatedUser = ref.read(authenticationProvider).user!;
      await invalidateUserDashboardCache(ref, updatedUser);
      switch (updatedUser.role) {
        case 'farmer':
          ref.invalidate(farmerWorkspaceProvider);
          ref.invalidate(farmerDashboardProvider);
          break;
        case 'buyer':
        case 'business_buyer':
          ref.invalidate(shoppingDashboardProvider(updatedUser.role));
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account profile updated.')),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _addChange(
    Map<String, dynamic> changes,
    String key,
    String value,
    String original,
  ) {
    if (value != original) changes[key] = value;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.darkGreen,
      title: const Text('Edit account profile'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Update your personal information and profile photo.',
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 16),
                ImageFilePickerField(
                  label: 'Profile photo',
                  imageData: _avatarChanged ? _avatarData : null,
                  existingImage: _avatarChanged ? null : _user.avatar,
                  onChanged: _saving
                      ? (_) {}
                      : (value) => setState(() {
                          _avatarData = value;
                          _avatarChanged = true;
                        }),
                ),
                _field(_firstName, 'First name'),
                _field(_middleName, 'Middle name', required: false),
                _field(_lastName, 'Last name'),
                _field(
                  _email,
                  'Email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.email,
                ),
                _field(
                  _phone,
                  'Phone number',
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_saving,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: validator ??
              (value) => required && value?.trim().isEmpty == true
                  ? '$label is required'
                  : null,
        ),
      );
}
