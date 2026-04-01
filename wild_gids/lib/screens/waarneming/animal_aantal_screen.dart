import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_details_screen.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_summary_screen.dart';

class AnimalAantalScreen extends StatefulWidget {
  const AnimalAantalScreen({super.key});

  @override
  State<AnimalAantalScreen> createState() => _AnimalAantalScreenState();
}

class _AnimalAantalScreenState extends State<AnimalAantalScreen> {
  int currentCount = 0;

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sightingManager =
        context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();
    final selectedAnimal = sighting?.animalSelected;

    if (selectedAnimal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F4),
        body: const Center(
          child: Text('No animal selected'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            CustomAppBar(
              
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: _handleBackNavigation,
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
          
            // Main card container
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: const Color(0xFF999999),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Question text
                          Text(
                            'Hoeveel van deze dieren\nheb je gezien?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Animal card with image
                          Center(
                            child: SizedBox(
                              width: 180,
                          
                              child: Card(
                                
                                shadowColor: const Color.fromARGB(133, 0, 0, 0).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: const Color(0xFF999999),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Image area
                                    Center(
                                      child: SizedBox(
                                        width: 180,
                                        height: 150,
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              color: Colors.white,
                                              
                                            ),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                              child: SizedBox.expand(
                                                child: selectedAnimal.animalImagePath !=
                                                        null
                                                    ? Image(
                                                        image: AssetImage(
                                                          selectedAnimal.animalImagePath!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
                                                          size: 50,
                                                          color: Colors.grey[400],
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Divider line
                                    Container(
                                      height: 1,
                                      color: const Color(0xFF999999),
                                      width: 180,
                                    ),
                                    // Name area
                                    Container(
                                      width: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(14),
                                          bottomRight: Radius.circular(14),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        selectedAnimal.animalName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Aantal label
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Aantal:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Stepper with - and + buttons
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color(0xFF999999),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Minus button
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(40),
                                      bottomLeft: Radius.circular(40),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: currentCount > 0
                                            ? () {
                                                setState(() {
                                                  currentCount--;
                                                });
                                              }
                                            : null,
                                        splashColor:
                                            Colors.black.withValues(alpha: 0.1),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(40),
                                              bottomLeft: Radius.circular(40),
                                            ),
                                          ),
                                          child: SizedBox.expand(
                                            child: Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Number display
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      '$currentCount',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                // Plus button
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(40),
                                      bottomRight: Radius.circular(40),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            currentCount++;
                                          });
                                        },
                                        splashColor:
                                            Colors.black.withValues(alpha: 0.1),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(25),
                                              bottomRight: Radius.circular(25),
                                            ),
                                          ),
                                          child: SizedBox.expand(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Quick add buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQuickAddButton('+ 10', 10),
                              const SizedBox(width: 15),
                              _buildQuickAddButton('+ 20', 20),
                              const SizedBox(width: 15),
                              _buildQuickAddButton('+ 50', 50),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // More details button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: const Color(0xFF999999),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                if (currentCount > 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AnimalWaarnemingDetailsScreen(
                                            animalIndex: 0,
                                            totalCount: currentCount,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                '+ Meer details toevoegen?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom buttons
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFF999999),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Vorige',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (currentCount > 0) {
                            // Navigate directly to summary, skipping details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimalWaarnemingSummaryScreen(
                                      totalCount: currentCount,
                                    ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Volgende',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox.shrink(),
    );
  }

  Widget _buildQuickAddButton(String label, int amount) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Color(0xFF999999),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
      ),
      onPressed: () {
        setState(() {
          currentCount += amount;
        });
      },
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
