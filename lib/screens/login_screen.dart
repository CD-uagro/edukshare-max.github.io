import 'dart:math' as math;

import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  static const Color _uagroRed = Color(0xFF7A0019);
  static const Color _uagroBlue = Color(0xFF0D2A5C);
  static const Color _success = Color(0xFF22C55E);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic));
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final matricula = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (matricula.isEmpty || password.isEmpty) {
      _showErrorDialog('VALIDATION', 'Ingrese matricula y contrasena.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sessionProvider = context.read<SessionProvider>();

      sessionProvider.checkBackend();

      final success = await sessionProvider.login(
        matricula,
        password,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/carnet');
      } else if (mounted) {
        final errorType = sessionProvider.errorType ?? 'UNKNOWN';
        final errorMessage = sessionProvider.error ?? 'Error de autenticacion';

        _showErrorDialog(errorType, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'CONNECTION',
          'No se pudo conectar con el servidor. Intente mas tarde.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String errorType, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.error_outline_rounded, color: _uagroRed, size: 34),
          title: const Text(
            'Error de autenticacion',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(message, style: const TextStyle(height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isWide = constraints.maxWidth >= 1180;

          return Stack(
            children: [
              const _InstitutionalBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 36 : 18,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(child: _buildInstitutionalCopy()),
                                    const SizedBox(width: 56),
                                    SizedBox(width: 460, child: _buildLoginCard(isDesktop)),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCompactBrand(),
                                    const SizedBox(height: 22),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 460),
                                      child: _buildLoginCard(isDesktop),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstitutionalCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset('assets/uagro_logo.png', width: 78, height: 78),
            const SizedBox(width: 18),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UAGro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  'Universidad Autonoma de Guerrero',
                  style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 44),
        const Text(
          'Carnet Digital Universitario',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 18),
        const SizedBox(
          width: 540,
          child: Text(
            'Acceso seguro a tu identificacion institucional, informacion medica critica y servicios SASU.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 34),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _FeaturePill(icon: Icons.shield_rounded, label: 'Seguro'),
            _FeaturePill(icon: Icons.qr_code_2_rounded, label: 'QR institucional'),
            _FeaturePill(icon: Icons.health_and_safety_rounded, label: 'Salud universitaria'),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactBrand() {
    return Column(
      children: [
        Image.asset('assets/uagro_logo.png', width: 82, height: 82),
        const SizedBox(height: 12),
        const Text(
          'UAGro',
          style: TextStyle(
            color: _uagroBlue,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Carnet Digital Universitario',
          style: TextStyle(color: _muted, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 38 : 22,
        isDesktop ? 34 : 24,
        isDesktop ? 38 : 22,
        isDesktop ? 30 : 22,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('assets/uagro_logo.png'),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acceso institucional',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SASU - UAGro',
                        style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Seguro',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Ingresa con tus credenciales universitarias.',
              style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 22),
            AutofillGroup(
              child: Column(
                children: [
                  _ModernTextField(
                    controller: _usernameController,
                    label: 'Matricula',
                    hint: 'Ej. 15662',
                    icon: Icons.badge_outlined,
                    autofillHints: const [AutofillHints.username],
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Ingresa tu matricula';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _ModernTextField(
                    controller: _passwordController,
                    label: 'Contrasena',
                    icon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.password],
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: _muted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword ? 'Mostrar contrasena' : 'Ocultar contrasena',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Ingresa tu contrasena';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Olvidaste tu contrasena?'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _uagroRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 20),
                          SizedBox(width: 9),
                          Text(
                            'Ingresar al sistema',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _uagroBlue,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pushNamed(context, '/register'),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(
                'Crear cuenta de acceso',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _line),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0B67C7)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Necesitas ayuda para acceder?',
                          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Contacta al area SASU de tu campus.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Direccion de Innovacion en Salud Universitaria del Centro de Investigacion Transdisciplinar',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstitutionalBackground extends StatelessWidget {
  const _InstitutionalBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              color: _LoginScreenState._background,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width >= 900
              ? MediaQuery.of(context).size.width * 0.55
              : MediaQuery.of(context).size.width,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _LoginScreenState._uagroBlue,
                  Color(0xFF071832),
                  _LoginScreenState._uagroRed,
                ],
                stops: [0.0, 0.72, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: -80,
          child: Transform.rotate(
            angle: math.pi / 7,
            child: Container(
              width: 250,
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Positioned(
          left: -50,
          bottom: -30,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 340,
              height: 22,
              color: _LoginScreenState._uagroRed,
            ),
          ),
        ),
        Positioned(
          left: 60,
          bottom: 70,
          child: Opacity(
            opacity: 0.06,
            child: Image.asset('assets/uagro_logo.png', width: 240),
          ),
        ),
      ],
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: !obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _LoginScreenState._uagroBlue),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(color: _LoginScreenState._muted, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _LoginScreenState._line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _LoginScreenState._uagroRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _LoginScreenState._success, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
