import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../widgets/success_dialog.dart';
import '../widgets/topic_insights_card.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _giftFromController = TextEditingController();
  final _giftMessageController = TextEditingController();

  String? _selectedTopic;
  String? _selectedCampaign;
  int _tapCount = 0;
  int _step = 0;
  bool _isSubmitting = false;
  bool _isGift = false;
  late final Future<Map<String, int>> _topicStatsFuture;

  final List<String> _topics = [
    "Inspiration (勇氣與啟發)",
    "Comfort (溫暖與安慰)",
    "Travel Story (旅行故事)",
    "Daily Life (生活雜記)",
    "Random Surprise (隨機驚喜)",
    "Birthday Blessing (生日祝福)",
    "Heartbreak Healing (失戀療癒)",
    "New Adventure (冒險啟程)",
  ];

  final List<String> _campaigns = [
    "Open Journey (Any City)",
    "Spring Japan Trip",
    "Taiwan Cafe Week",
    "Seaside Story Series",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _giftFromController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _topicStatsFuture = FirebaseService().getTopicStats();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _selectedTopic == null) {
      _showError("Please fill in all required fields.");
      return;
    }

    if (_isGift && _giftFromController.text.trim().isEmpty) {
      _showError("Please add your name for the gift postcard.");
      return;
    }

    setState(() => _isSubmitting = true);
    final String? newDocId = await FirebaseService().addRequest(
      _nameController.text.trim(),
      _addressController.text.trim(),
      _selectedTopic!,
      requestType: _isGift ? 'gift' : 'self',
      giftFromName: _isGift ? _giftFromController.text.trim() : null,
      giftMessage: _isGift ? _giftMessageController.text.trim() : null,
      campaign: _selectedCampaign,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    HapticFeedback.vibrate();
    final rootContext = context;

    showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        docId: newDocId ?? "TEMP",
        onOpenTracking: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            rootContext,
            '/',
            arguments: {'initialTab': 1, 'initialTrackQuery': newDocId ?? ''},
          );
        },
      ),
    );

    setState(() {
      _nameController.clear();
      _addressController.clear();
      _giftFromController.clear();
      _giftMessageController.clear();
      _selectedTopic = null;
      _selectedCampaign = null;
      _step = 0;
      _isGift = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.amber.shade700),
      filled: true,
      fillColor: Colors.grey.shade50,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How WanderStamp works",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text("1. You pick a topic and request a postcard."),
          Text("2. The traveler writes and updates your journey timeline."),
          Text("3. You confirm arrival and optionally share feedback."),
          SizedBox(height: 10),
          Text(
            "Privacy promise: Address is only visible to authenticated admin.",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            "Typical delivery window: 1-4 weeks depending on route.",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            "Current supported regions: Asia, North America, and Europe.",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              "Request Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 10),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text("For Me")),
                ButtonSegment<bool>(value: true, label: Text("Gift")),
              ],
              selected: {_isGift},
              onSelectionChanged: (set) => setState(() => _isGift = set.first),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameController,
          decoration: _buildInputDecoration(
            _isGift ? "Recipient Name" : "Nickname / Name",
            _isGift ? "Who will receive this?" : "How should I call you?",
            Icons.person_outline,
          ),
        ),
        const SizedBox(height: 14),
        if (_isGift) ...[
          TextField(
            controller: _giftFromController,
            decoration: _buildInputDecoration(
              "Gift From",
              "Your name",
              Icons.card_giftcard,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _giftMessageController,
            maxLines: 2,
            decoration: _buildInputDecoration(
              "Gift Context (Optional)",
              "A short note for why this gift matters",
              Icons.notes,
            ),
          ),
          const SizedBox(height: 14),
        ],
        DropdownButtonFormField<String>(
          initialValue: _selectedTopic,
          hint: const Text("Select a Message Topic"),
          items: _topics
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) => setState(() => _selectedTopic = val),
          decoration: _buildInputDecoration(
            "What kind of message is needed?",
            "",
            Icons.auto_awesome_outlined,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedCampaign,
          hint: const Text("Choose a Journey Campaign"),
          items: _campaigns
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCampaign = val),
          decoration: _buildInputDecoration(
            "Campaign (Optional)",
            "",
            Icons.public,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty ||
                  _selectedTopic == null) {
                _showError("Please complete name and topic first.");
                return;
              }
              if (_isGift && _giftFromController.text.trim().isEmpty) {
                _showError("Please fill in gift sender name.");
                return;
              }
              setState(() => _step = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text("Continue to Address"),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      children: [
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: _buildInputDecoration(
            "Mailing Address",
            "An address you are comfortable to share",
            Icons.home_outlined,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Address is only used for this postcard request. You can ask admin to delete records after delivery.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Send Warmth Request"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              _tapCount++;
              HapticFeedback.lightImpact();
              if (_tapCount == 5) {
                _tapCount = 0;
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, '/admin-login');
              }
            },
            child: const Text(
              "Receive Warmth From A Traveller",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _buildTrustSection(),
          FutureBuilder<Map<String, int>>(
            future: _topicStatsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return TopicInsightsCard(topicStats: snapshot.data!);
            },
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _step == 0 ? _buildStepOne() : _buildStepTwo(),
          ),
        ],
      ),
    );
  }
}
