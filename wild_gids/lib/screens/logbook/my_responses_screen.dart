import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/data_managers/response_api.dart';
import 'package:wildrapport/models/api_models/my_response.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/managers/api_managers/response_manager.dart';

class MyResponsesScreen extends StatefulWidget {
  const MyResponsesScreen({super.key});

  @override
  State<MyResponsesScreen> createState() => _MyResponsesScreenState();
}

class _MyResponsesScreenState extends State<MyResponsesScreen> {
  late Future<List<MyResponse>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MyResponse>> _load() async {
    final apiClient = context.read<ApiClient>();
    final responseApi = ResponseApi(apiClient);
    // Ensure any locally cached responses are submitted before fetching
    try {
      await context.read<ResponseManager>().submitResponses();
    } catch (_) {}
    final raw = await responseApi.getMyResponsesRaw();
    return raw
        .map((e) => MyResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Mijn antwoorden',
              rightIcon: Icons.refresh,
              onLeftIconPressed: () => Navigator.of(context).pop(),
              onRightIconPressed: _refresh,
              showUserIcon: false,
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
            Expanded(
              child: FutureBuilder<List<MyResponse>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Fout bij laden: ${snap.error}'),
                      ),
                    );
                  }
                  final items = snap.data ?? const <MyResponse>[];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Geen antwoorden gevonden'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _ResponseTile(items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final MyResponse r;
  const _ResponseTile(this.r);

  @override
  Widget build(BuildContext context) {
    final qName = r.interaction?.questionnaire?.name;
    final qIdent = r.interaction?.questionnaire?.identifier;
    final questionText = r.question?.text;
    final answerText = r.answer?.text;
    final freeText = r.freeText;
    final ts = DateFormat('dd-MM-yyyy HH:mm').format(r.timestamp.toLocal());
    final conveyMsg = r.conveyance?.messageText;
    final conveyAnimal = r.conveyance?.animalName;
    final conveyTs =
        r.conveyance != null
            ? DateFormat(
              'dd-MM-yyyy HH:mm',
            ).format(r.conveyance!.timestamp.toLocal())
            : null;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (qName != null && qName.isNotEmpty)
              Text(
                qName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
              ),
            if (qIdent != null && qIdent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  qIdent,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            if (qName != null || qIdent != null) const SizedBox(height: 8),
            if (questionText != null && questionText.isNotEmpty)
              Text(
                questionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (answerText != null && answerText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Antwoord: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(answerText)),
                  ],
                ),
              ),
            if (freeText != null && freeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tekst: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(freeText)),
                  ],
                ),
              ),
            if (conveyMsg != null && conveyMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bericht: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(conveyMsg)),
                  ],
                ),
              ),
            if (conveyAnimal != null && conveyAnimal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dier: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(conveyAnimal)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    ts,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (conveyTs != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      conveyTs,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
