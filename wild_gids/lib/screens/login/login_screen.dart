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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(75),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                    child: Image.asset(
                      'assets/gifs/login.gif',
                      width: screenWidth * 0.35,
                      fit: BoxFit.contain,
                    ),
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voer uw e-mailadres in',
                          style: AppTextTheme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
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
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                        const SizedBox(height: 20),
                        BrownButton(
                          model: ButtonModelFactory.createLoginButton(
                            text: 'Login',
                          ),
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 20),
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}