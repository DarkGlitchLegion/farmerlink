import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/image_file_picker_field.dart';
import '../../../authentication/domain/entities/user.dart';

class AccountProfileEditSheet extends StatefulWidget {
  const AccountProfileEditSheet({super.key, required this.user});

  final AuthUser user;

  @override
  State<AccountProfileEditSheet> createState() =>
      _AccountProfileEditSheetState();
}

class _AccountProfileEditSheetState extends State<AccountProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  String? _avatarData;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstName = TextEditingController(text: user.firstName);
    _middleName = TextEditingController(text: user.middleName);
    _lastName = TextEditingController(text: user.lastName);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone ?? '');
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final user = widget.user;
    final changes = <String, dynamic>{};
    _addChange(changes, 'first_name', _firstName.text.trim(), user.firstName);
    _addChange(
      changes,
      'middle_name',
      _middleName.text.trim(),
      user.middleName,
    );
    _addChange(changes, 'last_name', _lastName.text.trim(), user.lastName);
    _addChange(changes, 'email', _email.text.trim(), user.email);
    _addChange(changes, 'phone', _phone.text.trim(), user.phone ?? '');
    if (_avatarChanged) changes['avatar'] = _avatarData;
    Navigator.pop(context, changes);
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
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit account profile',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ImageFilePickerField(
                label: 'Profile photo',
                imageData: _avatarChanged ? _avatarData : null,
                existingImage: _avatarChanged ? null : widget.user.avatar,
                onChanged: (value) => setState(() {
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
              FilledButton(onPressed: _save, child: const Text('Save profile')),
            ],
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
