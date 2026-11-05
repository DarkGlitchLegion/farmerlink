import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/avatar_upload.dart';
import '../providers/authentication_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _imagePicker = ImagePicker();
  String _role = 'farmer';
  AvatarUpload? _avatar;
  String? _avatarError;

  Future<void> _pickAvatar() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType =
          file.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'jpg' || 'jpeg' => 'image/jpeg',
            'webp' => 'image/webp',
            'gif' => 'image/gif',
            _ => '',
          };
      if (!const {
        'image/png',
        'image/jpeg',
        'image/webp',
        'image/gif',
      }.contains(mimeType)) {
        setState(
          () => _avatarError = 'Choose a PNG, JPEG, WebP, or GIF image.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        setState(() => _avatarError = 'Choose an image smaller than 5 MiB.');
        return;
      }
      setState(() {
        _avatar = AvatarUpload(
          bytes: bytes,
          filename: file.name,
          mimeType: mimeType,
        );
        _avatarError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _avatarError = 'Could not open that image. Please try another.',
      );
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authenticationProvider.notifier)
        .register(
          firstName: _firstName.text,
          middleName: _middleName.text,
          lastName: _lastName.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          role: _role,
          avatar: _avatar,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authenticationProvider);
    final loading = auth.status == AuthenticationStatus.loading;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Create account',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const AuthHeader(
                    title: 'Join the table',
                    subtitle: 'Create your account and grow with your local community.',
                  ),
                  const SizedBox(height: 18),
                  _AvatarChoice(
                    avatar: _avatar,
                    error: _avatarError,
                    onTap: loading ? null : _pickAvatar,
                  ),
                  const SizedBox(height: 26),
                  AuthTextField(
                    controller: _firstName,
                    label: 'First name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        AppValidators.required(value, 'First name'),
                  ),
                  const SizedBox(height: 13),
                  AuthTextField(
                    controller: _middleName,
                    label: 'Middle name',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        AppValidators.required(value, 'Middle name'),
                  ),
                  const SizedBox(height: 13),
                  AuthTextField(
                    controller: _lastName,
                    label: 'Last name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        AppValidators.required(value, 'Last name'),
                  ),
                  const SizedBox(height: 13),
                  AuthTextField(
                    controller: _email,
                    label: 'Email address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 13),
                  AuthTextField(
                    controller: _phone,
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: AppValidators.phone,
                  ),
                  const SizedBox(height: 13),
                  PasswordField(
                    controller: _password,
                    validator: AppValidators.password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 13),
                  PasswordField(
                    controller: _confirmPassword,
                    label: 'Confirm password',
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      return value == _password.text
                          ? null
                          : 'Passwords do not match.';
                    },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'I am joining as',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Account type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                      DropdownMenuItem(
                        value: 'buyer',
                        child: Text('Individual buyer'),
                      ),
                      DropdownMenuItem(
                        value: 'business_buyer',
                        child: Text('Business buyer'),
                      ),
                    ],
                    onChanged: loading
                        ? null
                        : (value) {
                            if (value != null) setState(() => _role = value);
                          },
                  ),
                  if (auth.errorMessage != null ||
                      auth.successMessage != null) ...[
                    const SizedBox(height: 15),
                    _RegisterMessage(
                      message: auth.errorMessage ?? auth.successMessage!,
                      success: auth.successMessage != null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  AuthButton(
                    label: 'Create account',
                    loading: loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: loading ? null : () => context.go('/login'),
                    child: const Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By creating an account, you agree to provide accurate information. Your selected role does not grant permissions beyond those allowed by FarmerLink.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .56),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterMessage extends StatelessWidget {
  const _RegisterMessage({required this.message, required this.success});
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: success ? const Color(0xFFEAF5E9) : const Color(0xFFFFEFEE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: success ? AppColors.primaryGreen : const Color(0xFF9B1C1C),
        fontSize: 13,
        height: 1.4,
      ),
    ),
  );
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.avatar,
    required this.error,
    required this.onTap,
  });

  final AvatarUpload? avatar;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBDD)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE9F3E7),
                foregroundImage: avatar == null
                    ? null
                    : MemoryImage(avatar!.bytes),
                child: avatar == null
                    ? const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primaryGreen,
                        size: 21,
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avatar == null
                          ? 'Add a profile photo'
                          : 'Profile photo selected',
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Optional · PNG, JPEG, WebP, or GIF · up to 5 MiB',
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .62),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            error!,
            style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 12),
          ),
        ),
      ],
    ],
  );
}
