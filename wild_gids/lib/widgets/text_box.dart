import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFF6B3F1D), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Raak het dier niet aan als het gewond nof dood is.\n"
            "Gewonde dieren kunnen gevaarlijker zijn.\n"
            "Als het dier dood is, probeer dan contact nop te nemen met de organisatie\n'voorbeeld.com'.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Nummer: 0621234567",
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
