import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildgids/config/app_config.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/data_managers/profile_api.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/managers/other/login_manager.dart';
import 'package:wildgids/widgets/shared_ui_widgets/brown_button.dart';
import 'package:wildgids/models/api_models/user.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/screens/terms/terms_screen.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class VerificationCodeInput extends StatefulWidget {
  final VoidCallback onBack;
  final String email;

  const VerificationCodeInput({
    super.key,
    required this.onBack,
    required this.email,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  late final LoginInterface loginManager;
  late final AnimationController _animationController;
  bool isLoading = false;
  bool isError = false;
  User? verifiedUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    loginManager = context.read<LoginInterface>();
  }

  Future<void> _routeAfterLogin() async {
    try {
      // Try Provider first, fall back to a local instance so we donâ€™t crash
      ProfileApiInterface profileApi;
      try {
        profileApi = context.read<ProfileApiInterface>();
      } catch (_) {
        profileApi = ProfileApi(AppConfig.shared.apiClient);
      }

      final profile = await profileApi.fetchMyProfile(); // also caches
      if (!mounted) return;

      if (profile.reportAppTerms == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OverzichtScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TermsScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      // If anything goes wrong, keep the OLD behavior: go to Overzicht
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OverzichtScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final code = controllers.map((c) => c.text).join();

    setState(() {
      isLoading = true;
      isError = false;
    });

    bool navigated = false;

    try {
      final response = await loginManager.verifyCode(widget.email, code);
      verifiedUser = response;

      // let the animation play once
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted && verifiedUser != null) {
        await _routeAfterLogin();
        navigated = true;
      }
    } catch (e) {
      // token-saved-despite-error fallback
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('bearer_token');

      if (token != null && mounted) {
        await _routeAfterLogin();
        navigated = true;
      } else {
        setState(() {
          isError = true;
          verifiedUser = null;
        });
        if (context.mounted) {
          for (var c in controllers) c.clear();
          focusNodes[0].requestFocus();
        }
      }
    } finally {
      // if we didnâ€™t navigate, stop the loader
      if (mounted && !navigated) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildTextField(int index) {
    final responsive = context.responsive;
    final boxWidth = responsive.breakpointValue<double>(
      small: responsive.wp(13),
      medium: responsive.wp(12),
      large: responsive.wp(11),
      extraLarge: responsive.wp(10),
    );
    final fontSize = responsive.breakpointValue<double>(
      small: responsive.fontSize(20),
      medium: responsive.fontSize(22),
      large: responsive.fontSize(24),
      extraLarge: responsive.fontSize(24),
    );

    return Container(
      width: boxWidth,
      height: boxWidth * 1.2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.sp(1.5)),
        color:
            isError ? Colors.red.shade50.withValues(alpha: 0.9) : Colors.white,
        border:
            isError
                ? Border.all(
                  color: Colors.red.shade300,
                  width: responsive.sp(0.12),
                )
                : Border.all(
                  color: Colors.grey[300]!,
                  width: responsive.sp(0.12),
                ),
        boxShadow: [
          BoxShadow(
            color:
                isError
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(), // Unique FocusNode for each listener
        onKeyEvent: (KeyEvent event) {
          if (event is! KeyDownEvent) return;
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            // If current field is empty and not the first field
            if (controllers[index].text.isEmpty && index > 0) {
              // Move focus to previous field and clear it
              focusNodes[index - 1].requestFocus();
              controllers[index - 1].clear();
            }
          }
        },
        child: TextField(
          controller: controllers[index],
          focusNode: focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (isError) {
              setState(() => isError = false);
            }
            if (value.isNotEmpty) {
              // Move to next field if not the last one
              if (index < 5) {
                focusNodes[index + 1].requestFocus();
              } else if (index == 5) {
                // Verify code if all fields are filled
                if (controllers.every((c) => c.text.isNotEmpty)) {
                  _verifyCode();
                }
              }
            } else if (value.isEmpty && index > 0) {
              // Move to previous field when backspace clears the current field
              focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: responsive.sp(25),
          height: responsive.sp(25),
          child: Lottie.asset(
            'assets/loaders/loading_paw.json',
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            frameRate: FrameRate(60),
            controller: _animationController,
            onLoaded: (composition) {
              _animationController.duration = composition.duration;
              _animationController.forward();
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Unfocus all text fields before going back
                FocusScope.of(context).unfocus();
                widget.onBack();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.brown,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            Text(
              'Voer de verificatiecode in',
              style: AppTextTheme.textTheme.titleMedium?.copyWith(
                fontSize: responsive.fontSize(16),
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
          ],
        ),
        if (isError) ...[
          Padding(
            padding: EdgeInsets.only(
              left: responsive.wp(5),
              top: responsive.hp(1.2),
            ),
            child: Text(
              'Verkeerde code. Probeer het opnieuw.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        SizedBox(height: responsive.spacing(20)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildTextField(index)),
        ),
        const Spacer(),
        BrownButton(
          model: LoginManager.createButtonModel(
            text: 'Verifieren',
            isLoginButton: true,
          ),
          onPressed: _verifyCode,
        ),
        SizedBox(height: responsive.spacing(15)),
        Center(
          child: TextButton(
            onPressed: () {
              debugPrint("Resend code button pressed");
              _resendCode();
            },
            child: const Text(
              'Code niet ontvangen? Stuur opnieuw',
              style: TextStyle(
                color: AppColors.brown,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _resendCode() async {
    try {
      await loginManager.resendCode(widget.email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificatiecode opnieuw verzonden')),
      );
    } catch (e) {
      debugPrint("Error resending code: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kon code niet verzenden. Probeer het later opnieuw.'),
        ),
      );
    }
  }
}

