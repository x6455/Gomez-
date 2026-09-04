import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_sender.dart'; // Adjust path as needed

List<Map<String, String>> globalEngageList = [];

class EngagePage extends StatefulWidget {
  const EngagePage({super.key});

  @override
  State<EngagePage> createState() => _EngagePageState();
}

class _EngagePageState extends State<EngagePage> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, String>> _accounts = [];
  List<Map<String, String>> _filteredAccounts = [];

  bool _upperCaseEnabled = false;
  static const _storageKey = 'saved_engage_accounts';
  
  bool _isSendingReverse = false;
  String? _errorMessage; // For displaying errors on the page
  String? _successMessage; // For displaying success message on the page

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _searchController.addListener(_filterAccounts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ================= STORAGE =================

  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List decoded = json.decode(jsonString);
        setState(() {
          _accounts = decoded.map((e) => Map<String, String>.from(e)).toList();
          _filteredAccounts = List.from(_accounts);
          globalEngageList = List.from(_accounts);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load accounts: $e";
      });
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(_accounts));
      globalEngageList = List.from(_accounts);
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to save accounts: $e";
      });
    }
  }

  // ================= REVERSE SMS =================
  
  Future<void> _sendReverseSms() async {
    // Clear previous messages
    setState(() {
      _isSendingReverse = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Check if SmsSender is available
      try {
        // Test if SmsSender exists (this will throw if import is wrong)
        await Future.delayed(Duration.zero);
      } catch (e) {
        throw Exception("SMS service not properly configured");
      }
      
      // Get the latest transaction from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('sent_balances') ?? [];
      
      if (history.isEmpty) {
        throw Exception("No transaction history found. Please make a transfer first.");
      }
      
      // Get the last transaction
      String lastTransactionJson = history.last;
      Map<String, dynamic> lastTx;
      
      try {
        lastTx = jsonDecode(lastTransactionJson);
      } catch (e) {
        throw Exception("Failed to parse transaction data: $e");
      }
      
      // Extract required info with validation
      String transactionID = lastTx['txID'] ?? 'UNKNOWN';
      String amount = lastTx['amount_sent'] ?? '0.00';
      String currentBalance = lastTx['remaining_balance'] ?? '0.00';
      String accountName = lastTx['accountName'] ?? 'Customer';
      
      if (transactionID == 'UNKNOWN') {
        throw Exception("Invalid transaction data: missing transaction ID");
      }
      
      // Format the SMS message (reverse/cancellation)
      // 1. Convert the text values into numbers so they can be added mathematically
double balanceNum = double.parse(currentBalance.toString());
double amountNum = double.parse(amount.toString());

// 2. Calculate the new total and format it to 2 decimal places
String finalBalance = (balanceNum + amountNum).toStringAsFixed(2);

// 3. Your updated string message
String message = "Dear DANIEL\n"
    "Your request for transaction number $transactionID with amount ETB $amount is REVERSED/CANCELLED. "
    "Your current E-Money Account balance is ETB $finalBalance.\n\n"
    "The $transactionID transaction is reversed.\n"
    "Thank you for using telebirr. Ethio telecom.\n"
    "Further transactions might fail. Please try again later.";


          
      // Send SMS with timeout
      try {
        await SmsSender.sendSms("0994797189", message).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception("SMS sending timed out after 30 seconds"),
        );
      } catch (e) {
        throw Exception("SMS send failed: $e");
      }
      
      // Success!
      if (mounted) {
        setState(() {
          _successMessage = "✓ Reverse SMS sent successfully for transaction: $transactionID\nAmount: ETB $amount";
          _isSendingReverse = false;
        });
        
        // Auto-clear success message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _successMessage != null) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "❌ Error: ${e.toString()}";
          _isSendingReverse = false;
        });
      }
    } finally {
      if (mounted && _isSendingReverse) {
        setState(() {
          _isSendingReverse = false;
        });
      }
    }
  }

  // ================= PERMISSION =================

  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }

        var status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;

        if (await Permission.storage.isGranted) {
          return true;
        }

        status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = "Permission error: $e";
      });
      return false;
    }
  }

  // ================= EXPORT =================

  Future<void> _exportBackup() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      if (!await _requestStoragePermission()) {
        setState(() {
          _errorMessage = "Storage permission denied. Cannot export backup.";
        });
        return;
      }

      String jsonContent = json.encode(_accounts);

      if (Platform.isAndroid) {
        try {
          final path = '/storage/emulated/0/Download/EngageBackups';
          final dir = Directory(path);

          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          String fileName =
              'engage_backup_${DateTime.now().millisecondsSinceEpoch}.json';

          final file = File('$path/$fileName');
          await file.writeAsString(jsonContent);

          setState(() {
            _successMessage = "✓ Backup saved to Download/EngageBackups";
          });
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _successMessage != null) {
              setState(() {
                _successMessage = null;
              });
            }
          });
          return;
        } catch (e) {
          debugPrint("Direct save failed: $e");
        }
      }

      // fallback
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup',
        fileName:
            'engage_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonContent);

        setState(() {
          _successMessage = "✓ Backup saved successfully";
        });
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _successMessage != null) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Export failed: $e";
      });
    }
  }

  // ================= IMPORT =================

  Future<void> _importRestore() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      if (!await _requestStoragePermission()) {
        setState(() {
          _errorMessage = "Storage permission denied. Cannot restore backup.";
        });
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        String content = await file.readAsString();
        List decoded = json.decode(content);

        List<Map<String, String>> restored = decoded
            .map((e) => Map<String, String>.from(e))
            .toList();

        setState(() {
          _accounts = restored;
          _filteredAccounts = List.from(_accounts);
          _successMessage = "✓ Restored ${restored.length} accounts successfully";
        });

        await _saveToStorage();
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _successMessage != null) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Restore failed: $e";
      });
    }
  }

  // ================= UI =================

  void _saveAccount() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    
    if (_nameController.text.isEmpty ||
        _numberController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in both Name and Number fields";
      });
      return;
    }

    final account = {
      'name': _upperCaseEnabled
          ? _nameController.text.toUpperCase()
          : _nameController.text,
      'number': _numberController.text,
    };

    setState(() {
      _accounts.insert(0, account);
      _filteredAccounts = List.from(_accounts);
      _nameController.clear();
      _numberController.clear();
      _successMessage = "✓ Account saved successfully";
    });

    _saveToStorage();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _successMessage != null) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }

  void _deleteAccount(int index) {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      final removed = _filteredAccounts.removeAt(index);
      _accounts.remove(removed);
      _successMessage = "✓ Account deleted: ${removed['name']}";
    });
    _saveToStorage();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _successMessage != null) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }

  void _editAccount(Map<String, String> account) {
    _nameController.text = account['name']!;
    _numberController.text = account['number']!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController),
            const SizedBox(height: 10),
            TextField(controller: _numberController),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                _nameController.clear();
                _numberController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                account['name'] = _upperCaseEnabled
                    ? _nameController.text.toUpperCase()
                    : _nameController.text;
                account['number'] = _numberController.text;
                _successMessage = "✓ Account updated: ${account['name']}";
              });
              _saveToStorage();
              _nameController.clear();
              _numberController.clear();
              Navigator.pop(context);
              
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _successMessage != null) {
                  setState(() {
                    _successMessage = null;
                  });
                }
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _filterAccounts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAccounts = _accounts.where((a) {
        return a['name']!.toLowerCase().contains(query) ||
            a['number']!.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _exportBackup,
            tooltip: 'Export Backup',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importRestore,
            tooltip: 'Import Restore',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Error Message Display
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(Icons.close, color: Colors.red.shade700, size: 18),
                    ),
                  ],
                ),
              ),
            
            // Success Message Display
            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _successMessage = null),
                      child: Icon(Icons.close, color: Colors.green.shade700, size: 18),
                    ),
                  ],
                ),
              ),
            
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveAccount,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Account'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSendingReverse ? null : _sendReverseSms,
                    icon: _isSendingReverse
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isSendingReverse ? 'Sending...' : 'Reverse SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredAccounts.isEmpty && _accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contacts, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No accounts yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first account above',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAccounts.length,
                      itemBuilder: (c, i) {
                        final acc = _filteredAccounts[i];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                acc['name']![0].toUpperCase(),
                                style: TextStyle(color: Colors.green.shade800),
                              ),
                            ),
                            title: Text(
                              acc['name']!,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(acc['number']!),
                            onTap: () => _editAccount(acc),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAccount(i),
                            ),
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
}
