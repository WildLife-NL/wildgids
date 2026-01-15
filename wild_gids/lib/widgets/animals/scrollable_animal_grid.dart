import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/widgets/animals/animal_grid.dart';

class ScrollableAnimalGrid extends StatelessWidget {
  final List<AnimalModel>? animals;
  final bool isLoading;
  final String? error;
  final ScrollController scrollController;
  final Function(AnimalModel) onAnimalSelected;
  final VoidCallback? onRetry;

  const ScrollableAnimalGrid({
    super.key,
    required this.animals,
    required this.isLoading,
    this.error,
    required this.scrollController,
    required this.onAnimalSelected,
    this.onRetry,
  });

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/loaders/loading_paw.json',
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            frameRate: FrameRate(60),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Fout: $error'),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Opnieuw proberen'),
              ),
            ],
          ],
        ),
      );
    }

    if (animals == null || animals!.isEmpty) {
      return const Center(child: Text('Geen dieren gevonden'));
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: AnimalGrid(animals: animals!, onAnimalSelected: onAnimalSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: _buildContent(),
      ),
    );
  }
}

