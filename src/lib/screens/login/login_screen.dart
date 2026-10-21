import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/exceptions/login_code_delivery_uncertain_exception.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/screens/gate/location_gate_screen.dart';
import 'package:wildgids/screens/login/login_overlay.dart';
import 'package:wildgids/screens/main/main_tab_shell.dart';
import 'package:wildgids/utils/reviewer_auth.dart';
import 'package:wildgids/widgets/overlay/error_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _deepGreen = Color(0xFF003B2B);
  static const _mutedText = Color(0xFF667064);
  static const _fieldBorder = Color(0xFFE7E2D8);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  late final LoginInterface _loginManager;
  bool showVerification = false;
  bool isError = false;
  String errorMessage = '';
  bool _isSendingCode = false;
  bool _deliveryDelayed = false;
  int _loginRequest = 0;

  @override
  void initState() {
    super.initState();
    _loginManager = context.read<LoginInterface>();
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSendingCode) return;
    final email = emailController.text.trim();
    final validationError = _loginManager.validateEmail(email);

    if (validationError != null) {
      showDialog(
        context: context,
        builder: (context) => ErrorOverlay(messages: [validationError]),
      );
      return;
    }

    final request = ++_loginRequest;
    setState(() {
      isError = false;
      errorMessage = '';
      showVerification = true;
      _isSendingCode = true;
      _deliveryDelayed = false;
    });

    String? failureMessage;
    try {
      final response = await _loginManager.sendLoginCode(email);
      if (!response) {
        failureMessage = 'Login mislukt. Probeer het later opnieuw.';
      }
    } on LoginCodeDeliveryUncertainException {
      if (!mounted || request != _loginRequest) return;
      setState(() => _deliveryDelayed = true);
    } catch (e) {
      failureMessage = 'Er is een fout opgetreden. Probeer het later opnieuw.';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        failureMessage =
            'Geen internetverbinding. Controleer uw netwerk en probeer het opnieuw.';
      } else if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        failureMessage =
            'Ongeldige inloggegevens. Controleer uw emailadres en probeer het opnieuw.';
      }
    }
    if (!mounted || request != _loginRequest) return;
    setState(() {
      _isSendingCode = false;
      if (failureMessage != null) showVerification = false;
    });
    if (failureMessage != null) {
      showDialog(
        context: context,
        builder: (_) => ErrorOverlay(messages: [failureMessage!]),
      );
    }
  }

  void _handleVerifyCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        isError = true;
        errorMessage = 'Voer de verificatiecode in';
      });
      return;
    }

    try {
      await _loginManager.verifyCode(emailController.text.trim(), code);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isError = true;
        errorMessage = 'Ongeldige verificatiecode';
      });
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LocationGateScreen(next: MainTabShell()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final titleSize =
        showVerification
            ? (size.width * 0.078).clamp(29.0, 32.0)
            : (size.width * 0.098).clamp(34.0, 40.0);
    final deerHeight = (size.height * (compact ? 0.22 : 0.25)).clamp(
      172.0,
      250.0,
    );
    final topGap = compact ? 18.0 : 28.0;
    final contentGap = compact ? 6.0 : 8.0;
    final fieldGap = compact ? 10.0 : 14.0;
    final linkTopGap = compact ? 10.0 : 14.0;
    final afterLinkGap = compact ? 14.0 : 18.0;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.paddingOf(context).vertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogoHeader(),
                  SizedBox(height: topGap),
                  Text(
                    showVerification ? 'Controleer uw e-mail' : 'Welkom terug',
                    maxLines: 1,
                    style: TextStyle(
                      color: _deepGreen,
                      fontSize: titleSize,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: contentGap),
                  Text(
                    showVerification
                        ? (_deliveryDelayed
                            ? 'De e-mail kan vertraagd zijn. Controleer uw inbox en spammap.'
                            : 'Voer de verificatiecode in om verder te gaan.')
                        : 'Meld u aan om de natuur verder te ontdekken.',
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: deerHeight,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _NatureShapesPainter()),
                        ),
                        Positioned(
                          right: -18,
                          bottom: -24,
                          child: Image.asset(
                            'assets/real_animal_pics_no_bg/real_Damhert.png',
                            height: deerHeight + 42,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ForegroundGrassPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFECE8DE)),
                  SizedBox(height: fieldGap),
                  if (showVerification) ...[
                    _LoginField(
                      controller: codeController,
                      hintText: 'Verificatiecode',
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ReviewerAuth.isReviewerEmail(emailController.text)
                          ? 'Gebruik de verificatiecode uit de testhandleiding.'
                          : '${_isSendingCode || _deliveryDelayed ? 'Code aangevraagd voor' : 'Verzonden naar'} ${emailController.text.trim()}',
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ] else ...[
                    _LoginField(
                      controller: emailController,
                      hintText: 'E-mailadres',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                  if (isError) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: linkTopGap),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        if (showVerification) {
                          setState(() {
                            showVerification = false;
                            _loginRequest++;
                            _isSendingCode = false;
                            _deliveryDelayed = false;
                            codeController.clear();
                            isError = false;
                            errorMessage = '';
                          });
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => const LoginOverlay(),
                          );
                        }
                      },
                      child: Text(
                        showVerification
                            ? 'E-mailadres wijzigen'
                            : 'Hoe werkt de registratie?',
                        style: const TextStyle(
                          color: _deepGreen,
                          decoration: TextDecoration.underline,
                          decorationColor: _deepGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: afterLinkGap),
                  _PrimaryLoginButton(
                    label:
                        _isSendingCode
                            ? 'Code aanvragen...'
                            : (showVerification
                                ? 'Verifieer'
                                : 'Code versturen'),
                    onPressed:
                        _isSendingCode
                            ? null
                            : (showVerification
                                ? _handleVerifyCode
                                : _handleLogin),
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

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: SvgPicture.asset(
            'assets/logo-wildlife.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              _LoginScreenState._deepGreen,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Wild Gids',
              style: TextStyle(
                color: _LoginScreenState._deepGreen,
                fontSize: 34,
                height: 1.18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        style: const TextStyle(
          color: _LoginScreenState._deepGreen,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9EA59B),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _LoginScreenState._deepGreen, size: 28),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 64,
            minHeight: 64,
          ),
          filled: true,
          fillColor: AppColors.offWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _LoginScreenState._fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _LoginScreenState._fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: _LoginScreenState._deepGreen,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF1A704B), Color(0xFF0E5137), Color(0xFF0A3D2E)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A3D2E).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.arrow_forward_rounded, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NatureShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final softShapePaint = Paint()..color = const Color(0xFFEAF0E3);

    final leftShape =
        Path()
          ..moveTo(size.width * 0.14, size.height * 0.94)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.52,
            size.width * 0.29,
            size.height * 0.66,
            size.width * 0.33,
            size.height * 0.86,
          )
          ..cubicTo(
            size.width * 0.41,
            size.height * 0.74,
            size.width * 0.50,
            size.height * 0.86,
            size.width * 0.49,
            size.height * 0.98,
          )
          ..close();
    canvas.drawPath(leftShape, softShapePaint);

    final rightShape =
        Path()
          ..moveTo(size.width * 0.73, size.height * 0.96)
          ..cubicTo(
            size.width * 0.72,
            size.height * 0.48,
            size.width * 0.96,
            size.height * 0.42,
            size.width * 0.91,
            size.height * 0.95,
          )
          ..close();
    canvas.drawPath(rightShape, softShapePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForegroundGrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()..color = const Color(0xFF87B392);
    void drawLeaf(
      double x,
      double y,
      double width,
      double height,
      double tilt,
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tilt);
      final leaf =
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(width * 0.35, -height * 0.55, width, -height)
            ..quadraticBezierTo(width * 0.75, -height * 0.26, 0, 0);
      canvas.drawPath(leaf, grassPaint);
      canvas.restore();
    }

    drawLeaf(size.width * 0.20, size.height * 0.99, 28, 92, -0.36);
    drawLeaf(size.width * 0.25, size.height * 0.99, 24, 68, 0.10);
    drawLeaf(size.width * 0.78, size.height * 1.00, 30, 116, -0.08);
    drawLeaf(size.width * 0.86, size.height * 1.00, 24, 78, 0.42);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
