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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Консилиум и Заметки',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          if (!widget.isPatientView) ...[
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.getNotes(widget.patientId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Заметок пока нет',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final note = snapshot.data![index];
                      return _buildChatBubble(note);
                    },
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
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Раздел "Заметки консилиума"\nдоступен только медицинскому персоналу',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 16,
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
    final String authorRaw = note['author'] ?? 'Врач';
    final List<String> authorParts = authorRaw.split('|');
    final String name = authorParts[0];
    final String specialty = authorParts.length > 1 ? authorParts[1] : '';

    final String timestampStr = note['timestamp'].toString();
    final String time = timestampStr.length >= 16
        ? timestampStr.substring(11, 16)
        : timestampStr;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.blue.shade900.withOpacity(0.4)
              : Colors.blue.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['content'],
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    specialty.isNotEmpty ? '$name ($specialty)' : name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите заметку...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () async {
                final content = _noteController.text.trim();
                if (content.isNotEmpty) {
                  String authorInfo = "Врач";
                  if (widget.doctor != null) {
                    authorInfo = "${_formatDoctorName(widget.doctor!.name)}|${widget.doctor!.specialization}";
                  }
                  await _dbService.insertNote(widget.patientId, authorInfo, content);
                  _noteController.clear();
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}