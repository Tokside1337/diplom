import 'package:flutter/material.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/models/doctor.dart';

class CommunicationScreen extends StatefulWidget {
  final int patientId;
  final bool isPatientView;
  final Doctor? doctor;

  const CommunicationScreen({
    super.key,
    required this.patientId,
    this.isPatientView = false,
    this.doctor,
  });

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _noteController = TextEditingController();

  String _formatDoctorName(String fullName) {
    List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return fullName;
    String result = parts[0];
    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        result += ' ${parts[i][0]}.';
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки консилиума'),
      ),
      body: Column(
        children: [
          if (!widget.isPatientView) ...[
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.getNotes(widget.patientId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notes_rounded, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text('Заметок пока нет', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => _buildChatBubble(snapshot.data![index]),
                  );
                },
              ),
            ),
            _buildInputArea(),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_person_rounded, size: 64, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Раздел доступен только медицинскому персоналу',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> note) {
    final colorScheme = Theme.of(context).colorScheme;
    final String authorRaw = note['author'] ?? 'Врач';
    final List<String> authorParts = authorRaw.split('|');
    final String name = authorParts[0];
    final String specialty = authorParts.length > 1 ? authorParts[1] : '';
    final String timestampStr = note['timestamp'].toString();
    final String time = timestampStr.length >= 16 ? timestampStr.substring(11, 16) : timestampStr;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note['content'], style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  specialty.isNotEmpty ? '$name ($specialty)' : name,
                  style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                Text(time, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Введите заметку...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send_rounded),
              onPressed: () async {
                final content = _noteController.text.trim();
                if (content.isNotEmpty) {
                  String authorInfo = "Врач";
                  if (widget.doctor != null) {
                    authorInfo = "${_formatDoctorName(widget.doctor!.name)}|${widget.doctor!.specialization}";
                  }
                  await _dbService.insertNote(widget.patientId, authorInfo, content);
                  _noteController.clear();
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
