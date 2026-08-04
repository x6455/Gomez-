import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';

class IndividualTransferPage extends StatefulWidget {
  const IndividualTransferPage({super.key});

  @override
  State<IndividualTransferPage> createState() => _IndividualTransferPageState();
}

class _IndividualTransferPageState extends State<IndividualTransferPage> {
  int _currentIndex = 0;

  final List<String> sliderImages = [
    'images/Banner1.jpg',
    'images/Banner2.jpg',
    'images/Banner3.jpg',
    'images/Banner4.jpg',
    'images/Banner5.jpg',
  ];

  final TextEditingController _numberController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _showSystemBusy = false; // ✅ New state for system busy overlay

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_checkInput);
  }

  void _checkInput() {
    setState(() {
      _isButtonEnabled = _numberController.text.length == 9;
    });
  }

  Future<void> _handleNext() async {
    if (_isLoading) return;

    // ✅ Start loading
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // ✅ Hide loading and show system busy message
      setState(() {
        _isLoading = false;
        _showSystemBusy = true;
      });
    }

    // ✅ Wait 3 seconds then hide the system busy message
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _showSystemBusy = false);
    }

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send Money to Individual',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              _focusNode.unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  /// 🔹 Slider
                  CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: 39 / 9,
                      viewportFraction: 0.9,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                    items: sliderImages.map((imagePath) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  /// 🔹 Indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(sliderImages.length, (i) {
                        final isActive = i == _currentIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 0.8),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              width: isActive ? 4.0 : 0,
                              height: isActive ? 4.0 : 0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 13),

                  /// 🔹 Input Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Please Enter Mobile Number",
                          style: TextStyle(color: Colors.black87, fontSize: 17),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _numberController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, top: 14),
                              child: Text(
                                "+251 ",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(1.0),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner,
                                    color: Colors.lightGreen[600]),
                                const SizedBox(width: 12),
                                Icon(Icons.contact_phone_outlined,
                                    color: Colors.lightGreen[600]),
                                const SizedBox(width: 12),
                              ],
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightGreen[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🔹 Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isButtonEnabled && !_isLoading)
                                ? _handleNext
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(2, 135, 208, 1),
                              disabledBackgroundColor:
                                  const Color.fromRGBO(2, 135, 208, 0.25),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Next",
                              style: TextStyle(color: Colors.white, fontSize: 17),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Recent Header (outside container, no background)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear Recents'),
                                content: const Text('Remove all recent contacts?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(Icons.delete_outline, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),

                  /// Contacts Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildRecentTile("Hewan", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("TEWABE", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Abera", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Biruk", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Meron", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Natnael", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Samirawit", Colors.amber),
                          _buildDivider(),
                          _buildRecentTile("Yonas", Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ✅ LOADER OVERLAY (NO UI SHIFT)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'images/loading.gif',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            ),

          /// ✅ SYSTEM BUSY OVERLAY
          if (_showSystemBusy)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.orange[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'System busy, please try again',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildRecentTile(String name, Color avatarColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        _focusNode.requestFocus();
      },
    );
  }
}
