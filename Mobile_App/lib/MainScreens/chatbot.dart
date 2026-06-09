import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatbotScreen extends StatefulWidget {
  final String? imageResult;
  final String? strokeResult;
  final String? temperature;
  final String? pressure;
  final String? generalHealth;

  const ChatbotScreen({
    super.key,
    this.imageResult,
    this.strokeResult,
    this.temperature,
    this.pressure,
    this.generalHealth,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}//--------------------------------------------------------------------------------------------------------------------------------------------------------
class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {

  static const String _baseUrl = 'http://10.0.2.2:8000';

  final List<_Message> _messages = [];

  final TextEditingController _input =
      TextEditingController();

  final ScrollController _scroll =
      ScrollController();

  final AudioPlayer _player = AudioPlayer();

  bool _sending = false;

  bool _isPlaying = false;

  String? _playingUrl;

  late String _userId;

  @override
  void initState() {
    super.initState();

    final user =
        Supabase.instance.client.auth.currentUser;

    _userId =
        user?.id ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';

    _sendInitialData();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      final locale =
          Localizations.localeOf(context)
              .languageCode;

      final isArabic = locale == "ar";

      _addBotMessage(
        isArabic
            ? 'مرحباً 👋\nأنا مساعدك الطبي الذكي.\n\nيمكنني مساعدتك في فهم نتائجك الطبية والإجابة على أسئلتك.'
            : 'Hello 👋\nI am your smart medical assistant.\n\nI can help explain your medical results and answer your health questions.',
        null,
      );
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _player.dispose();

    super.dispose();
  }

  Future<void> _sendInitialData() async {
    final body = <String, dynamic>{
      'user_id': _userId,
    };

    if (widget.imageResult != null) {
      body['image_result'] = widget.imageResult;
    }

    if (widget.strokeResult != null) {
      body['stroke_result'] = widget.strokeResult;
    }

    if (widget.temperature != null) {
      body['temperature'] = widget.temperature;
    }

    if (widget.pressure != null) {
      body['pressure'] = widget.pressure;
    }

    if (widget.generalHealth != null) {
      body['general_health'] = widget.generalHealth;
    }

    if (body.length == 1) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/update_data'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode(body),
      );
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();

    if (text.isEmpty || _sending) return;

    _input.clear();

    setState(() {
      _messages.add(
        _Message(
          text: text,
          isUser: true,
        ),
      );

      _sending = true;
    });

    _scrollDown();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/chat'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'user_id': _userId,
          'user_input': text,
          'image_result':
              widget.imageResult ?? '',
          'stroke_result':
              widget.strokeResult ?? '',
          'temperature':
              widget.temperature ?? '',
          'pressure':
              widget.pressure ?? '',
          'general_health':
              widget.generalHealth ?? '',
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(res.bodyBytes),
        );

        final reply =
            data['reply'] as String? ?? '...';

        final audioUrl =
            data['audio'] as String?;

        _addBotMessage(reply, audioUrl);
      } else {

        final isArabic =
            Localizations.localeOf(context)
                    .languageCode ==
                "ar";

        _addBotMessage(
          isArabic
              ? 'حدث خطأ في الاتصال بالسيرفر.'
              : 'Server connection error.',
          null,
        );
      }
    } catch (_) {

      final isArabic =
          Localizations.localeOf(context)
                  .languageCode ==
              "ar";

      _addBotMessage(
        isArabic
            ? 'تعذر الاتصال بالسيرفر.'
            : 'Unable to connect to server.',
        null,
      );
    }

    setState(() {
      _sending = false;
    });

    _scrollDown();
  }

  void _addBotMessage(
    String text,
    String? audioUrl,
  ) {
    final hasAlert =
        text.contains('⚠️') ||
        text.contains('خطر') ||
        text.contains('warning') ||
        text.contains('danger');

    setState(() {
      _messages.add(
        _Message(
          text: text,
          isUser: false,
          audioUrl: audioUrl,
          hasAlert: hasAlert,
        ),
      );
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,

          duration: const Duration(
            milliseconds: 300,
          ),

          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fixAudioUrl(String url) {
    return url.replaceAll(
      '127.0.0.1',
      '10.0.2.2',
    );
  }

  Future<void> _toggleAudio(String url) async {
    try {
      final fixedUrl = _fixAudioUrl(url);

      if (_isPlaying &&
          _playingUrl == url) {

        await _player.stop();

        setState(() {
          _isPlaying = false;
          _playingUrl = null;
        });

        return;
      }

      await _player.stop();

      await _player.play(
        UrlSource(fixedUrl),
        mode: PlayerMode.mediaPlayer,
      );

      setState(() {
        _isPlaying = true;
        _playingUrl = url;
      });

      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _playingUrl = null;
          });
        }
      });
    } catch (_) {}
  }

  bool get _hasData =>
      widget.imageResult != null ||
      widget.strokeResult != null ||
      widget.temperature != null ||
      widget.pressure != null ||
      widget.generalHealth != null;

Widget _suggestionChip(String text) {

  final isDark =
      Theme.of(context).brightness ==
      Brightness.dark;

  return GestureDetector(

    onTap: () {

      _input.text = text;

      _send();
    },

    child: Container(

      margin: const EdgeInsets.only(
        right: 8,
      ),

      padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),

      decoration: BoxDecoration(

        color:
            isDark
                ? const Color(0xFF1F2937)
                : Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),

      child: Center(
        child: Text(
          text,

          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final primary =
        theme.colorScheme.primary;

    final isDark =
        theme.brightness ==
        Brightness.dark;

    final locale =
        Localizations.localeOf(context)
            .languageCode;

    final isArabic = locale == "ar";

    return Directionality(
      textDirection:
          isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,

      child: Scaffold(

        backgroundColor:
            isDark
                ? const Color(0xFF111827)
                : const Color(0xFFF7F8FC),

        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,

          backgroundColor:
              isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF7F8FC),

          centerTitle: true,

          title: Row(
            mainAxisSize: MainAxisSize.min,

            children: [

              Container(
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color:
                      primary.withOpacity(0.12),

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Icon(
                  Icons.smart_toy_outlined,
                  color: primary,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                isArabic
                    ? "المساعد الطبي الذكي"
                    : "Smart Medical Assistant",

                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,

                  color:
                      isDark
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        body: Column(
          children: [

            /// HEALTH CHIPS
            if (_hasData)
              Container(
                height: 54,

                margin:
                    const EdgeInsets.only(
                      top: 6,
                    ),

                child: ListView(
                  scrollDirection:
                      Axis.horizontal,

                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),

                  children: [

                    if (widget.imageResult != null)
                      _healthChip(
                        "🦶 ${widget.imageResult}",
                        Colors.orange,
                      ),

                    if (widget.strokeResult != null)
                      _healthChip(
                        "🧠 ${widget.strokeResult}",
                        Colors.red,
                      ),

                    if (widget.temperature != null)
                      _healthChip(
                        "🌡 ${widget.temperature}",
                        Colors.deepOrange,
                      ),

                    if (widget.pressure != null)
                      _healthChip(
                        "⚡ ${widget.pressure}",
                        Colors.teal,
                      ),

                    if (widget.generalHealth != null)
                      _healthChip(
                        "🩺 ${widget.generalHealth}",
                        primary,
                      ),
                  ],
                ),
              ),

            /// CHAT
            Expanded(
              child: ListView.builder(
                controller: _scroll,

                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),

                itemCount: _messages.length,

                itemBuilder: (_, i) {
                  return _buildBubble(
                    _messages[i],
                    isArabic,
                  );
                },
              ),
            ),

            /// TYPING
            if (_sending)
              Padding(
                padding:
                    const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),

                child: Row(
                  children: [

                    Container(
                      width: 30,
                      height: 30,

                      decoration: BoxDecoration(
                        color:
                            primary.withOpacity(
                              0.12,
                            ),

                        borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                      ),

                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: primary,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),

                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(
                                  0xFF1F2937,
                                )
                                : Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                              18,
                            ),
                      ),

                      child: Row(
                        children: const [
                          _TypingDot(),
                          _TypingDot(),
                          _TypingDot(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            /// INPUT BAR
            

Container(
  height: 42,

  margin: const EdgeInsets.only(
    bottom: 10,
  ),

  child: ListView(
    scrollDirection: Axis.horizontal,

    padding: const EdgeInsets.symmetric(
      horizontal: 14,
    ),

    children: [

      _suggestionChip(
        isArabic
            ? "اشرح النتيجة"
            : "Explain result",
      ),

      _suggestionChip(
        isArabic
            ? "هل هذا خطر؟"
            : "Is this dangerous?",
      ),

      _suggestionChip(
        isArabic
            ? "كيف أقلل الخطورة؟"
            : "How to reduce risk?",
      ),
    ],
  ),
),



            Container(
              padding:
                  const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    18,
                  ),
                  decoration: BoxDecoration(

  color:
      isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF7F8FC),

  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, -2),
    ),
  ],
),

              child: Row(
                children: [

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(
                                  0xFF1F2937,
                                )
                                : Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                      ),

                      child: TextField(
                        controller: _input,

                        maxLines: null,

                decoration: InputDecoration(

  hintText:
      isArabic
          ? "اكتب رسالتك..."
          : "Type your message...",

  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),

    borderSide: BorderSide(
      color: Colors.grey.shade300,
    ),
  ),

  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),

    borderSide: BorderSide(
      color: primary,
      width: 1.5,
    ),
  ),

  contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
),

                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap:
                        _sending
                            ? null
                            : _send,

                    child: AnimatedContainer(
                      duration:
                          const Duration(
                            milliseconds: 200,
                          ),

                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        color:
                            _sending
                                ? Colors.grey
                                : primary,

                        borderRadius:
                            BorderRadius.circular(
                              18,
                            ),
                      ),

                      child:
                          _sending
                              ? const Padding(
                                padding:
                                    EdgeInsets.all(
                                      12,
                                    ),

                                child:
                                    CircularProgressIndicator(
                                      strokeWidth:
                                          2,

                                      color:
                                          Colors
                                              .white,
                                    ),
                              )
                              : const Icon(
                                Icons.send_rounded,
                                color:
                                    Colors.white,
                              ),
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

  Widget _healthChip(
    String text,
    Color color,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(right: 8),

      padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Center(
        child: Text(
          text,

          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    _Message msg,
    bool isArabic,
  ) {

    final isUser = msg.isUser;

    final theme = Theme.of(context);

    final primary =
        theme.colorScheme.primary;

    final isDark =
        theme.brightness ==
        Brightness.dark;

    final bubbleColor =
        msg.hasAlert && !isUser
            ? Colors.red.withOpacity(0.08)
            : isUser
            ? primary
            : isDark
            ? const Color(0xFF1F2937)
            : Colors.white;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
            vertical: 5,
          ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,

        mainAxisAlignment:
            isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,

        children: [

          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,

              decoration: BoxDecoration(
                color:
                    primary.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
              ),

              child: Icon(
                Icons.health_and_safety_outlined,
                color: primary,
                size: 16,
              ),
            ),

            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context)
                            .size
                            .width *
                        0.72,
              ),

              padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

              decoration: BoxDecoration(
                color: bubbleColor,

  border: msg.hasAlert
      ? Border.all(
          color: Colors.red.shade300,
          width: 1.2,
        )
      : null,

                borderRadius:
                    BorderRadius.only(
                      topLeft:
                          const Radius.circular(
                            22,
                          ),

                      topRight:
                          const Radius.circular(
                            22,
                          ),

                      bottomLeft:
                          Radius.circular(
                            isUser
                                ? 22
                                : 8,
                          ),

                      bottomRight:
                          Radius.circular(
                            isUser
                                ? 8
                                : 22,
                          ),
                    ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  if (!isUser &&
                      msg.hasAlert) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 16,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          isArabic
                              ? "تنبيه"
                              : "Alert",

                          style:
                              const TextStyle(
                                color:
                                    Colors.orange,

                                fontWeight:
                                    FontWeight
                                        .bold,

                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],

                  Text(
                    msg.text,

                    style: TextStyle(
                      color:
                          isUser
                              ? Colors.white
                              : isDark
                              ? Colors.white
                              : Colors.black87,

                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
const SizedBox(height: 8),

Align(
  alignment:
      isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,

  child: Text(

    TimeOfDay.now().format(context),

    style: TextStyle(
      fontSize: 10,

      color:
          isUser
              ? Colors.white70
              : Colors.grey,
    ),
  ),
),
                  if (!isUser &&
                      msg.audioUrl != null) ...[
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () =>
                          _toggleAudio(
                            msg.audioUrl!,
                          ),

                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),

                        decoration: BoxDecoration(
                          color: primary
                              .withOpacity(0.08),

                          borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                        ),

                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,

                          children: [
                            Icon(
                              _isPlaying &&
                                      _playingUrl ==
                                          msg
                                              .audioUrl
                                  ? Icons.stop
                                  : Icons
                                      .volume_up_rounded,

                              size: 16,
                              color: primary,
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            Text(
                              _isPlaying &&
                                      _playingUrl ==
                                          msg
                                              .audioUrl
                                  ? (isArabic
                                      ? "إيقاف"
                                      : "Stop")
                                  : (isArabic
                                      ? "استماع"
                                      : "Listen"),

                              style: TextStyle(
                                color: primary,

                                fontWeight:
                                    FontWeight
                                        .w600,

                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),

            Container(
              width: 30,
              height: 30,

              decoration: BoxDecoration(
                color:
                    primary.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
              ),

              child: Icon(
                Icons.person_rounded,
                color: primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}




class _Message {
  final String text;

  final bool isUser;

  final String? audioUrl;

  final bool hasAlert;

  _Message({
    required this.text,
    required this.isUser,
    this.audioUrl,
    this.hasAlert = false,
  });
}

class _TypingDot extends StatefulWidget {
  const _TypingDot();

  @override
  State<_TypingDot> createState() =>
      _TypingDotState();
}

class _TypingDotState
    extends State<_TypingDot>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(
        milliseconds: 600,
      ),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,

      child: Container(
        margin:
            const EdgeInsets.symmetric(
              horizontal: 3,
            ),

        width: 7,
        height: 7,

        decoration: const BoxDecoration(
          color: Color(0xFF4C6FFF),

          shape: BoxShape.circle,
        ),
      ),
    );
  }
}