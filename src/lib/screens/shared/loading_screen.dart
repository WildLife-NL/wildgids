import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/asset_preloader.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback? onLoadingComplete;

  const LoadingScreen({super.key, this.onLoadingComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ), // Adjust this to control speed
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    // Create two futures: one for asset preloading and one for the minimum duration
    final Future<void> assetsFuture = AssetPreloader.precacheAllAssets(context);
    final Future<void> timerFuture = Future.delayed(const Duration(seconds: 2));

    // Wait for both futures to complete
    await Future.wait([assetsFuture, timerFuture]);

    if (mounted && widget.onLoadingComplete != null) {
      widget.onLoadingComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
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
                  _animationController.duration =
                      composition.duration ~/ 2; // Makes it 2x faster
                  _animationController.repeat();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

