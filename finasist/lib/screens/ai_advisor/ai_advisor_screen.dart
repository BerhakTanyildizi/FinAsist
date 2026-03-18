import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/transaction_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mesaj listesi: isUser => true (Kullanıcı), false (AI)
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Merhaba! Ben FinAsist yapay zeka danışmanınızım.\n\nBugün harcamalarınızı analiz etmemi veya size özel tasarruf önerileri sunmamı ister misiniz?',
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _msgController.clear();
    });
    
    _scrollToBottom();
    _simulateAiResponse(text);
  }

  void _simulateAiResponse(String userMsg) async {
    // "Yazıyor..." hissi için gecikme
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    String aiReply = "Bunu anladığımdan emin değilim. Size genel durumunuzdan bahsedeyim:\n";
    String msgLower = userMsg.toLowerCase();
    
    if (msgLower.contains("rapor") || msgLower.contains("harcama") || msgLower.contains("gider")) {
       double expense = 0;
       for (var tx in provider.transactions) {
         if (tx['type'] == 'expense') {
           expense += double.parse(tx['amount'].toString());
         }
       }
       aiReply = "Şimdiye kadar kaydettiğiniz toplam harcama(gider) tutarı ${expense.toStringAsFixed(2)} ₺.\nBankalardan gelen son ekstrelere göre bu ay porsiyonlarınızı biraz küçültmek isteyebilirsiniz! 📉";
    } else if (msgLower.contains("gelir") || msgLower.contains("maaş") || msgLower.contains("para")) {
       aiReply = "Şu anki güncel net bakiyeniz: ${provider.totalBalance.toStringAsFixed(2)} ₺.\nHarika gidiyorsunuz! Yatırım fırsatlarını değerlendirmemizi ister misiniz? 🚀";
    } else {
       aiReply = "Şu an arka planda tam kapsamlı yapay zeka entegrasyonumuz devreye giriyor. Demo sürümündeyiz ama şu an güncel veritabanı bakiyenizin ${provider.totalBalance.toStringAsFixed(2)} ₺ olduğunu görüyorum!";
    }

    setState(() {
      _messages.add({'isUser': false, 'text': aiReply});
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
            icon: const Icon(CupertinoIcons.clear_circled, color: AppTheme.textSecondary),
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
              itemCount: _messages.length + 1, // +1 For suggestions at the end
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 16.0),
                     child: _buildSuggestionChips([
                      'Aylık Raporumu Çıkar',
                      'Toplam Gelirim Ne Kadar?',
                      'Toplam Harcamam Ne Kadar?'
                     ]),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5)),
          ),
          child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryPurple, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
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
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChips(List<String> suggestions) {
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
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
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
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.paperclip, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Finansal bir soru sorun...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_msgController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
