import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/models/factories/button_model_factory.dart';
import 'package:wildrapport/screens/login/login_overlay.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/brown_button.dart';
import 'package:wildrapport/widgets/login/verification_code_input.dart';
import 'package:wildrapport/interfaces/other/login_interface.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  late final LoginInterface _loginManager;
  bool showVerification = false;
  bool isError = false;
  String errorMessage = '';
  String? _pendingErrorMessage;

  @override
  void initState() {
    super.initState();
    _loginManager = context.read<LoginInterface>();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    debugPrint('Login button pressed');

    final validationError = _loginManager.validateEmail(emailController.text);
    if (validationError != null) {
      showDialog(
        context: context,
        builder: (context) => ErrorOverlay(messages: [validationError]),
      );
      return;
    }

    setState(() {
      isError = false;
      errorMessage = '';
      showVerification = true;
      _pendingErrorMessage = null;
    });

    _loginManager
        .sendLoginCode(emailController.text)
        .then((response) {
          if (!response) {
            _pendingErrorMessage = 'Login mislukt. Probeer het later opnieuw.';
          } else {
            debugPrint("Verification Code Sent To Email!");
          }
        })
        .catchError((e) {
          String userFriendlyMessage =
              'Er is een fout opgetreden. Probeer het later opnieuw.';
          debugPrint('Login error: $e');

          if (e.toString().contains('SocketException') ||
              e.toString().contains('Connection refused') ||
              e.toString().contains('Network is unreachable')) {
            userFriendlyMessage =
                'Geen internetverbinding. Controleer uw netwerk en probeer het opnieuw.';
          } else if (e.toString().contains('timed out')) {
            userFriendlyMessage =
                'De server reageert niet. Probeer het later opnieuw.';
          } else if (e.toString().contains('Unauthorized') ||
              e.toString().contains('401')) {
            userFriendlyMessage =
                'Ongeldige inloggegevens. Controleer uw e-mailadres en probeer het opnieuw.';
          }

          _pendingErrorMessage = userFriendlyMessage;
        })
        .whenComplete(() {
          if (_pendingErrorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                showVerification = false;
              });
              showDialog(
                context: context,
                builder:
                    (context) =>
                        ErrorOverlay(messages: [_pendingErrorMessage!]),
              );
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LoginScreen, showVerification: $showVerification');
    return Scaffold(
      body: ResponsiveUtils.layoutBuilder(
        context: context,
        builder: (ctx, constraints, ru) {
          final isSideBySide =
              constraints.maxWidth >= 600; // breakpoint for tablet
          final showTwoColumn =
              constraints.maxWidth >= 900; // wider layout adjustments
          final branding = Container(
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.zero,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/LogoWildlifeNL.png',
                        width: ru.breakpointValue<double>(
                          small: ru.wp(60),
                          medium: ru.wp(40),
                          large: ru.wp(35),
                          extraLarge: ru.wp(30),
                        ),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: ru.spacing(12)),
                      Text(
                        'Wild Gids',
                        style:
                            AppTextTheme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: ru.adaptiveFont(
                                small: 22,
                                medium: 24,
                                large: 26,
                                extraLarge: 28,
                              ),
                            ) ??
                            TextStyle(
                              color: Colors.white,
                              fontSize: ru.adaptiveFont(
                                small: 22,
                                medium: 24,
                                large: 26,
                                extraLarge: 28,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: ru.hp(-2.5),
                  right: ru.wp(-2.5),
                  child: SizedBox.shrink(),
                ),
              ],
            ),
          );

          final form = Padding(
            padding: EdgeInsets.all(ru.spacing(20)),
            child:
                showVerification
                    ? VerificationCodeInput(
                      onBack: () {
                        setState(() {
                          showVerification = false;
                        });
                      },
                      email: emailController.text,
                    )
                    : Transform.translate(
                      offset: Offset(0, ru.hp(-2.5)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Voer uw e-mailadres in',
                            textAlign: TextAlign.center,
                            style: AppTextTheme.textTheme.titleMedium?.copyWith(
                              fontSize: ru.adaptiveFont(
                                small: 18,
                                medium: 20,
                                large: 22,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: ru.spacing(12)),
                          if (isError) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                left: ru.wp(2),
                                bottom: ru.hp(0.6),
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: ru.fontSize(12),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: ru.spacing(8)),
                          ],
                          SizedBox(height: ru.spacing(8)),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F2),
                              borderRadius: BorderRadius.circular(ru.sp(3.1)),
                              border: Border.all(
                                color: AppColors.brown,
                                width: ru.sp(0.19),
                              ),
                            ),
                            child: TextField(
                              controller: emailController,
                              minLines: 1,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'e-mailadres',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: ru.fontSize(14),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ru.wp(5),
                                  vertical: ru.hp(1.9),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: ru.spacing(24)),
                          BrownButton(
                            model: ButtonModelFactory.createLoginButton(
                              text: 'Aanmelden',
                            ),
                            onPressed: _handleLogin,
                          ),
                          SizedBox(height: ru.spacing(16)),
                          Center(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const LoginOverlay(),
                                );
                              },
                              child: Text(
                                'Hoe werkt de registratie?',
                                style: TextStyle(
                                  color: AppColors.brown,
                                  fontSize: ru.fontSize(14),
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.brown,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
          );

          if (!isSideBySide) {
            return Column(
              children: [
                Expanded(flex: 1, child: branding),
                Expanded(flex: 1, child: form),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: showTwoColumn ? 3 : 2, child: branding),
              Expanded(flex: showTwoColumn ? 4 : 3, child: form),
            ],
          );
        },
      ),
    );
  }
}
