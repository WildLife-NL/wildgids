import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';

class AnimalsQuizScreen extends StatefulWidget {
  const AnimalsQuizScreen({super.key});

  @override
  State<AnimalsQuizScreen> createState() => _AnimalsQuizScreenState();
}

class _AnimalsQuizScreenState extends State<AnimalsQuizScreen> {
  final _rng = Random();

  late List<_Question> _questions;
  int _index = 0;
  int _score = 0;
  int? _selectedOption; // for feedback
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _index = 0;
    _score = 0;
    _selectedOption = null;
    _finished = false;
  }

  List<_Question> _buildQuestions() {
    final base = <_Question>[
      _Question(
        prompt: 'Waar leeft de vos meestal?',
        imageAsset: 'assets/black_icons_animal/vos_black_icon-removebg-preview.png',
        options: ['Savanne', 'Bos en velden', 'Woestijn', 'Open zee'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'Wat is de wolf vooral?',
        imageAsset: 'assets/black_icons_animal/wolf_black_icon-removebg-preview.png',
        options: ['Herbivoor', 'Carnivoor', 'Planktoneter', 'Alleseter'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'Wat eet een ree voornamelijk?',
        imageAsset: 'assets/black_icons_animal/ree_black_icon-removebg-preview.png',
        options: ['Vlees', 'Planten', 'Insecten', 'Vissen'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'Waar leeft de das graag?',
        imageAsset: 'assets/black_icons_animal/das_black_icon-removebg-preview.png',
        options: ['Ondergronds in burchten', 'Op bomen', 'In grotten aan zee', 'In steden'],
        correctIndex: 0,
      ),
      _Question(
        prompt: 'De bever staat bekend om?',
        imageAsset: 'assets/black_icons_animal/bever_black_icon-removebg-preview.png',
        options: ['Snelle sprint', 'Burchten en dammen bouwen', 'Grote sprongen', 'Hoge zang'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'Het wild zwijn is een ...',
        imageAsset: 'assets/black_icons_animal/Wild_Zwijn_black_icon-removebg-preview.png',
        options: ['Strikte vleeseter', 'Strikte planteneter', 'Alleseter', 'Alleen fruiteter'],
        correctIndex: 2,
      ),
      _Question(
        prompt: 'Waar vind je vaak een eekhoorn?',
        imageAsset: 'assets/black_icons_animal/eekhoorn_black_icon-removebg-preview.png',
        options: ['Op grasvlaktes', 'In bossen (bomen)', 'Onder water', 'Woestijn'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'De otter leeft vooral in ...',
        imageAsset: 'assets/black_icons_animal/otter_black_icon-removebg-preview.png',
        options: ['Bergen', 'Stad', 'Rivier- en merengebieden', 'Woestijn'],
        correctIndex: 2,
      ),
      _Question(
        prompt: 'Wat is een hermelijn in de winter vaak?',
        imageAsset: 'assets/black_icons_animal/Hermelijn_black_icon-removebg-preview.png',
        options: ['Zwart', 'Wit', 'Rood', 'Geel'],
        correctIndex: 1,
      ),
      _Question(
        prompt: 'De wisent is het Europese ...',
        imageAsset: 'assets/black_icons_animal/Wisent_black_icon-removebg-preview.png',
        options: ['Hert', 'Paard', 'Bizon', 'Geit'],
        correctIndex: 2,
      ),
    ];
    base.shuffle(_rng);
    return base.take(10).toList();
  }

  void _select(int i) {
    if (_selectedOption != null) return; // already answered
    setState(() {
      _selectedOption = i;
      if (i == _questions[_index].correctIndex) {
        _score++;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() {
        _finished = true;
      });
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
    });
  }

  void _restart() {
    setState(() {
      _questions = _buildQuestions();
      _index = 0;
      _score = 0;
      _selectedOption = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Terug',
        ),
        title: const Text('Dierenquiz', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: AppColors.lightMintGreen,
        elevation: 0,
      ),
      backgroundColor: AppColors.lightMintGreen,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _finished ? _buildFinished() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _chip('Vraag ${_index + 1}/${_questions.length}'),
            _chip('Score $_score'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.darkGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              q.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.pets, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkGreen, width: 1.5),
          ),
          child: Text(
            q.prompt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < q.options.length; i++) ...[
          _answerButton(q, i),
          const SizedBox(height: 12),
        ],
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _selectedOption == null ? null : _next,
          child: Text(_index + 1 >= _questions.length ? 'Einde' : 'Volgende'),
        ),
      ],
    );
  }

  Widget _answerButton(_Question q, int i) {
    final selected = _selectedOption == i;
    final correct = q.correctIndex == i;
    Color bg;
    Color fg = Colors.white;
    if (_selectedOption == null) {
      bg = AppColors.darkGreen;
    } else if (selected && correct) {
      bg = Colors.green.shade700;
    } else if (selected && !correct) {
      bg = Colors.red.shade700;
    } else {
      bg = AppColors.darkGreen;
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _selectedOption == null ? () => _select(i) : null,
      child: Text(q.options[i]),
    );
  }

  Widget _buildFinished() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chip('Klaar!'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkGreen, width: 1.5),
          ),
          child: Text(
            'Je score: $_score van ${_questions.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _restart,
          child: const Text('Opnieuw spelen'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Terug naar hoofdscherm'),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkGreen, width: 1.5),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _Question {
  final String prompt;
  final String imageAsset;
  final List<String> options;
  final int correctIndex;

  _Question({
    required this.prompt,
    required this.imageAsset,
    required this.options,
    required this.correctIndex,
  });
}
