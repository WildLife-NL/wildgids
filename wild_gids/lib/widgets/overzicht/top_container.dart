import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/screens/profile/profile_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TopContainer extends StatefulWidget {
  final String userName;
  final double height;
  final double welcomeFontSize;
  final double usernameFontSize;
  final bool showUserIcon;
  final VoidCallback? onUserIconPressed;

  const TopContainer({
    super.key,
    required this.userName,
    required this.height,
    required this.welcomeFontSize,
    required this.usernameFontSize,
    this.showUserIcon = true,
    this.onUserIconPressed,
  });

  @override
  State<TopContainer> createState() => _TopContainerState();
}

class _TopContainerState extends State<TopContainer> {
  String _version = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    if (!_isLoading) return; // Prevent multiple loads
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${packageInfo.version}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkGreen,
            borderRadius:
                BorderRadius.zero, // straight bottom edge to match mock
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: widget.height * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welkom bij Wild Gids',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontSize: widget.welcomeFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: widget.height * 0.03),
                  Text(
                    widget.userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontSize: widget.usernameFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_version.isNotEmpty)
                    SizedBox(height: widget.height * 0.02),
                  if (_version.isNotEmpty)
                    Text(
                      _version,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.offWhite.withOpacity(0.7),
                        fontSize: widget.welcomeFontSize * 0.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showUserIcon)
          Positioned(
            right: 12,
            // move icon a bit lower for visual alignment
            top: widget.height * 0.12,
            child: GestureDetector(
              onTap:
                  widget.onUserIconPressed ??
                  () {
                    debugPrint('[TopContainer] user icon tapped');
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
              child: Icon(
                Icons.person,
                color: AppColors.offWhite,
                // slightly smaller than before
                size: widget.height * 0.14,
              ),
            ),
          ),
      ],
    );
  }
}
