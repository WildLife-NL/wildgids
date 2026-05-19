import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/models/factories/button_model_factory.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/login/login_overlay.dart';
import 'package:wildgids/widgets/shared_ui_widgets/brown_button.dart';
import 'package:wildgids/widgets/login/verification_code_input.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/widgets/overlay/error_overlay.dart';
import 'package:wildgids/utils/responsive_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
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
  codeController.dispose();
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
                'Ongeldige inloggegevens. Controleer uw emailadres en probeer het opnieuw.';
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

void _handleVerifyCode() async {
  final code = codeController.text.trim();

  if (code.isEmpty) {
    setState(() {
      isError = true;
      errorMessage = 'Voer de verificatiecode in';
    });
    return;
  }

  final result = await _loginManager.verifyCode(
    emailController.text.trim(),
    code,
  );

  if (result == false || result == null) {
    setState(() {
      isError = true;
      errorMessage = 'Ongeldige verificatiecode';
    });
    return;
  }

  if (!mounted) return;

  if (!mounted) return;

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const KaartOverviewScreen(),
  ),
);
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F6F4),
    body: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () {
    FocusScope.of(context).unfocus();
  },
  child: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

                SizedBox(
                  width: 120,
                  height: 120,
                  child: SvgPicture.asset(
                    'assets/logo-wildlife.svg',
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              Text(
              'Welkom bij Wild Gids',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

              const SizedBox(height: 8),

              Text(
                'Een app van WildLifeNL',
                textAlign: TextAlign.center,
                style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(
                    color: Color(0xFF999999),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: showVerification
                      ? Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Voer verificatiecode in',
        style: TextStyle(
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Wij hebben een code naar ${emailController.text} verzonden',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: codeController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '123456',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(
          fontSize: 24,
          letterSpacing: 8,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _handleVerifyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Verifieer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            setState(() {
              showVerification = false;
              codeController.clear();
            });
          },
          child: Text(
            'Terug naar e-mail',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ],
  )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voer uw e-mailadres in',
                              style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: emailController,
                              
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'E-mailadres',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF999999),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD0D0D0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (isError)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Aanmelden',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Center(
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const LoginOverlay(),
                                  );
                                },
                                child: const Text(
                                  'Hoe werkt de registratie?',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 103, 103, 103),
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

                           const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}