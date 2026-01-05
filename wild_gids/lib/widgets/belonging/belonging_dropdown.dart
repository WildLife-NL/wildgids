import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';

class BelongingDropdown extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String getSelectedValue;
  final String getSelectedText;
  final List<Map<String, String>> dropdownItems;
  final double? containerWidth;
  final double? containerHeight;
  final String startingValue;
  final bool hasDropdownSideDescription;
  final String? dropdownSideDescriptionText;
  final String defaultValue;
  final bool hasError; // Add this property to check for error state
  final bool useIcons;
  final ValueChanged<bool>? onDropdownToggle; // Added the callback here

  const BelongingDropdown({
    super.key,
    this.onChanged,
    required this.getSelectedValue,
    required this.getSelectedText,
    required this.dropdownItems,
    this.containerWidth,
    this.containerHeight,
    required this.startingValue,
    required this.hasDropdownSideDescription,
    this.dropdownSideDescriptionText,
    required this.defaultValue,
    required this.hasError, // Pass error state from provider
    required this.useIcons,
    this.onDropdownToggle, // Make sure to add this to constructor
  });

  @override
  State<BelongingDropdown> createState() => _BelongingDropdownState();
}

class _BelongingDropdownState extends State<BelongingDropdown> {
  bool isExpanded = false;
  late String selectedValue;
  late String selectedText;
  OverlayEntry? overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();
  final List<String> gewassIconList = [
    "assets/icons/possesion/gewassen/corn.svg",
    "assets/icons/possesion/gewassen/radish_2.svg",
    "assets/icons/possesion/gewassen/wheat.svg",
    "assets/icons/possesion/gewassen/tulip_2.svg",
    "assets/icons/possesion/gewassen/grass.svg",
    "assets/icons/possesion/gewassen/apple.svg",
    "assets/icons/possesion/gewassen/tomato.svg",
  ];
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';
  late final BelongingDamageReportProvider formProvider;

  @override
  void initState() {
    super.initState();
    selectedValue =
        widget.getSelectedValue.isNotEmpty
            ? widget.getSelectedValue
            : widget.defaultValue;
    selectedText =
        widget.getSelectedText.isNotEmpty
            ? widget.getSelectedText
            : widget.defaultValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formProvider = Provider.of<BelongingDamageReportProvider>(
      context,
      listen: false,
    );
    formProvider.addListener(_onFormProviderChanged);
  }

  void _onFormProviderChanged() {
    debugPrint("$yellowLog _onFormProviderChanged");
    if (formProvider.expanded && isExpanded) {
      debugPrint(
        "$yellowLog [PossesionDropdown]: external tap detected, closing overlay",
      );
      closeOverlay();
      // ✅ Reset to false to prevent re-triggering
      formProvider.updateExpanded(false);
    }
  }

  @override
  void didUpdateWidget(covariant BelongingDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.getSelectedValue != oldWidget.getSelectedValue &&
        widget.getSelectedValue.isNotEmpty) {
      selectedValue = widget.getSelectedValue;
    }
  }

  @override
  void dispose() {
    formProvider.removeListener(_onFormProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget.hasDropdownSideDescription
              ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(widget.dropdownSideDescriptionText ?? ''),
                  const SizedBox(width: 10),
                  buildMainButton(),
                ],
              )
              : buildMainButton(),
          const SizedBox(
            height: 4,
          ), // small space between dropdown and error text
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: 16, // always reserve space for 1 line of error text
              child:
                  widget.hasError
                      ? const Text(
                        'This field is required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      )
                      : const SizedBox.shrink(), // invisible when no error
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMainButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            debugPrint("$greenLog [PossesionDropdown]: line 112");
            overlayEntry?.remove();
            isExpanded = false;
          } else {
            showOverlay();
            debugPrint("$greenLog [PossesionDropdown]: line 120");
            isExpanded = true;
          }
          // Notify about the state change (whether dropdown is open or closed)
          if (widget.onDropdownToggle != null) {
            widget.onDropdownToggle!(isExpanded); // Trigger callback
          }
        });
      },
      child: Container(
        key: _buttonKey, // Set the key to the button container
        width: widget.containerWidth ?? 200,
        height: widget.containerHeight ?? 50,
        decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: BorderRadius.circular(30),
          border:
              widget.hasError
                  ? Border.all(color: Colors.red, width: 2.0)
                  : Border.all(color: Colors.transparent, width: 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ), // Ensure you know the padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void showOverlay() {
    final overlay = Overlay.of(context);

    // Get the position and size of the dropdown button using the RenderBox
    final RenderBox renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(
      Offset.zero,
    ); // Position relative to screen
    final double buttonWidth =
        renderBox.size.width; // Get the actual width of the button
    final double top = buttonPosition.dy + renderBox.size.height;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Semi-transparent overlay backdrop
            GestureDetector(
              onTap: () {
                closeOverlay();
                setState(() {
                  isExpanded = false;
                });
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            // Dropdown items
            Positioned(
              top: top, // Position the dropdown right below the button
              left: buttonPosition.dx, // Align the dropdown with the button
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children:
                      widget.dropdownItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> item = entry.value;
                        return buildDropdownItem(item, buttonWidth, index);
                      }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(overlayEntry!);
  }

  void setItemState(item) {
    debugPrint("$greenLog [PossesionDropdown]: line 197");
    setState(() {
      selectedValue = item['value']!;
      selectedText = item['text']!;
      widget.onChanged?.call(item['value']!);
    });
  }

  void closeOverlay() {
    debugPrint("$greenLog [PossesionDropdown]: line 205");
    isExpanded = false;
    overlayEntry?.remove();
    formProvider.updateExpanded(false);
  }

  Widget buildDropdownItem(
    Map<String, String> item,
    double buttonWidth,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setItemState(item);
        closeOverlay();
      },
      child: Container(
        width: buttonWidth,
        height: widget.containerHeight ?? 50,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.useIcons)
              Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  gewassIconList[index],
                  height: 20,
                  width: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            Center(
              child: Text(
                item['text']!,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
