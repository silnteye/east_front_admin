import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../../models/post_model.dart";
import "../../services/firestore_service.dart";
import "../../services/providers.dart";
import "dart:io";
import "package:flutter/foundation.dart";
import "package:file_picker/file_picker.dart";
import "package:record/record.dart";
import "package:image_picker/image_picker.dart";
import "package:path_provider/path_provider.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:intl/intl.dart";
import "../../widgets/app_audio_player.dart";

class CreatePostScreen extends ConsumerStatefulWidget {
  final PostModel? post;
  const CreatePostScreen({super.key, this.post});
  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  PostType _type = PostType.text;
  bool _loading = false;
  final List<Map<String, String>> _pollOptions = [
    {"id": "1", "text": ""},
    {"id": "2", "text": ""}
  ];

  String _categoryId = "Political";
  String _language = "English";
  bool _commentsEnabled = true;
  String? _bookSubcategory;

  // Multiple picked platform files
  final List<PlatformFile> _pickedPlatformFiles = [];

  // Voice recording state
  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _recordedPath;

  // Poll expiry
  bool _pollHasExpiry = false;
  DateTime? _pollExpiryDate;
  TimeOfDay? _pollExpiryTime;

  // Auto delete fields
  bool _autoDeleteEnabled = false;
  DateTime? _autoDeleteDate;
  TimeOfDay? _autoDeleteTime;

  @override
  void dispose() {
    _audioRecorder?.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      final p = widget.post!;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description;
      _type = p.type;
      _urlCtrl.text = p.externalUrl ?? p.imageUrl ?? p.videoUrl ?? p.pdfUrl ?? p.audioUrl ?? "";
      _categoryId = p.categoryId ?? "Political";
      _language = p.language;
      _commentsEnabled = p.commentsEnabled;
      _bookSubcategory = p.bookSubcategory;
      if (p.pollExpiryDate != null) {
        _pollHasExpiry = true;
        _pollExpiryDate = p.pollExpiryDate;
        _pollExpiryTime = TimeOfDay.fromDateTime(p.pollExpiryDate!);
      }
      _autoDeleteEnabled = p.autoExpire;
      if (p.expireDate != null) {
        _autoDeleteDate = p.expireDate;
        _autoDeleteTime = TimeOfDay.fromDateTime(p.expireDate!);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      _audioRecorder ??= AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        String? path;
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = "${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a";
        }
        await _audioRecorder!.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path ?? '');
        setState(() {
          _isRecording = true;
          _recordedPath = null;
          _urlCtrl.text = "Recording voice...";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Microphone permission/access error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_audioRecorder != null) {
        final path = await _audioRecorder!.stop();
        setState(() {
          _isRecording = false;
          _recordedPath = path;
          if (path != null) {
            _urlCtrl.text = "Voice note recorded";
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error stopping recorder: $e")));
    }
  }

  Future<void> _cancelRecording() async {
    try {
      if (_audioRecorder != null) {
        await _audioRecorder!.stop();
        setState(() {
          _isRecording = false;
          _recordedPath = null;
          _urlCtrl.clear();
        });
      }
    } catch (_) {}
  }

  Future<String> _uploadRecordedFile(String path) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/${DateTime.now().millisecondsSinceEpoch}_voice_note.m4a');
    final metadata = SettableMetadata(contentType: 'audio/mp4');
    final xFile = XFile(path);
    if (kIsWeb) {
      final bytes = await xFile.readAsBytes();
      await storageRef.putData(bytes, metadata);
    } else {
      await storageRef.putFile(File(path), metadata);
    }
    return storageRef.getDownloadURL();
  }

  Future<void> _pickFiles() async {
    FileType pickType = FileType.any;
    List<String>? extensions;

    if (_type == PostType.image) {
      pickType = FileType.custom;
      extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    } else if (_type == PostType.video) {
      pickType = FileType.custom;
      extensions = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'flv'];
    } else if (_type == PostType.audio) {
      pickType = FileType.custom;
      extensions = ['wav', 'mp3', 'aac', 'm4a', 'ogg'];
    } else if (_type == PostType.pdf) {
      pickType = FileType.custom;
      extensions = ['pdf'];
    }

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: pickType,
        allowedExtensions: extensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedPlatformFiles.clear();
          _pickedPlatformFiles.addAll(result.files);
          if (result.files.length == 1) {
            _urlCtrl.text = result.files.first.name;
          } else {
            _urlCtrl.text = "${result.files.length} files selected";
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<String> _uploadPlatformFile(PlatformFile file) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/${DateTime.now().millisecondsSinceEpoch}_${file.name}');

    // Fallback content-types based on file extension
    String? contentType;
    final nameLower = file.name.toLowerCase();
    if (nameLower.endsWith('.jpg') || nameLower.endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (nameLower.endsWith('.png')) {
      contentType = 'image/png';
    } else if (nameLower.endsWith('.gif')) {
      contentType = 'image/gif';
    } else if (nameLower.endsWith('.webp')) {
      contentType = 'image/webp';
    } else if (nameLower.endsWith('.mp4')) {
      contentType = 'video/mp4';
    } else if (nameLower.endsWith('.mov')) {
      contentType = 'video/quicktime';
    } else if (nameLower.endsWith('.mp3')) {
      contentType = 'audio/mpeg';
    } else if (nameLower.endsWith('.wav')) {
      contentType = 'audio/wav';
    } else if (nameLower.endsWith('.pdf')) {
      contentType = 'application/pdf';
    }

    final metadata = SettableMetadata(contentType: contentType);
    if (kIsWeb) {
      await storageRef.putData(file.bytes!, metadata);
    } else {
      await storageRef.putFile(File(file.path!), metadata);
    }
    return storageRef.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      String finalUrl = _urlCtrl.text.trim();
      List<String> uploadedUrls = [];

      final isMedia = _type != PostType.text && _type != PostType.poll && _type != PostType.link;

      if (_recordedPath != null && _type == PostType.audio) {
        finalUrl = await _uploadRecordedFile(_recordedPath!);
      } else if (_pickedPlatformFiles.isNotEmpty && isMedia) {
        // Upload all picked files
        for (final file in _pickedPlatformFiles) {
          final url = await _uploadPlatformFile(file);
          uploadedUrls.add(url);
        }
        finalUrl = uploadedUrls.first;
      }

      // Poll expiry datetime
      DateTime? expiryDateTime;
      if (_type == PostType.poll && _pollHasExpiry && _pollExpiryDate != null) {
        final t = _pollExpiryTime ?? const TimeOfDay(hour: 23, minute: 59);
        expiryDateTime = DateTime(
          _pollExpiryDate!.year, _pollExpiryDate!.month, _pollExpiryDate!.day,
          t.hour, t.minute,
        );
      }

      // Auto delete expiry
      DateTime? autoDeleteDateTime;
      if (_autoDeleteEnabled && _autoDeleteDate != null) {
        final t = _autoDeleteTime ?? const TimeOfDay(hour: 23, minute: 59);
        autoDeleteDateTime = DateTime(
          _autoDeleteDate!.year, _autoDeleteDate!.month, _autoDeleteDate!.day,
          t.hour, t.minute,
        );
      }

      String derivedTitle = _descCtrl.text.trim();
      if (derivedTitle.contains("\n")) {
        derivedTitle = derivedTitle.split("\n").first.trim();
      }
      if (derivedTitle.length > 55) {
        derivedTitle = "${derivedTitle.substring(0, 55).trim()}...";
      }
      if (derivedTitle.isEmpty) {
        derivedTitle = "New Post";
      }

      final data = {
        "title": derivedTitle,
        "description": _descCtrl.text.trim(),
        "type": _type.name,
        "authorId": uid,
        "categoryId": _categoryId,
        "language": _language,
        "commentsEnabled": _commentsEnabled,
        "views": widget.post?.views ?? 0,
        "shareCount": widget.post?.shareCount ?? 0,
        "isPinned": widget.post?.isPinned ?? false,
        "allowDownload": true,
        "autoExpire": _autoDeleteEnabled,
        "expireDate": autoDeleteDateTime != null ? Timestamp.fromDate(autoDeleteDateTime) : null,
        "createdAt": widget.post == null ? FieldValue.serverTimestamp() : widget.post!.createdAt,
        if (_type == PostType.image) "imageUrl": finalUrl,
        if (_type == PostType.video) "videoUrl": finalUrl,
        if (_type == PostType.audio) "audioUrl": finalUrl,
        if (_type == PostType.pdf) "pdfUrl": finalUrl,
        if (_type == PostType.link) "externalUrl": _urlCtrl.text.trim(),
        // Store all uploaded urls
        if (uploadedUrls.length > 1) "mediaUrls": uploadedUrls,
        if (_type == PostType.poll) "pollOptions":
          _pollOptions.map((o) => {"id": o["id"], "text": o["text"], "votes": 0}).toList(),
        if (expiryDateTime != null) "pollExpiryDate": Timestamp.fromDate(expiryDateTime),
        "pollEnded": widget.post?.pollEnded ?? false,
        "bookSubcategory": _categoryId == "Books" ? _bookSubcategory : null,
      };

      if (widget.post != null) {
        await FirestoreService.instance.updatePost(postId: widget.post!.id, data: data);
      } else {
        await FirestoreService.instance.createPost(data: data);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF2F2FA);
    final cardColor = isDark ? const Color(0xFF1A1A3E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFill = isDark ? Colors.white10 : Colors.black12;
    final cs = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text(isEdit ? "Edit Post" : "New Post",
            style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop()),
        actions: [
          _loading
              ? Padding(padding: const EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2)))
              : TextButton(
                  onPressed: _submit,
                  child: Text(isEdit ? "Update" : "Publish",
                      style: GoogleFonts.inter(
                          color: cs.primary,
                          fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            // Post Type Selector
            Text("Post Type", style: GoogleFonts.inter(color: textColor.withAlpha(180), fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 12)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PostType.values.map((t) {
                  final selected = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.name.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => setState(() { _type = t; _pickedPlatformFiles.clear(); _urlCtrl.clear(); }),
                      selectedColor: cs.primary,
                      backgroundColor: inputFill,
                      labelStyle: GoogleFonts.inter(
                          color: selected ? Colors.white : textColor.withAlpha(150),
                          fontWeight: FontWeight.bold, fontSize: 11),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),



            // Description
            _InputField(label: "Description", controller: _descCtrl, textColor: textColor, fillColor: inputFill,
              maxLines: 14, validator: (v) => v == null || v.isEmpty ? "Description is required" : null),
            const SizedBox(height: 14),

            // Category + Language
            Row(children: [
              categoriesAsync.when(
                loading: () => const Expanded(child: SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))),
                error: (err, _) => Expanded(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
                data: (catsList) {
                  final cats = catsList.map((c) => c["name"] as String).toList();
                  if (cats.isEmpty) cats.add("Political"); // fallback
                  final selectedVal = cats.contains(_categoryId) ? _categoryId : cats.first;
                  return Expanded(
                    child: _DropdownField(
                      label: "Category",
                      value: selectedVal,
                      items: cats,
                      fillColor: inputFill,
                      textColor: textColor,
                      cardColor: cardColor,
                      onChanged: (v) {
                        setState(() {
                          _categoryId = v!;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(child: _DropdownField(label: "Language", value: _language,
                items: const ["English", "Urdu"], fillColor: inputFill, textColor: textColor, cardColor: cardColor, onChanged: (v) => setState(() => _language = v!))),
            ]),
            if (_categoryId == "Books") ...[
              const SizedBox(height: 14),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.instance.getBookSubcategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
                  }
                  final subcategories = snapshot.data ?? [];
                  if (subcategories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "No subcategories created. Go to drawer > Manage Book Subcategories to create them first.",
                        style: GoogleFonts.inter(color: Colors.amber[800], fontSize: 13),
                      ),
                    );
                  }

                  final hasMatch = subcategories.any((s) => s["id"] == _bookSubcategory);
                  if (!hasMatch && subcategories.isNotEmpty) {
                    _bookSubcategory = subcategories.first["id"] as String;
                  }

                  final items = subcategories.map((s) => s["name"] as String).toList();
                  final selectedSub = subcategories.firstWhere(
                    (s) => s["id"] == _bookSubcategory,
                    orElse: () => subcategories.first,
                  );

                  return _DropdownField(
                    label: "Book Subcategory",
                    value: selectedSub["name"] as String,
                    items: items,
                    fillColor: inputFill,
                    textColor: textColor,
                    cardColor: cardColor,
                    onChanged: (v) {
                      if (v != null) {
                        final matched = subcategories.firstWhere((s) => s["name"] == v);
                        setState(() {
                          _bookSubcategory = matched["id"] as String;
                        });
                      }
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 14),

            // Comments toggle
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: Text("Enable Comments", style: GoogleFonts.inter(color: textColor)),
                value: _commentsEnabled,
                onChanged: (v) => setState(() => _commentsEnabled = v),
                activeColor: cs.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
            const SizedBox(height: 14),

            // Auto Delete Toggle
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text("Enable Auto Delete", style: GoogleFonts.inter(color: textColor)),
                    subtitle: _autoDeleteEnabled
                        ? Text(
                            _autoDeleteDate != null
                                ? "${DateFormat('dd MMM yyyy').format(_autoDeleteDate!)} at ${_autoDeleteTime?.format(context) ?? '23:59'}"
                                : "Select deletion date",
                            style: GoogleFonts.inter(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w500))
                        : null,
                    value: _autoDeleteEnabled,
                    activeColor: cs.primary,
                    onChanged: (v) async {
                      setState(() => _autoDeleteEnabled = v);
                      if (v && _autoDeleteDate == null) {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null && mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 23, minute: 59),
                          );
                          setState(() {
                            _autoDeleteDate = date;
                            _autoDeleteTime = time;
                          });
                        }
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (_autoDeleteEnabled && _autoDeleteDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton.icon(
                        icon: Icon(Icons.calendar_today, size: 14, color: cs.primary),
                        label: Text("Change auto delete date/time", style: GoogleFonts.inter(color: cs.primary, fontSize: 12)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _autoDeleteDate!,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _autoDeleteTime ?? const TimeOfDay(hour: 23, minute: 59),
                            );
                            setState(() {
                              _autoDeleteDate = date;
                              _autoDeleteTime = time;
                            });
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Media section
            if (_type != PostType.text && _type != PostType.poll) ...[
              Text("Media", style: GoogleFonts.inter(color: textColor.withAlpha(180), fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 12)),
              const SizedBox(height: 8),
              // File picker area
              GestureDetector(
                onTap: _type == PostType.link ? null : _pickFiles,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withAlpha(60)),
                  ),
                  child: _pickedPlatformFiles.isEmpty
                      ? Column(children: [
                          Icon(_postTypeIcon(_type), color: cs.primary, size: 36),
                          const SizedBox(height: 8),
                          Text(_type == PostType.audio ? "Tap to select local audio file" : "Tap to select file(s)", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                          if (_type == PostType.image) Text("Multiple images supported", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11)),
                        ])
                      : Column(children: [
                          ..._pickedPlatformFiles.asMap().entries.map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_postTypeIcon(_type), color: cs.primary, size: 20),
                            title: Text(e.value.name, style: GoogleFonts.inter(color: textColor, fontSize: 12), overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                              onPressed: () => setState(() => _pickedPlatformFiles.removeAt(e.key)),
                            ),
                          )),
                          if (_type == PostType.image)
                            TextButton.icon(
                              icon: Icon(Icons.add, color: cs.primary, size: 16),
                              label: Text("Add more", style: GoogleFonts.inter(color: cs.primary, fontSize: 12)),
                              onPressed: _pickFiles,
                            ),
                        ]),
                ),
              ),
              // Live Voice note panel (only for Audio post type)
              if (_type == PostType.audio) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.withAlpha(20) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isRecording ? Colors.redAccent : cs.primary.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.redAccent : cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isRecording
                                  ? "Voice note recording in progress..."
                                  : (_recordedPath != null ? "Voice Note Recorded! ✅" : "Or Record Live Voice Note"),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isRecording && _recordedPath == null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: Text("Start Recording", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _startRecording,
                            ),
                          if (_isRecording) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.stop, size: 16),
                              label: Text("Stop & Save", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _stopRecording,
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: _cancelRecording,
                              child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
                            ),
                          ],
                          if (_recordedPath != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: AppAudioPlayer(audioUrl: _recordedPath!),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.mic, size: 16),
                                  label: Text("Re-Record", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: _startRecording,
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _recordedPath = null;
                                      _urlCtrl.clear();
                                    });
                                  },
                                  child: const Text("Delete Recording", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Or paste URL (Only shown for Link type)
              if (_type == PostType.link)
                _InputField(label: _urlLabel(_type), controller: _urlCtrl, textColor: textColor, fillColor: inputFill,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Provide URL";
                    return null;
                  }),
              const SizedBox(height: 14),
            ],

            // Poll options + expiry
            if (_type == PostType.poll) ...[
              Text("Poll Options", style: GoogleFonts.inter(color: textColor.withAlpha(180), fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 12)),
              const SizedBox(height: 8),
              ..._pollOptions.asMap().entries.map((entry) {
                final i = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                      child: TextFormField(
                        style: TextStyle(color: textColor),
                        initialValue: _pollOptions[i]["text"],
                        onChanged: (v) => _pollOptions[i]["text"] = v,
                        decoration: InputDecoration(
                          labelText: "Option ${i + 1}",
                          labelStyle: TextStyle(color: textColor.withAlpha(150)),
                          filled: true, fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                    if (_pollOptions.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _pollOptions.removeAt(i)),
                      ),
                  ]),
                );
              }),
              TextButton.icon(
                icon: Icon(Icons.add_circle_outline, color: cs.primary),
                label: Text("Add Option", style: GoogleFonts.inter(color: cs.primary)),
                onPressed: () => setState(() => _pollOptions.add({"id": DateTime.now().millisecondsSinceEpoch.toString(), "text": ""})),
              ),
              const SizedBox(height: 12),
              // Poll Expiry
              Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: Text("Set Expiry Date & Time", style: GoogleFonts.inter(color: textColor)),
                  subtitle: _pollHasExpiry
                      ? Text("${_pollExpiryDate != null ? '${_pollExpiryDate!.day}/${_pollExpiryDate!.month}/${_pollExpiryDate!.year}' : 'Select date'} ${_pollExpiryTime?.format(context) ?? ''}",
                          style: GoogleFonts.inter(color: cs.primary, fontSize: 12))
                      : null,
                  value: _pollHasExpiry,
                  activeColor: cs.primary,
                  onChanged: (v) async {
                    setState(() => _pollHasExpiry = v);
                    if (v) {
                      final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date != null && mounted) {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
                        setState(() { _pollExpiryDate = date; _pollExpiryTime = time; });
                      }
                    }
                  },
                ),
              ),
              if (_pollHasExpiry && _pollExpiryDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today, size: 14, color: cs.primary),
                    label: Text("Change date/time", style: GoogleFonts.inter(color: cs.primary, fontSize: 12)),
                    onPressed: () async {
                      final date = await showDatePicker(context: context, initialDate: _pollExpiryDate!,
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date != null && mounted) {
                        final time = await showTimePicker(context: context, initialTime: _pollExpiryTime ?? const TimeOfDay(hour: 23, minute: 59));
                        setState(() { _pollExpiryDate = date; _pollExpiryTime = time; });
                      }
                    },
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    ),
  ),
),
);
}

  String _urlLabel(PostType t) {
    switch (t) {
      case PostType.image: return "Image URL (or pick file above)";
      case PostType.video: return "Video URL (or pick file above)";
      case PostType.audio: return "Audio URL (or pick file above)";
      case PostType.pdf: return "PDF URL (or pick file above)";
      case PostType.link: return "External URL";
      default: return "URL";
    }
  }

  IconData _postTypeIcon(PostType t) {
    switch (t) {
      case PostType.image: return Icons.image_outlined;
      case PostType.video: return Icons.videocam_outlined;
      case PostType.audio: return Icons.headphones_outlined;
      case PostType.pdf: return Icons.picture_as_pdf_outlined;
      case PostType.link: return Icons.link;
      default: return Icons.article_outlined;
    }
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color textColor;
  final Color fillColor;
  final int maxLines;
  final String? Function(String?)? validator;
  const _InputField({required this.label, required this.controller, required this.textColor, required this.fillColor, this.maxLines = 1, this.validator});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withAlpha(150)),
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
      validator: validator,
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Color fillColor;
  final Color textColor;
  final Color cardColor;
  final ValueChanged<String?> onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.fillColor, required this.textColor, required this.cardColor, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: items.contains(value) ? value : items.first,
      dropdownColor: cardColor,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withAlpha(150)),
        filled: true, fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}
