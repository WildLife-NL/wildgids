import 'dart:math' as math;

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
    final recipient =
        ReviewerAuth.isReviewerEmail(emailController.text)
            ? 'Gebruik de verificatiecode uit de testhandleiding.'
            : '${_isSendingCode || _deliveryDelayed ? 'Code aangevraagd voor' : 'Verzonden naar'} ${emailController.text.trim()}';
    const titleStyle = TextStyle(
      color: _deepGreen,
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
    const subtitleStyle = TextStyle(
      color: _mutedText,
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    const emailSubtitle = 'Meld u aan om de natuur verder te ontdekken.';
    final codeSubtitle =
        _deliveryDelayed
            ? 'De e-mail kan vertraagd zijn. Controleer uw inbox en spammap.'
            : 'Voer de verificatiecode in om verder te gaan.';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, 520.0) - 44;
              final scaler = MediaQuery.textScalerOf(context);
              double textHeight(String text, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                )..layout(maxWidth: width);
                final height = painter.height;
                painter.dispose();
                return height;
              }

              // Reserve the same heading and form allowance for both steps.
              final titleHeight = math.max(
                textHeight('Welkom terug', titleStyle),
                textHeight('Controleer uw e-mail', titleStyle),
              );
              final subtitleHeight = math.max(
                textHeight(emailSubtitle, subtitleStyle),
                textHeight(codeSubtitle, subtitleStyle),
              );
              final fieldHeight = math.max(60.0, scaler.scale(18) * 1.4 + 32);
              final buttonHeight = math.max(56.0, scaler.scale(18) * 1.3 + 28);
              final noteHeight = scaler.scale(14) * 1.3 * 2;
              final linkHeight = math.max(
                48.0,
                textHeight(
                      'Hoe werkt de registratie?',
                      const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ) +
                    16,
              );
              final errorHeight =
                  isError
                      ? 12 +
                          textHeight(
                            errorMessage,
                            const TextStyle(fontSize: 14, height: 1.3),
                          )
                      : 0;
              final reserved =
                  40 +
                  20 +
                  titleHeight +
                  8 +
                  subtitleHeight +
                  12 +
                  16 +
                  fieldHeight +
                  8 +
                  noteHeight +
                  errorHeight +
                  16 +
                  buttonHeight +
                  8 +
                  linkHeight;
              final deerHeight =
                  (constraints.maxHeight - 36 - reserved)
                      .clamp(140.0, math.min(420.0, width * 1.1))
                      .toDouble();

              return SingleChildScrollView(
                key: const ValueKey('login-scroll'),
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 476,
                      minHeight: math.max(0, constraints.maxHeight - 36),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LogoHeader(),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: titleHeight,
                              child: _LoginStepTransition(
                                step: showVerification,
                                child: Text(
                                  showVerification
                                      ? 'Controleer uw e-mail'
                                      : 'Welkom terug',
                                  style: titleStyle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: subtitleHeight,
                              child: _LoginStepTransition(
                                step: showVerification,
                                child: Text(
                                  showVerification
                                      ? codeSubtitle
                                      : emailSubtitle,
                                  style: subtitleStyle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              key: const ValueKey('login-illustration'),
                              height: deerHeight,
                              width: double.infinity,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _NatureShapesPainter(),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: -deerHeight * 0.085,
                                      child: Image.asset(
                                        'assets/real_animal_pics_no_bg/real_Damhert.png',
                                        height: deerHeight * 1.1,
                                        fit: BoxFit.contain,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: _LoginGrass(
                                        step: showVerification,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _LoginStepTransition(
                            step: showVerification,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LoginField(
                                  controller:
                                      showVerification
                                          ? codeController
                                          : emailController,
                                  hintText:
                                      showVerification
                                          ? 'Verificatiecode'
                                          : 'E-mailadres',
                                  icon:
                                      showVerification
                                          ? Icons.lock_outline_rounded
                                          : Icons.mail_outline_rounded,
                                  keyboardType:
                                      showVerification
                                          ? TextInputType.number
                                          : TextInputType.emailAddress,
                                  textAlign:
                                      showVerification
                                          ? TextAlign.center
                                          : TextAlign.start,
                                ),
                                if (showVerification) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    recipient,
                                    style: const TextStyle(
                                      color: _mutedText,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                if (isError) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Color(0xFFA33636),
                                      fontSize: 14,
                                      height: 1.3,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 8),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
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
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _deepGreen,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _deepGreen,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// Keep one live form throughout the transition, preserving focus and input.
class _LoginStepTransition extends StatefulWidget {
  const _LoginStepTransition({required this.step, required this.child});

  final bool step;
  final Widget child;

  @override
  State<_LoginStepTransition> createState() => _LoginStepTransitionState();
}

class _LoginStepTransitionState extends State<_LoginStepTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _LoginStepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(_controller.value);
      return Transform.translate(
        offset: Offset(0, 6 * (1 - progress)),
        child: Opacity(opacity: 0.65 + 0.35 * progress, child: child),
      );
    },
  );
}

class _LoginGrass extends StatefulWidget {
  const _LoginGrass({required this.step});

  final bool step;

  @override
  State<_LoginGrass> createState() => _LoginGrassState();
}

class _LoginGrassState extends State<_LoginGrass>
    with SingleTickerProviderStateMixin {
  late final _breeze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breeze.value = 1;
    } else if (_breeze.isDismissed) {
      _breeze.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _LoginGrass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step &&
        !MediaQuery.disableAnimationsOf(context)) {
      _breeze.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breeze.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _ForegroundGrassPainter(_breeze)),
    ),
  );
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
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
                fontSize: 26,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
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
            color: _LoginScreenState._mutedText,
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
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _LoginScreenState._fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _LoginScreenState._fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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
  _ForegroundGrassPainter(this.breeze) : super(repaint: breeze);

  final Animation<double> breeze;

  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()..color = const Color(0xFF87B392);
    // A short breeze settles back to the original silhouette; no endless loop.
    final sway =
        math.sin(breeze.value * math.pi * 4) *
        math.sin(breeze.value * math.pi) *
        0.035;
    void drawLeaf(
      double x,
      double y,
      double width,
      double height,
      double tilt,
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tilt + sway);
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
  bool shouldRepaint(covariant _ForegroundGrassPainter oldDelegate) =>
      oldDelegate.breeze != breeze;
}
