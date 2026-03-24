import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
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
          _version = _formatDisplayVersion(packageInfo);
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

  String _formatDisplayVersion(PackageInfo packageInfo) {
    final buildNumber = packageInfo.buildNumber.trim();

    // Example: 20260303 -> 26.03.03
    if (RegExp(r'^\d{8}$').hasMatch(buildNumber)) {
      final yy = buildNumber.substring(2, 4);
      final mm = buildNumber.substring(4, 6);
      final dd = buildNumber.substring(6, 8);
      return '$yy.$mm.$dd';
    }

    // Example: 260303 -> 26.03.03
    if (RegExp(r'^\d{6}$').hasMatch(buildNumber)) {
      final yy = buildNumber.substring(0, 2);
      final mm = buildNumber.substring(2, 4);
      final dd = buildNumber.substring(4, 6);
      return '$yy.$mm.$dd';
    }

    if (buildNumber.isNotEmpty) {
      return 'v${packageInfo.version}+$buildNumber';
    }

    return 'v${packageInfo.version}';
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

