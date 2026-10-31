import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/member.dart';
import '../models/collection_event.dart';
import '../models/payment_record.dart';
import '../models/member_balance.dart';

class BadmintonController extends GetxController {
  final GetStorage _storage;

  BadmintonController({GetStorage? storage})
      : _storage = storage ?? GetStorage();

  final RxList<Member> members = <Member>[].obs;
  final RxList<CollectionEvent> collections = <CollectionEvent>[].obs;
  final RxList<PaymentRecord> payments = <PaymentRecord>[].obs;

  final RxString currencySymbol = '₹'.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = 'all'.obs; // 'all', 'pending', 'settled'

  static const List<int> avatarColors = [
    0xFF1B5E20, // Green
    0xFF00695C, // Teal
    0xFF0277BD, // Light Blue
    0xFF283593, // Indigo
    0xFF4A148C, // Purple
    0xFFC2185B, // Pink
    0xFFD84315, // Deep Orange
    0xFF4E342E, // Brown
    0xFF37474F, // Blue Grey
  ];

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
  }

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    Widget? icon,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: colorText,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        icon: icon,
      );
    }
  }

  void loadFromStorage() {
    try {
      currencySymbol.value = _storage.read<String>('currencySymbol') ?? '₹';

      final membersJson = _storage.read<List>('members');
      if (membersJson != null && membersJson.isNotEmpty) {
        members.value = membersJson
            .map((m) => Member.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }

      final collectionsJson = _storage.read<List>('collections');
      if (collectionsJson != null) {
        collections.value = collectionsJson
            .map((c) => CollectionEvent.fromMap(Map<String, dynamic>.from(c)))
            .toList();
      }

      final paymentsJson = _storage.read<List>('payments');
      if (paymentsJson != null) {
        payments.value = paymentsJson
            .map((p) => PaymentRecord.fromMap(Map<String, dynamic>.from(p)))
            .toList();
      }
    } catch (e) {
      debugPrint('Storage load error: $e');
    }

    // If completely first launch, load rich sample data
    if (members.isEmpty) {
      loadInitialSampleData();
    }
  }

  void saveToStorage() {
    try {
      _storage.write('currencySymbol', currencySymbol.value);
      _storage.write('members', members.map((m) => m.toMap()).toList());
      _storage.write('collections', collections.map((c) => c.toMap()).toList());
      _storage.write('payments', payments.map((p) => p.toMap()).toList());
    } catch (e) {
      debugPrint('Storage write error: $e');
    }
  }

  void setCurrency(String symbol) {
    currencySymbol.value = symbol;
    saveToStorage();
  }

  // MARK: - Balance Calculations
  MemberBalance getBalanceForMember(String memberId) {
    final member = members.firstWhereOrNull((m) => m.id == memberId);
    if (member == null) {
      return MemberBalance(
        member: Member(id: memberId, name: 'Unknown', colorValue: 0xFF9E9E9E),
        totalOwed: 0,
        totalPaid: 0,
      );
    }

    double totalOwed = 0;
    for (var c in collections) {
      if (c.targetMemberIds.contains(memberId)) {
        totalOwed += c.amountPerMember;
      }
    }

    double totalPaid = 0;
    for (var p in payments) {
      if (p.memberId == memberId) {
        totalPaid += p.amount;
      }
    }

    return MemberBalance(
      member: member,
      totalOwed: totalOwed,
      totalPaid: totalPaid,
    );
  }

  List<MemberBalance> get allMemberBalances {
    return members.map((m) => getBalanceForMember(m.id)).toList();
  }

  List<MemberBalance> get filteredMemberBalances {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = filterStatus.value;

    return allMemberBalances.where((b) {
      final matchesQuery = query.isEmpty ||
          b.member.name.toLowerCase().contains(query) ||
          b.member.phone.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (filter == 'pending') {
        return b.remainingDue > 0;
      } else if (filter == 'settled') {
        return b.remainingDue <= 0;
      }
      return true;
    }).toList();
  }

  double get totalGroupOwed {
    double total = 0;
    for (var b in allMemberBalances) {
      total += b.totalOwed;
    }
    return total;
  }

  double get totalGroupCollected {
    double total = 0;
    for (var p in payments) {
      total += p.amount;
    }
    return total;
  }

  double get totalGroupPending {
    double total = 0;
    for (var b in allMemberBalances) {
      if (b.remainingDue > 0) {
        total += b.remainingDue;
      }
    }
    return total;
  }

  int get pendingMembersCount =>
      allMemberBalances.where((b) => b.remainingDue > 0).length;

  int get settledMembersCount =>
      allMemberBalances.where((b) => b.remainingDue <= 0).length;

  // MARK: - Member Operations
  void addMember({required String name, String phone = ''}) {
    final randomColor = avatarColors[Random().nextInt(avatarColors.length)];
    final newMember = Member(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: phone.trim(),
      colorValue: randomColor,
      isActive: true,
      joinedAt: DateTime.now(),
    );
    members.add(newMember);
    saveToStorage();
    _showSnackbar(
      'Member Added',
      '${newMember.name} joined the badminton club!',
      backgroundColor: const Color(0xFF1B5E20),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void updateMember(Member updated) {
    final idx = members.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      members[idx] = updated;
      saveToStorage();
    }
  }

  void deleteMember(String id) {
    members.removeWhere((m) => m.id == id);
    // remove target ids from collections
    for (int i = 0; i < collections.length; i++) {
      if (collections[i].targetMemberIds.contains(id)) {
        final updatedList = List<String>.from(collections[i].targetMemberIds)
          ..remove(id);
        collections[i] =
            collections[i].copyWith(targetMemberIds: updatedList);
      }
    }
    // remove their payments
    payments.removeWhere((p) => p.memberId == id);
    saveToStorage();
  }

  // MARK: - Collection Operations
  /// Adds a new collection entry (e.g. 500 for new shuttles)
  /// This automatically increases the remaining dues of all selected members!
  void addNewCollection({
    required String title,
    required double amountPerMember,
    List<String>? targetMemberIds,
    String notes = '',
    String shuttleBrand = 'Yonex Mavis 350',
  }) {
    final targets = targetMemberIds ??
        members.where((m) => m.isActive).map((m) => m.id).toList();

    final newCollection = CollectionEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      amountPerMember: amountPerMember,
      notes: notes.trim(),
      targetMemberIds: targets,
      createdAt: DateTime.now(),
      shuttleBrand: shuttleBrand,
    );

    collections.insert(0, newCollection);
    saveToStorage();

    _showSnackbar(
      'New Collection Added! 🏸',
      '${currencySymbol.value}${amountPerMember.toStringAsFixed(0)} added to ${targets.length} members remaining dues.',
      backgroundColor: const Color(0xFF0F9D58),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.sports_tennis, color: Colors.white),
    );
  }

  void deleteCollection(String id) {
    collections.removeWhere((c) => c.id == id);
    payments.removeWhere((p) => p.collectionEventId == id);
    saveToStorage();
    _showSnackbar(
      'Collection Deleted',
      'Collection entry removed and balances updated.',
      duration: const Duration(seconds: 2),
    );
  }

  // MARK: - Payment Operations
  /// One-tap Check / Settle: marks the member fully paid for all their remaining dues!
  void quickSettleMember(String memberId, {String method = 'Cash'}) {
    final balance = getBalanceForMember(memberId);
    if (balance.remainingDue <= 0) {
      _showSnackbar(
        'Already Settled',
        '${balance.member.name} has no remaining dues!',
      );
      return;
    }

    final amountToPay = balance.remainingDue;
    final payment = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      amount: amountToPay,
      date: DateTime.now(),
      paymentMethod: method,
      notes: 'Full balance settled',
    );

    payments.insert(0, payment);
    saveToStorage();

    _showSnackbar(
      'Checked & Paid! ✅',
      '${balance.member.name} paid full remaining ${currencySymbol.value}${amountToPay.toStringAsFixed(0)}',
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Partial or Custom Payment: player gives some amount, remaining stays in their balance!
  void recordPayment({
    required String memberId,
    required double amount,
    String paymentMethod = 'UPI / Online',
    String notes = '',
    String? collectionId,
  }) {
    if (amount <= 0) return;

    final member = members.firstWhereOrNull((m) => m.id == memberId);
    final memberName = member?.name ?? 'Player';

    final payment = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      notes: notes.trim(),
      collectionEventId: collectionId,
    );

    payments.insert(0, payment);
    saveToStorage();

    final updatedBalance = getBalanceForMember(memberId);
    String feedback;
    if (updatedBalance.remainingDue <= 0) {
      feedback = 'Paid in full! Dues fully cleared.';
    } else {
      feedback =
          'Recorded ${currencySymbol.value}${amount.toStringAsFixed(0)}. Remaining: ${currencySymbol.value}${updatedBalance.remainingDue.toStringAsFixed(0)}';
    }

    _showSnackbar(
      'Payment Recorded 💰',
      '$memberName: $feedback',
      backgroundColor: const Color(0xFF1565C0),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.payment, color: Colors.white),
    );
  }

  void deletePayment(String paymentId) {
    payments.removeWhere((p) => p.id == paymentId);
    saveToStorage();
    _showSnackbar(
      'Payment Deleted',
      'Payment removed and remaining balances updated.',
      duration: const Duration(seconds: 2),
    );
  }

  List<PaymentRecord> getPaymentsForMember(String memberId) {
    return payments.where((p) => p.memberId == memberId).toList();
  }

  List<CollectionEvent> getCollectionsForMember(String memberId) {
    return collections.where((c) => c.targetMemberIds.contains(memberId)).toList();
  }

  // MARK: - WhatsApp Share Report
  String generateShareableSummary() {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    buffer.writeln('🏸 *BADMINTON CLUB - SHUTTLE COLLECTION REPORT* 🏸');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('💰 Total Collected: ${currencySymbol.value}${totalGroupCollected.toStringAsFixed(0)}');
    buffer.writeln('⏳ Total Pending: ${currencySymbol.value}${totalGroupPending.toStringAsFixed(0)}');
    buffer.writeln('-----------------------------------');

    final pending = allMemberBalances.where((b) => b.remainingDue > 0).toList();
    final settled = allMemberBalances.where((b) => b.remainingDue <= 0).toList();

    if (pending.isNotEmpty) {
      buffer.writeln('🔴 *PENDING DUES (${pending.length} Players):*');
      for (var b in pending) {
        if (b.totalPaid > 0) {
          buffer.writeln('• ${b.member.name}: ${currencySymbol.value}${b.remainingDue.toStringAsFixed(0)} remaining (Paid ${currencySymbol.value}${b.totalPaid.toStringAsFixed(0)} of ${currencySymbol.value}${b.totalOwed.toStringAsFixed(0)})');
        } else {
          buffer.writeln('• ${b.member.name}: ${currencySymbol.value}${b.remainingDue.toStringAsFixed(0)} due');
        }
      }
      buffer.writeln('');
    }

    if (settled.isNotEmpty) {
      buffer.writeln('🟢 *CLEARED / SETTLED (${settled.length} Players):*');
      for (var b in settled) {
        if (b.remainingDue < 0) {
          buffer.writeln('• ${b.member.name}: Settled (Advance ${currencySymbol.value}${b.remainingDue.abs().toStringAsFixed(0)}) ✅');
        } else {
          buffer.writeln('• ${b.member.name}: Paid in full ✅');
        }
      }
    }

    buffer.writeln('-----------------------------------');
    buffer.writeln('🏸 Please clear your remaining dues for the new shuttles box! Thank you!');
    return buffer.toString();
  }

  // MARK: - Initial Sample Data
  void loadInitialSampleData() {
    final now = DateTime.now();

    final sampleMembers = [
      Member(
        id: 'm1',
        name: 'Rahul Sharma',
        phone: '+91 98765 43210',
        colorValue: 0xFF1B5E20,
        joinedAt: now.subtract(const Duration(days: 30)),
      ),
      Member(
        id: 'm2',
        name: 'Amit Patel',
        phone: '+91 98111 22233',
        colorValue: 0xFF0277BD,
        joinedAt: now.subtract(const Duration(days: 30)),
      ),
      Member(
        id: 'm3',
        name: 'Vikram Singh',
        phone: '+91 97222 33344',
        colorValue: 0xFFD84315,
        joinedAt: now.subtract(const Duration(days: 28)),
      ),
      Member(
        id: 'm4',
        name: 'Alex Johnson',
        phone: '+91 96333 44455',
        colorValue: 0xFF4A148C,
        joinedAt: now.subtract(const Duration(days: 25)),
      ),
      Member(
        id: 'm5',
        name: 'David Miller',
        phone: '+91 95444 55566',
        colorValue: 0xFF00695C,
        joinedAt: now.subtract(const Duration(days: 20)),
      ),
      Member(
        id: 'm6',
        name: 'Suresh Kumar',
        phone: '+91 94555 66677',
        colorValue: 0xFFC2185B,
        joinedAt: now.subtract(const Duration(days: 15)),
      ),
    ];

    members.value = sampleMembers;

    // A collection entry: 500 for Yonex Mavis 350 shuttles
    final sampleCollection = CollectionEvent(
      id: 'c1',
      title: 'New Shuttles (Yonex Mavis 350 Box)',
      amountPerMember: 500,
      notes: 'Monthly shuttle pool - 6 tubes',
      targetMemberIds: ['m1', 'm2', 'm3', 'm4', 'm5', 'm6'],
      createdAt: now.subtract(const Duration(days: 3)),
      shuttleBrand: 'Yonex Mavis 350',
    );

    collections.value = [sampleCollection];

    // Some members have paid full (checked), some partial, some haven't paid yet!
    final samplePayments = [
      PaymentRecord(
        id: 'p1',
        memberId: 'm1',
        amount: 500, // Rahul paid in full (Checked)
        date: now.subtract(const Duration(days: 2)),
        paymentMethod: 'UPI / GPay',
        notes: 'Full payment',
        collectionEventId: 'c1',
      ),
      PaymentRecord(
        id: 'p2',
        memberId: 'm2',
        amount: 250, // Amit paid partial 250 (250 remains)
        date: now.subtract(const Duration(days: 1)),
        paymentMethod: 'Cash',
        notes: 'Gave 250 cash at court, 250 remaining',
        collectionEventId: 'c1',
      ),
      PaymentRecord(
        id: 'p3',
        memberId: 'm4',
        amount: 500, // Alex paid in full
        date: now.subtract(const Duration(hours: 12)),
        paymentMethod: 'UPI / Online',
        notes: 'GPay payment',
        collectionEventId: 'c1',
      ),
      // Vikram (m3), David (m5), Suresh (m6) owe full 500
    ];

    payments.value = samplePayments;
    saveToStorage();
  }

  void resetAllData() {
    members.clear();
    collections.clear();
    payments.clear();
    _storage.erase();
    loadInitialSampleData();
    _showSnackbar(
      'Reset Complete',
      'Sample badminton data restored.',
    );
  }
}
