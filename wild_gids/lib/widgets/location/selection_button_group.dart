import 'package:flutter/material.dart';

typedef SelectionButton = ({
  String text,
  IconData? icon,
  String? imagePath,
});

class SelectionButtonGroup extends StatelessWidget {
  final List<SelectionButton> buttons;
  final Function(String) onStatusSelected;
  final String? title;

  const SelectionButtonGroup({
    Key? key,
    required this.buttons,
    required this.onStatusSelected,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                final button = buttons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: () => onStatusSelected(button.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (button.imagePath != null)
                          Image.asset(
                            button.imagePath!,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 50),
                          )
                        else if (button.icon != null)
                          Icon(button.icon, size: 50)
                        else
                          const SizedBox(width: 50),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            button.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
