import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';

// 1. IMPORTS ADDED HERE
import 'package:telebirrbybr7/screens/engage_page.dart'; // To access globalEngageList
import 'package:telebirrbybr7/screens/bank_amount_page.dart'; // To navigate to next screen
import 'package:telebirrbybr7/services/recent_transfers_service.dart';
import 'dart:math' as math;

class TelebirrLoader extends StatefulWidget {
  const TelebirrLoader({super.key});

  @override
  State<TelebirrLoader> createState() => _TelebirrLoaderState();
}

class _TelebirrLoaderState extends State<TelebirrLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), 
    )..repeat();

    _rotationAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationAnimation,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(8, (index) {
            double angle = (index * 45 - 90) * (math.pi / 180);
            double radius = 22.0;
            double dotSize = 2.5 + (index * 1.6); 

            return Positioned(
              left: 30 + radius * math.cos(angle) - (dotSize / 2),
              top: 30 + radius * math.sin(angle) - (dotSize / 2),
              child: Opacity(
                opacity: 1.0,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(141, 199, 63, 1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class TransferToBankPage extends StatefulWidget {
  const TransferToBankPage({super.key});

  @override
  State<TransferToBankPage> createState() => _TransferToBankPageState();
}

class _TransferToBankPageState extends State<TransferToBankPage> {
  // Controllers and State Variables
  final TextEditingController _accountController = TextEditingController();
  int _currentIndex = 0;
  bool _isButtonEnabled = false;
  String selectedBankName = 'Please Choose';
  List<Map<String, String>> _recentTransfers = [];

  final List<String> sliderImages = [
    'images/Banner1.jpg',
    'images/Banner2.jpg',
    'images/Banner3.jpg',
    'images/Banner4.jpg',
    //'images/Banner5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_checkInput);
    _loadRecentTransfers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecentTransfers();
  }

  void _checkInput() {
    setState(() {
      _isButtonEnabled = _accountController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTransfers() async {
    final transfers = await RecentTransfersService.load();
    if (mounted) {
      setState(() {
        _recentTransfers = transfers;
      });
    }
  }

  // Handle recent item tap
  void _handleRecentTap(Map<String, String> recentItem) {
    // Auto-fill the bank name and account number
    setState(() {
      selectedBankName = recentItem['bankName']!;
      _accountController.text = recentItem['accountNumber']!;
      _isButtonEnabled = true;
    });

    // Navigate directly to BankAmountPage (skip loading dialog)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankAmountPage(
          accountName: recentItem['accountName']!,
          accountNumber: recentItem['accountNumber']!,
          bankName: recentItem['bankName']!,
        ),
      ),
    );
  }

  // Handle Next button press
  void _handleNextProcess() async {
    // A. Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                'images/loading.gif', 
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );

    // B. Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // C. Close Loading Dialog
    if (!mounted) return;
    Navigator.pop(context);

    // D. Check if account exists in globalEngageList
    try {
      final foundAccount = globalEngageList.firstWhere(
        (item) => item['number'] == _accountController.text,
      );

      // --- IF FOUND: Navigate to BankAmountPage ---
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BankAmountPage(
            accountName: foundAccount['name']!,
            accountNumber: foundAccount['number']!,
            bankName: selectedBankName,
          ),
        ),
      );
    } catch (e) {
      // --- IF NOT FOUND: Show Floating Error ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('query not found'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black54,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.4,
            left: 50,
            right: 50,
          ),
        ),
      );
    }
  }

  void _showBankSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Choose Bank",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildBankItem("Abay Bank", "images/abay.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Addis Bank S.C.", "images/addis.jpg", imageWidth: 50, imageHeight: 50,),
                    _buildBankItem("Ahadu Bank", "images/ahadu.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Amhara Bank", "images/amara.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Awash Bank", "images/Awash.png", imageWidth: 45, imageHeight: 45,),
                    _buildBankItem("Bank of Abyssinia", "images/abyssinia.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Birhan Bank", "images/birhan.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Bunna Bank", "images/bunna.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Commercial Bank of Ethiopia", "images/cbe.png", imageWidth: 45, imageHeight: 45,),
                    _buildBankItem("Cooperative Bank of Oromia", "images/coop.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Dashen Bank", "images/dashen.png", imageWidth: 45, imageHeight: 45,),
                    _buildBankItem("Global Bank Ethiopia", "images/global.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Enat Bank", "images/enat.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Gadda Bank", "images/geda.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Goh Betoch Bank", "images/goh.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Hibret Bank", "images/hibret.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Hijira Bank", "images/hijra.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Lion International Bank", "images/lion.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Nib International Bank", "images/nib.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Oromia Bank", "images/oro.jpg", imageWidth: 70, imageHeight: 70,),
                    _buildBankItem("Rammis Bank", "images/ramis.jpg", imageWidth: 70, imageHeight: 70,),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankItem(
    String name,
    String imagePath, {
    double imageWidth = 45,
    double imageHeight = 45,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedBankName = name;
        });
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.account_balance, size: 30),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          'Transfer to Bank',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                aspectRatio: 3.5, 
                viewportFraction: 0.92,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: sliderImages.map((imagePath) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sliderImages.length, (i) {
                  final isActive = i == _currentIndex;
                  const color = Color.fromRGBO(141, 199, 63, 1); 
                  const ringSize = 8.0;      
                  const innerDotSize = 4.0;  

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: ringSize,
                    height: ringSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.0),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? innerDotSize : 0,
                        height: isActive ? innerDotSize : 0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 5),
            const SizedBox(height: 15),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Bank',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showBankSelection(context),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedBankName,
                            style: TextStyle(
                              color: selectedBankName == 'Please Choose' 
                                  ? Colors.grey.shade700 
                                  : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account No',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter Account Number',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade500), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.green), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _handleNextProcess : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled 
                            ? const Color.fromRGBO(141, 199, 63, 1)
                            : Colors.grey.shade400,
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: _isButtonEnabled ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_recentTransfers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    Icon(Icons.delete_outline, color: Colors.grey.shade500, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _recentTransfers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildRecentItem(
                      item['accountName']!,
                      '${item['bankName']!} (${item['accountNumber']!})',
                      item['bankLogo']!,
                      isLast: index == _recentTransfers.length - 1,
                      data: item,
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    color: Colors.grey.shade600, 
    fontSize: 14, 
    fontWeight: FontWeight.w200,
  );

  Widget _buildRecentItem(String name, String details, String imagePath, {required bool isLast, required Map<String, String> data}) {
    return Column(
      children: [
        InkWell(
          onTap: () => _handleRecentTap(data),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            leading: Image.asset(imagePath, width: 40, height: 40),
            title: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.normal), overflow: TextOverflow.ellipsis),
            subtitle: Text(details, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal), overflow: TextOverflow.ellipsis),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: Colors.grey.shade200, indent: 70),
      ],
    );
  }
}
