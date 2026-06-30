import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Mesaj listesi: isUser => true (Kullanıcı), false (AI)
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Merhaba! Ben FinAsist yapay zeka danışmanınızım.\n\nBugün harcamalarınızı analiz etmemi veya size özel tasarruf önerileri sunmamı ister misiniz?',
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isTyping) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _msgController.clear();
    });

    _scrollToBottom();
    _getAiResponse(text);
  }

  void _getAiResponse(String userMsg) async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    // Karşılama mesajı hariç, az önce eklenen kullanıcı mesajı hariç geçmişi oluştur
    final history = <Map<String, String>>[];
    for (var i = 1; i < _messages.length - 1; i++) {
      final m = _messages[i];
      history.add({
        'role': m['isUser'] == true ? 'user' : 'assistant',
        'content': m['text'] as String,
      });
    }

    final reply = await ApiService.sendAdvisorMessage(userMsg, history);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add({
        'isUser': false,
        'text': reply ??
            'Üzgünüm, şu anda yanıt veremiyorum. Bağlantınızı kontrol edip tekrar deneyin.',
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.sparkles, color: AppTheme.starYellow, size: 20),
            SizedBox(width: 8),
            Text('AI Finansal Danışman', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.clear_circled, color: AppTheme.textSecondaryOf(context)),
            onPressed: () {
              setState(() {
                _messages.removeRange(1, _messages.length); // Sadece ilk mesajı tut
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Sohbet Alanı
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              // +1 yazıyor göstergesi (varsa) +1 öneri çipleri
              itemCount: _messages.length + (_isTyping ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                final typingIndex = _messages.length;
                final suggestionsIndex = _messages.length + (_isTyping ? 1 : 0);

                if (_isTyping && index == typingIndex) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: _TypingIndicator(),
                  );
                }

                if (index == suggestionsIndex) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 16.0),
                     child: _buildSuggestionChips([
                      'Aylık Raporumu Çıkar',
                      'Toplam Gelirim Ne Kadar?',
                      'Nereden Tasarruf Edebilirim?'
                     ], context),
                   );
                }

                var msg = _messages[index];
                if (msg['isUser'] == true) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildUserMessage(msg['text']),
                  );
                } else {
                  return Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: _buildAiMessage(msg['text']),
                  );
                }
              },
            ),
          ),

          // 2. Mesaj Yazma Alanı
          _buildMessageInput(),
          const SizedBox(height: 60), // Fab butonu boşluğu
        ],
      ),
    );
  }

  Widget _buildAiMessage(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
          ),
          child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryPurple, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColorOf(context),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
            ),
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 14, height: 1.4),
            ),
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildUserMessage(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            // Bu balon her zaman AppTheme.primaryPurple arkaplanlıdır, metin sabit beyaz kalmalı
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChips(List<String> suggestions, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((text) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _sendMessage(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  text,
                  style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.cardColorOf(context),
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 1)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(CupertinoIcons.paperclip, color: AppTheme.textSecondaryOf(context)),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _msgController,
                  style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Finansal bir soru sorun...',
                    hintStyle: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isTyping ? null : () => _sendMessage(_msgController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isTyping
                      ? AppTheme.primaryPurple.withValues(alpha: 0.4)
                      : AppTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
                // Bu alan her zaman AppTheme.primaryPurple arkaplanlıdır, ikon sabit beyaz kalmalı
                child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// AI'ın yanıt yazdığını gösteren basit "..." animasyonlu balon.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.5)),
          ),
          child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryPurple, size: 16),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColorOf(context),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          ),
          child: const SizedBox(
            // 3 nokta × (6px genişlik + 2px yatay padding×2) = 30px gerekiyor
            width: 32,
            height: 12,
            child: _ThreeDotsAnimation(),
          ),
        ),
      ],
    );
  }
}

class _ThreeDotsAnimation extends StatefulWidget {
  const _ThreeDotsAnimation();

  @override
  State<_ThreeDotsAnimation> createState() => _ThreeDotsAnimationState();
}

class _ThreeDotsAnimationState extends State<_ThreeDotsAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final opacity = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2)).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
