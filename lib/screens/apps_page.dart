import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telebirrbybr7/screens/bank_amount_page.dart'; // Verified package path routing

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String selectedBankName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  // Load data from storage
  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('saved_name') ?? '';
      _accountController.text = prefs.getString('saved_account') ?? '';
      selectedBankName = prefs.getString('saved_bank') ?? '';
    });
  }

  // Save data to storage
  Future<void> _saveAccount() async {
    if (_nameController.text.isEmpty || _accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_name', _nameController.text);
    await prefs.setString('saved_account', _accountController.text);
    await prefs.setString('saved_bank', selectedBankName);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account details saved successfully!")),
      );
    }
  }

  /// BYPASS FUNCTION: Direct route straight into BankAmountPage bypassing scanner camera screen
  Future<void> _bypassQRAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    String savedName = prefs.getString('saved_name') ?? 'No Name Saved';
    String savedAccount = prefs.getString('saved_account') ?? '0000000000';
    String savedBank = prefs.getString('saved_bank') ?? '';

    if (!mounted) return;

    // Launch core route with the scanner pipeline flag set to true
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankAmountPage(
          accountName: savedName,
          accountNumber: savedAccount,
          bankName: savedBank,
          isFromQr: true, // <-- Forces merchant receipt layout down the execution stream
        ),
      ),
    );
  }

  // BANK SELECTION MODAL
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 15),
              const Text("Choose Bank", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildBankItem("No Bank", ""),
                    _buildBankItem("Abay Bank", "images/abay.jpg"),
                    _buildBankItem("Addis Bank S.C.", "images/addis.jpg"),
                    _buildBankItem("Ahadu Bank", "images/ahadu.jpg"),
                    _buildBankItem("Amhara Bank", "images/amara.jpg"),
                    _buildBankItem("Awash Bank", "images/Awash.png"),
                    _buildBankItem("Bank of Abyssinia", "images/abyssinia.jpg"),
                    _buildBankItem("Birhan Bank", "images/birhan.jpg"),
                    _buildBankItem("Bunna Bank", "images/bunna.jpg"),
                    _buildBankItem("Commercial Bank of Ethiopia", "images/cbe.png"),
                    _buildBankItem("Cooperative Bank of Oromia", "images/coop.jpg"),
                    _buildBankItem("Dashen Bank", "images/dashen.png"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankItem(String name, String imagePath) {
    return InkWell(
      onTap: () {
        setState(() => selectedBankName = name == "No Bank" ? '' : name);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath.isNotEmpty)
              Image.asset(imagePath, width: 45, height: 45, fit: BoxFit.contain)
            else
              const Icon(Icons.account_balance, size: 45, color: Colors.grey),
            const SizedBox(height: 5),
            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11), maxLines: 2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const telebirrGreen = Color.fromRGBO(141, 199, 63, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Apps & Accounts"),
        backgroundColor: telebirrGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Link Bank Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            // Bank Selection Dropdown UI (Preserved to maintain correct system logging params)
            const Text("Select Bank", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showBankSelection(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedBankName.isEmpty ? '' : selectedBankName, 
                      style: TextStyle(
                        color: selectedBankName.isEmpty ? Colors.grey : Colors.black, 
                        fontSize: 16
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            const Text("Account Name", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Enter full name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Account Number", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter account number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),

            const SizedBox(height: 40),

            // Standard Data Update Trigger
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: telebirrGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),

            // Bypass shortcut navigation button layout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _bypassQRAndNavigate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: telebirrGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.flash_on, color: telebirrGreen),
                label: const Text(
                  "INSTANT MERCHANT PAYMENT",
                  style: TextStyle(color: telebirrGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
