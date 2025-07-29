// lib/screens/auth/login_screen.dart - MODERN ELEGANT LOGIN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../utils/animation_utils.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (mounted) {
      _showErrorSnackbar(authProvider.errorMessage ?? 'Login failed');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeConfig.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ThemeConfig.spacingL),
              child: Column(
                children: [
                  const SizedBox(height: ThemeConfig.spacingXL),
                  AnimationUtils.slideUp(
                    child: _buildHeader(),
                    delay: const Duration(milliseconds: 200),
                  ),
                  const SizedBox(height: ThemeConfig.spacingXXL),
                  AnimationUtils.slideUp(
                    child: _buildLoginForm(),
                    delay: const Duration(milliseconds: 400),
                  ),
                  const SizedBox(height: ThemeConfig.spacingXL),
                  AnimationUtils.slideUp(
                    child: _buildFooter(),
                    delay: const Duration(milliseconds: 600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with modern design
        AnimationUtils.bounceIn(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: ThemeConfig.primaryGradient,
              borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
              boxShadow: ThemeConfig.elevatedShadow,
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          delay: const Duration(milliseconds: 300),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // App name with gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => ThemeConfig.primaryGradient.createShader(bounds),
          child: const Text(
            'TeleCRM',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingS),
        
        Text(
          'Modern Sales Management',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ThemeConfig.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(ThemeConfig.spacingXL),
          decoration: BoxDecoration(
            color: ThemeConfig.cardColor,
            borderRadius: BorderRadius.circular(ThemeConfig.radiusXL),
            boxShadow: ThemeConfig.cardShadow,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ThemeConfig.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: ThemeConfig.spacingS),
                
                Text(
                  'Sign in to continue to your account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeConfig.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: ThemeConfig.spacingXL),
                
                // Username Field
                AnimationUtils.slideInFromLeft(
                  child: _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Enter your username',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    enabled: !authProvider.isLoading,
                  ),
                  delay: const Duration(milliseconds: 100),
                ),
                
                const SizedBox(height: ThemeConfig.spacingL),
                
                // Password Field
                AnimationUtils.slideInFromRight(
                  child: _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: ThemeConfig.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    enabled: !authProvider.isLoading,
                  ),
                  delay: const Duration(milliseconds: 200),
                ),
                
                const SizedBox(height: ThemeConfig.spacingL),
                
                // Remember Me
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: authProvider.isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                              activeColor: ThemeConfig.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ThemeConfig.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: ThemeConfig.spacingXL),
                
                // Login Button
                AnimationUtils.scaleIn(
                  child: _buildLoginButton(authProvider),
                  delay: const Duration(milliseconds: 300),
                ),
                
                // Error Message
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: ThemeConfig.spacingL),
                  _buildErrorMessage(authProvider.errorMessage!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: ThemeConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ThemeConfig.spacingS),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ThemeConfig.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: ThemeConfig.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? ThemeConfig.backgroundColor : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              borderSide: BorderSide(color: ThemeConfig.secondaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              borderSide: const BorderSide(color: ThemeConfig.accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
              borderSide: const BorderSide(color: ThemeConfig.errorColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return AnimationUtils.rippleEffect(
      onTap: authProvider.isLoading ? () {} : _handleLogin,
      borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: authProvider.isLoading ? null : ThemeConfig.accentGradient,
          borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
          boxShadow: authProvider.isLoading ? null : ThemeConfig.buttonShadow,
        ),
        child: ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: authProvider.isLoading ? Colors.grey[300] : Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
            ),
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.primaryColor),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.spacingM),
      decoration: BoxDecoration(
        color: ThemeConfig.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusM),
        border: Border.all(color: ThemeConfig.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ThemeConfig.errorColor,
            size: 20,
          ),
          const SizedBox(width: ThemeConfig.spacingM),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeConfig.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Demo Credentials (for development)
        Container(
          padding: const EdgeInsets.all(ThemeConfig.spacingL),
          decoration: BoxDecoration(
            color: ThemeConfig.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ThemeConfig.radiusL),
            border: Border.all(color: ThemeConfig.accentColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeConfig.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: ThemeConfig.spacingM),
                  Text(
                    'Demo Access',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ThemeConfig.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeConfig.spacingM),
              Text(
                'Use any agent username from Django admin with the password set in your admin panel.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.accentColor.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: ThemeConfig.spacingL),
        
        // App Version and Branding
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ThemeConfig.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ThemeConfig.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TeleCRM v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeConfig.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: ThemeConfig.spacingM),
        
        // Company branding
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Powered by ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.textTertiary,
                ),
              ),
              TextSpan(
                text: 'TeleCRM',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}