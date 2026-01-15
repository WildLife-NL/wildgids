import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/widgets/shared_ui_widgets/circle_icon_container.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class WhiteBulkButton extends StatefulWidget {
  final String text;
  final Widget? leftWidget;
  final Widget? rightWidget;
  final VoidCallback? onPressed;
  final double height;
  final double? width; // Add width parameter
  final bool showIcon;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign textAlign;
  final Color? backgroundColor; // Add this line
  final Color? borderColor; // Add border color
  final Color? hoverBackgroundColor; // background color on hover/press
  final Color? hoverBorderColor; // border color on hover/press
  final Color? arrowColor; // color for right arrow / icon
  final bool showShadow; // control shadows

  const WhiteBulkButton({
    super.key,
    required this.text,
    this.leftWidget,
    this.rightWidget,
    this.onPressed,
    this.height = 120,
    this.width, // Add width parameter
    this.showIcon = true,
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.textAlign = TextAlign.center,
    this.backgroundColor, // Add this line
    this.borderColor,
    this.hoverBackgroundColor,
    this.hoverBorderColor,
    this.arrowColor,
    this.showShadow = true,
  });
  @override
  State<WhiteBulkButton> createState() => _WhiteBulkButtonState();
}

class _WhiteBulkButtonState extends State<WhiteBulkButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _onEnter(PointerEvent _) => setState(() => _isHovered = true);
  void _onExit(PointerEvent _) => setState(() => _isHovered = false);

  void _onTapDown(TapDownDetails _) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _isPressed = false);
  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final bool active = _isHovered || _isPressed;

    final Color initialBg = widget.backgroundColor ?? AppColors.offWhite;
    final Color initialBorder = widget.borderColor ?? Colors.transparent;

    // When active (hover/press) use hover colors if provided, otherwise fallback
    // to the previous darkGreen behavior for background, and to initialBg for border.
    final Color bgColor =
        active
            ? (widget.hoverBackgroundColor ?? AppColors.darkGreen)
            : initialBg;
    final Color borderColor =
        active ? (widget.hoverBorderColor ?? initialBg) : initialBorder;

    // Base style from theme (buttons should use Roboto / titleMedium)
    final baseStyle = AppTextTheme.textTheme.titleMedium?.copyWith(
      shadows:
          widget.showShadow
              ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
              : null,
    );

    // Combine styles in order of precedence
    final effectiveStyle = baseStyle
        ?.copyWith(
          fontSize:
              widget.fontSize ??
              widget.textStyle?.fontSize ??
              baseStyle.fontSize,
          fontWeight:
              widget.fontWeight ??
              widget.textStyle?.fontWeight ??
              baseStyle.fontWeight,
          color: widget.textStyle?.color ?? baseStyle.color,
        )
        .merge(widget.textStyle);

    final Color defaultTextColor =
        widget.textStyle?.color ?? effectiveStyle?.color ?? Colors.black;
    final TextStyle finalTextStyle = (effectiveStyle ?? const TextStyle())
        .copyWith(color: active ? Colors.white : defaultTextColor);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor,
              width: borderColor != Colors.transparent ? 2 : 0,
            ),
            boxShadow:
                widget.showShadow
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: widget.onPressed,
              splashColor: AppColors.brown.withValues(alpha: 0.1),
              highlightColor: AppColors.brown.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.leftWidget != null)
                      widget.leftWidget!
                    else
                      const SizedBox(),
                    Expanded(
                      child: Text(
                        widget.text,
                        textAlign: widget.textAlign,
                        style: finalTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.rightWidget != null)
                      widget.rightWidget!
                    else if (widget.showIcon)
                      CircleIconContainer(
                        icon: Icons.arrow_forward_ios,
                        iconColor:
                            active
                                ? Colors.white
                                : (widget.arrowColor ?? AppColors.brown),
                        size: responsive.sp(4.8),
                        iconSize: responsive.sp(2.8),
                        backgroundColor:
                            widget.backgroundColor ?? AppColors.offWhite,
                        showShadow: widget.showShadow,
                      )
                    else
                      const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

