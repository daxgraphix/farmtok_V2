import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/local_cache_service.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isSidebarOpen = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  // Expert Quick Questions (30+)
  final List<Map<String, String>> _quickQuestions = [
    {
      'question': 'Best crops for my region?',
      'answer': 'For optimal yields in Tanzania, consider your agro-ecological zone. Highland areas suit potatoes, wheat, and tea. Lowland/coastal regions excel with cassava, rice, and coconuts. Semi-arid zones benefit from drought-resistant sorghum, millet, and pigeon peas.'
    },
    {
      'question': 'Precision irrigation advice?',
      'answer': 'Implement drip irrigation for 30-50% water savings. Water at 5-7 day intervals during vegetative stage, increasing frequency during flowering and fruiting. Monitor soil moisture at 15cm depth - irrigate when it drops below 60% field capacity.'
    },
    {
      'question': 'Early disease detection signs?',
      'answer': 'Watch for chlorosis (yellowing), necrotic lesions, wilting, stunting, and abnormal growth patterns. Use the scanner app weekly. Early intervention at first symptom sighting increases treatment success rate by 80%.'
    },
    {
      'question': 'Fertilizer application schedule?',
      'answer': 'Apply NPK basal at planting. Side-dress nitrogen at 4-6 weeks. Foliar micronutrients during flowering. Conduct soil tests every 2 seasons. Use organic compost (5-10 tons/ha) to improve soil structure and microbial activity.'
    },
    {
      'question': 'Integrated pest management?',
      'answer': 'Combine cultural (crop rotation, sanitation), biological (natural predators, neem), and targeted chemical controls. Monitor weekly with pheromone traps. Apply pesticides only when economic threshold is reached to protect beneficial insects.'
    },
    {
      'question': 'Climate-smart practices?',
      'answer': 'Adopt conservation agriculture: minimum tillage, crop rotation, cover cropping. Use drought-tolerant varieties. Implement agroforestry with Faidherbia albida. Time planting with seasonal forecasts from TMA.'
    },
    {
      'question': 'How to improve soil fertility?',
      'answer': 'Add organic matter (compost, manure, crop residues). Practice crop rotation with legumes. Use green manures like sunn hemp. Apply lime if soil is acidic. Test soil every 2 seasons and balance nutrients accordingly.'
    },
    {
      'question': 'Best maize varieties for Tanzania?',
      'answer': 'Popular high-yielding varieties include Stuka, DK 8031, and SC 627. Choose drought-tolerant varieties like PAN 4M-21 for semi-arid areas. Always use certified seeds from reliable suppliers.'
    },
    {
      'question': 'How to control fall armyworm?',
      'answer': 'Scout fields weekly. Apply neem-based products or Bt insecticides early. Encourage natural predators like birds and wasps. Plant early and use push-pull technology with Desmodium and Napier grass borders.'
    },
    {
      'question': 'When to plant beans?',
      'answer': 'Plant beans at the onset of rains (March-April for long rains, October-November for short rains). Use varieties like Lyamungo 90 or Selian 97. Inoculate seeds with rhizobium for better nitrogen fixation.'
    },
    {
      'question': 'How to store harvested maize?',
      'answer': 'Dry maize to 13-14% moisture. Use hermetic bags (PICS) or metal silos. Add ash or neem leaves as natural repellent. Store in clean, dry, well-ventilated structures away from direct sunlight.'
    },
    {
      'question': 'Best practices for cassava farming?',
      'answer': 'Use disease-free cuttings from 8-12 month old plants. Plant at 1m x 1m spacing. Weed early and earth up at 2-3 months. Harvest at 8-12 months depending on variety. Process into flour or chips to reduce post-harvest losses.'
    },
    {
      'question': 'How to manage tomato pests organically?',
      'answer': 'Use neem oil or garlic spray for aphids and whiteflies. Install yellow sticky traps. Practice crop rotation. Mulch to reduce soil-borne diseases. Introduce predatory insects like ladybugs and lacewings.'
    },
    {
      'question': 'What is the best time to apply manure?',
      'answer': 'Apply well-decomposed manure 2-3 weeks before planting. For top dressing, apply at 4-6 weeks after planting. Avoid fresh manure as it can burn roots and introduce weeds.'
    },
    {
      'question': 'How to prevent post-harvest losses?',
      'answer': 'Harvest at correct maturity. Dry produce properly before storage. Use clean, dry containers. Store in cool, dry places. Use hermetic storage bags for grains. Process perishable crops quickly into flour, dried chips, or juice.'
    },
    {
      'question': 'Best cover crops for soil health?',
      'answer': 'Legumes like cowpea, lablab, and sunn hemp fix nitrogen. Cereals like millet and sorghum add biomass. Plant cover crops after main harvest and incorporate before flowering for maximum soil benefit.'
    },
    {
      'question': 'How to deal with drought in farming?',
      'answer': 'Choose drought-tolerant varieties. Practice conservation agriculture. Use mulching and water harvesting techniques. Plant early maturing crops. Implement drip irrigation where possible. Diversify income with livestock or beekeeping.'
    },
    {
      'question': 'Recommended spacing for onions?',
      'answer': 'Plant onions in rows 30cm apart with 10-15cm between plants. Use raised beds for better drainage. Transplant 6-8 week old seedlings. Apply light irrigation after transplanting and keep soil moist during bulb formation.'
    },
    {
      'question': 'How to make organic pesticide at home?',
      'answer': 'Neem spray: Soak 500g neem leaves in 5L water for 24hrs. Garlic-chili spray: Blend 100g garlic + 100g chili + 1L water. Fermented plant juice: Mix chopped plants with molasses and ferment for 7 days. Strain and dilute before use.'
    },
    {
      'question': 'Best fish farming practices in Tanzania?',
      'answer': 'Use tilapia or catfish. Stock 2-3 fish per m². Feed twice daily with quality pellets. Maintain water quality (pH 6.5-8.5, oxygen >5mg/L). Harvest after 6-8 months. Integrate with crops for better nutrient cycling.'
    },
    {
      'question': 'How to start beekeeping?',
      'answer': 'Use modern hives (KTB or Langstroth). Place hives near flowering plants. Provide water source. Inspect hives monthly. Harvest honey after 3-4 months. Join beekeeping groups for training and market access.'
    },
    {
      'question': 'Best sweet potato varieties?',
      'answer': 'Popular varieties: Kabode (orange-fleshed, high vitamin A), Mataya, and Kiegea. Plant vine cuttings 30cm apart on ridges. Harvest after 4-5 months. Orange varieties help fight vitamin A deficiency.'
    },
    {
      'question': 'How to control weeds organically?',
      'answer': 'Use mulch (straw, leaves, plastic). Practice timely weeding (2-3 times per season). Use cover crops to suppress weeds. Rotate crops. Hand weed or use simple tools before weeds flower and set seed.'
    },
    {
      'question': 'Recommended practices for banana farming?',
      'answer': 'Use disease-free suckers. Plant at 3m x 3m spacing. Apply 20-30kg manure per plant annually. Remove male buds after flowering. Prop up bunches with poles. Harvest when fingers are rounded and fingers start to yellow.'
    },
    {
      'question': 'How to reduce soil erosion?',
      'answer': 'Plant along contours. Use grass strips and hedgerows. Build terraces on slopes. Maintain ground cover. Avoid burning crop residues. Practice minimum tillage and agroforestry.'
    },
    {
      'question': 'Best practices for rice farming?',
      'answer': 'Use certified seeds (SARO5, TXD306). Transplant 21-28 day seedlings. Maintain 5-10cm water depth. Apply fertilizer in splits. Control weeds early. Drain field 2 weeks before harvest. Dry paddy to 14% moisture.'
    },
    {
      'question': 'How to market farm produce profitably?',
      'answer': 'Know your market prices. Form or join farmer groups for collective marketing. Add value (process, package, brand). Use mobile apps for market information. Build relationships with buyers. Consider contract farming for stability.'
    },
    {
      'question': 'What is crop rotation and why is it important?',
      'answer': 'Crop rotation means growing different crops in sequence on the same land. It breaks pest and disease cycles, improves soil fertility, reduces weeds, and increases yields by 10-25%. Example: Maize → Beans → Cassava → Fallow.'
    },
    {
      'question': 'How to test soil at home?',
      'answer': 'Observe soil color, texture, and structure. Do a jar test for particle size. Use simple pH test strips. Send samples to nearest agricultural office or Sokoine University lab for full nutrient analysis. Cost is usually affordable.'
    },
    {
      'question': 'Best practices for poultry farming?',
      'answer': 'Use improved breeds (Kuroiler, Sasso). Vaccinate against Newcastle and Gumboro. Provide balanced feed and clean water. Maintain good housing with ventilation. Practice biosecurity. Start small (50-100 birds) and scale up.'
    },
    {
      'question': 'How to make and use compost?',
      'answer': 'Layer green (leaves, weeds) and brown (dry stalks, ash) materials. Keep moist and turn every 2-3 weeks. Ready in 6-8 weeks. Apply 5-10 tons per hectare or 2-5kg per planting hole. Improves soil structure and water retention.'
    },
    {
      'question': 'What are the signs of nutrient deficiency in crops?',
      'answer': 'Nitrogen: yellowing of older leaves. Phosphorus: purple stems, poor roots. Potassium: leaf edge browning. Calcium: blossom end rot in tomatoes. Magnesium: yellowing between veins. Iron: yellow new leaves. Use soil tests and targeted fertilizers.'
    },
    {
      'question': 'How to start a small farm business?',
      'answer': 'Start with high-demand crops you understand. Calculate costs and expected revenue. Keep records. Start small and reinvest profits. Join farmer groups. Use mobile money for transactions. Focus on quality and consistent supply.'
    },
    {
      'question': 'Best watermelon farming practices?',
      'answer': 'Use varieties like Sugar Baby or Crimson Sweet. Plant in well-drained sandy loam. Space 2m x 2m. Apply manure and NPK. Mulch to retain moisture. Harvest when tendril dries and fruit sounds hollow when tapped (after 80-100 days).'
    },
    {
      'question': 'How to prevent aflatoxin in maize and groundnuts?',
      'answer': 'Harvest at correct maturity. Dry immediately to below 13% moisture. Sort out damaged grains. Store in clean, dry, ventilated structures. Use hermetic bags. Avoid storing wet produce. Test for aflatoxin before selling or consuming.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _sidebarAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadChatHistory();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await LocalCacheService.getCachedChatHistory();
      setState(() {
        _messages.clear();
        for (var item in history) {
          _messages.add({
            'message': item['message'],
            'isUser': true,
            'timestamp': DateTime.parse(item['timestamp']),
          });
          _messages.add({
            'message': item['response'],
            'isUser': false,
            'timestamp': DateTime.parse(item['timestamp']),
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Assistant',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Quick Questions',
            onPressed: () => _showQuickQuestions(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
                if (_isSidebarOpen) {
                  _sidebarAnimationController.forward();
                } else {
                  _sidebarAnimationController.reverse();
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main chat area
            Column(
              children: [
                Expanded(
                  child: _buildMessagesList(),
                ),
                AnimatedPadding(
                  padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 8 : 0),
                  duration: const Duration(milliseconds: 200),
                  child: _buildMessageInput(),
                ),
              ],
            ),

            // Sidebar overlay
            if (_isSidebarOpen)
              AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.5 * _sidebarAnimation.value),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSidebarOpen = false;
                          _sidebarAnimationController.reverse();
                        });
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8 * _sidebarAnimation.value,
                            child: _buildSidebar(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.chat, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chat History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSidebarOpen = false;
                      _sidebarAnimationController.reverse();
                    });
                  },
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Conversations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length > 10 ? 10 : _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['isUser'] ?? false;
                final text = message['message'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUser ? const Color(0xFF2E7D32) : Colors.grey,
                      child: Icon(
                        isUser ? Icons.person : Icons.smart_toy,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      text.length > 50 ? '${text.substring(0, 50)}...' : text,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      isUser ? 'You' : 'AI Assistant',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      // TODO: Load this conversation
                    },
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _isSidebarOpen = false;
                  _sidebarAnimationController.reverse();
                });
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickQuestions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap any question to get instant farming advice',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _quickQuestions.length,
                itemBuilder: (context, index) {
                  final qa = _quickQuestions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        qa['question']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _sendQuickQuestion(qa['question']!, qa['answer']!);
                      },
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

  void _sendQuickQuestion(String question, String answer) {
    setState(() {
      _messages.add({
        'message': question,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    setState(() {
      _isTyping = true;
    });

    // Simulate typing delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'message': answer,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        final isUser = message['isUser'] ?? false;

        return _buildMessageBubble(message['message'], isUser);
      },
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 10, top: 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.agriculture,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(6),
                  bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(20),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.now().toString().substring(11, 16),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 16,
              color: Color(0xFF2E7D32),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'AI is thinking',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 120,
                  minHeight: 48,
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask about farming, crops, weather...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _messageController.clear();
                      },
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? 'anonymous';

    setState(() {
      _messages.add({
        'message': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await AIService.chatWithAI(message, userId);

      if (mounted) {
        setState(() {
          _messages.add({
            'message': response,
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isTyping = false;
        });

        // Save to cache
        await LocalCacheService.saveChatMessage(message, response, userId);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'message': 'Sorry, I encountered an error. Please try again.',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isTyping = false;
        });
        _scrollToBottom();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}