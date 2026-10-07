import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final AuthState authState;
  final VoidCallback? onAuthenticated;

  const AuthScreen({
    super.key,
    required this.authState,
    this.onAuthenticated,
  });

  static Future<void> show(BuildContext context, AuthState authState) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          authState: authState,
          onAuthenticated: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authState;

    return Scaffold(
      backgroundColor: const Color(0xFF08090C), // Deep obsidian black
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar Navigation / Skip Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161C),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(24), width: 1),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                            ),
                          )
                        else
                          const SizedBox(width: 38),
                        // Center Brand Emblem
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'IMREXPENSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        // Skip / Guest Text
                        GestureDetector(
                          onTap: () {
                            auth.continueAsGuest();
                            if (widget.onAuthenticated != null) {
                              widget.onAuthenticated!();
                            } else if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14161C),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withAlpha(24), width: 1),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    // Headline Title (Matching reference image)
                    Text(
                      _isSignUp ? 'Sign Up Account' : 'Sign In Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle (Matching reference image)
                    Text(
                      _isSignUp
                          ? 'Enter your personal data to create your account.'
                          : 'Enter your credentials to access your cloud journal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Social Login Buttons (Google & Guest Side-by-Side as in reference)
                    Row(
                      children: [
                        // Google Button
                        Expanded(
                          child: InkWell(
                            onTap: auth.isLoading ? null : () => _submitGoogleAuth(auth),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161C),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withAlpha(28),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Colored Google G badge
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Guest Access Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              auth.continueAsGuest();
                              if (widget.onAuthenticated != null) {
                                widget.onAuthenticated!();
                              } else if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14161C),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withAlpha(28),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on_rounded, color: Colors.white, size: 19),
                                  SizedBox(width: 8),
                                  Text(
                                    'Guest',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // "Or" Divider Line (Matching reference image)
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 1, color: Colors.white.withAlpha(22)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Or',
                            style: TextStyle(
                              color: Colors.white.withAlpha(120),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: Colors.white.withAlpha(22)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Error Banner (with smart Create Account switcher)
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF221115),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.danger.withAlpha(90)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                                  onPressed: () => auth.clearError(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            if (!_isSignUp &&
                                (auth.errorMessage!.contains('create an account') ||
                                    auth.errorMessage!.contains('not created') ||
                                    auth.errorMessage!.contains('not found'))) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.black),
                                  label: const Text(
                                    'Create Account First →',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.black),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isSignUp = true;
                                      auth.clearError();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Sign Up Specific Fields: First Name & Last Name (Side-by-Side as in reference)
                    if (_isSignUp) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'First Name',
                              hint: 'eg. John',
                              controller: _firstNameController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              label: 'Last Name',
                              hint: 'eg. Francisco',
                              controller: _lastNameController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Address Field
                    _buildInputField(
                      label: 'Email Address',
                      hint: 'eg. john@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    _buildInputField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 19,
                          color: Colors.white.withAlpha(150),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Minimum 6 characters';
                        }
                        return null;
                      },
                    ),

                    // Forgot Password (in Sign In mode)
                    if (!_isSignUp) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(context, auth),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    // Primary CTA Action Button (Pure White Button with Bold Black Text)
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: auth.isLoading ? null : () => _submitEmailAuth(auth),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.4),
                              )
                            : Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bottom Toggle Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withAlpha(160),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              auth.clearError();
                            });
                          },
                          child: Text(
                            _isSignUp ? 'Log In' : 'Sign Up',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(75),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFF14161C),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(24),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(24),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.white,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitEmailAuth(AuthState auth) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

    bool success = false;
    if (_isSignUp) {
      success = await auth.signUpWithEmail(email, password, displayName: fullName);
    } else {
      success = await auth.signInWithEmail(email, password);
    }

    if (success && mounted) {
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submitGoogleAuth(AuthState auth) async {
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context, AuthState auth) {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14161C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(28), width: 1),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address and we will send you a password reset link.',
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(170)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                hintStyle: TextStyle(color: Colors.white.withAlpha(70)),
                filled: true,
                fillColor: const Color(0xFF0C0E12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;
              final ok = await auth.sendPasswordReset(email);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Password reset email sent to $email'
                          : (auth.errorMessage ?? 'Failed to send reset email'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: ok ? AppColors.charcoal : AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Send Link', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
