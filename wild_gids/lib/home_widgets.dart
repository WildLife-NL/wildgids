import 'package:flutter/material.dart';
import 'widgets/picture_frame.dart';
import 'widgets/big_button.dart';
import 'widgets/filter_button.dart';
import 'widgets/filter_icon_buttons.dart';
import 'widgets/number_input.dart';
import 'widgets/slide_bar.dart';
import 'widgets/small_button.dart';
import 'widgets/square_button.dart';
import 'widgets/text_box.dart';
import 'widgets/input_field.dart';
import 'widgets/table.dart';
import 'widgets/time_date.dart';
import 'widgets/deer_animation.dart';

class HomeWidgets extends StatelessWidget {
  const HomeWidgets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numberValues = [
      '1', '5', '10', '15', '20', '25', '30', '35', '40',
      '45', '50', '60', '70', '80', '90', '100+',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PictureFrame(),
                  const SizedBox(height: 24),
                  const ResizableInputField(
                    hintText: "replace with your text",
                    width: double.infinity,
                    height: 48,
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      return BigButton(
                        text: "Click me",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeerAnimationPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilterButton(
                    text: "Filter age and gender Button",
                    selected: false,
                    onPressed: () {
                      print('FilterButton pressed');
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GenderButton(
                        icon: Icons.female,
                        selected: false,
                        onPressed: () {
                          print('Female GenderButton pressed');
                        },
                      ),
                      const SizedBox(width: 24),
                      GenderButton(
                        icon: Icons.male,
                        selected: false,
                        onPressed: () {
                          print('Male GenderButton pressed');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  NumberInput(
                    values: numberValues,
                    initialIndex: 0,
                    width: 100,
                    height: 120,
                    onChanged: (index) {
                      print('NumberInput selected: ${numberValues[index]}');
                    },
                  ),
                  const SizedBox(height: 24),
                  const IntensitySlider(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: SmallButton(
                      text: "Small Button",
                      onPressed: () {
                        print('SmallButton pressed');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareButton(
                        imageAssetPath: 'assets/icons/agriculture.png',
                        text: "Gewasschade",
                        onPressed: () {
                          print('SquareButton 1 pressed');
                        },
                      ),
                      const SizedBox(width: 24),
                      SquareButton(
                        imageAssetPath: 'assets/icons/animal.png',
                        text: "Diergezondheid",
                        onPressed: () {
                          print('SquareButton 2 pressed');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const InfoBox(),
                  const SizedBox(height: 24),
                  CustomDateTimePicker(),
                  const SizedBox(height: 24),
                  OverzichtTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
