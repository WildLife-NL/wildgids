import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/managers/permission/permission_checker.dart';
import 'package:wildrapport/models/factories/button_model_factory.dart';
import 'package:wildrapport/screens/login/login_overlay.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/brown_button.dart';
import 'package:wildrapport/widgets/login/verification_code_input.dart';
import 'package:wildrapport/interfaces/other/login_interface.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with PermissionChecker<LoginScreen> {
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
    initiatePermissionCheck();
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

    _loginManager.sendLoginCode(emailController.text).then((response) {
      if (!response) {
        _pendingErrorMessage = 'Login mislukt. Probeer het later opnieuw.';
      } else {
        debugPrint("Verification Code Sent To Email!");
      }
    }).catchError((e) {
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
    }).whenComplete(() {
      if (_pendingErrorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            showVerification = false;
          });
          showDialog(
            context: context,
            builder: (context) => ErrorOverlay(messages: [_pendingErrorMessage!]),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building LoginScreen, showVerification: $showVerification');
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.zero,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/LogoWildlifeNL.png',
                      width: screenWidth * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    right: -10,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: showVerification
                  ? VerificationCodeInput(
                      onBack: () {
                        setState(() {
                          showVerification = false;
                        });
                      },
                      email: emailController.text,
                    )
                  : Transform.translate(
                      offset: const Offset(0, -20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Voer uw e-mailadres in',
                            textAlign: TextAlign.center,
                            style: AppTextTheme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isError) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 5,
                              ),
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: AppColors.brown, width: 1.5),
                            ),
                            child: TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: 'voorbeeld@gmail.com',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          BrownButton(
                            model: ButtonModelFactory.createLoginButton(
                              text: 'Login',
                            ),
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const LoginOverlay(),
                                );
                              },
                              child: Text(
                                'Leer hoe de registratie werkt?',
                                style: TextStyle(
                                  color: AppColors.brown,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.brown,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
