import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/member.dart';
import '../models/collection_event.dart';
import '../models/payment_record.dart';
import '../models/member_balance.dart';
import '../models/badminton_match.dart';
import '../models/shuttle_purchase.dart';

class BadmintonController extends GetxController {
  final GetStorage _storage;

  BadmintonController({GetStorage? storage})
      : _storage = storage ?? GetStorage();

  final RxList<Member> members = <Member>[].obs;
  final RxList<CollectionEvent> collections = <CollectionEvent>[].obs;
  final RxList<PaymentRecord> payments = <PaymentRecord>[].obs;

  // Shuttle Purchases & Stock
  final RxList<ShuttlePurchase> shuttlePurchases = <ShuttlePurchase>[].obs;
  final RxInt shuttlesUsed = 0.obs;

  final RxString currencySymbol = '₹'.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = 'all'.obs; // 'all', 'pending', 'settled'

  // Matchmaking State
  final RxSet<String> selectedPresentMemberIds = <String>{}.obs;
  final Rx<MatchRound?> currentMatchRound = Rx<MatchRound?>(null);
  final RxInt matchRoundNumber = 1.obs;
  final RxList<String> lastRestedMemberIds = <String>[].obs;

  double get totalSpentOnShuttles {
    double sum = 0;
    for (var p in shuttlePurchases) {
      sum += p.totalCost;
    }
    return sum;
  }

  /// Cash remaining in kitty after deducting shuttle purchases:
  /// e.g. Collected 1000 - Bought 2 shuttles for 700 = 300 remaining!
  double get kittyBalanceRemaining => totalGroupCollected - totalSpentOnShuttles;

  int get totalShuttlesStockBought {
    int sum = 0;
    for (var p in shuttlePurchases) {
      sum += p.quantity;
    }
    return sum;
  }

  int get currentShuttleStock =>
      max(0, totalShuttlesStockBought - shuttlesUsed.value);

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

      final purchasesJson = _storage.read<List>('shuttlePurchases');
      if (purchasesJson != null) {
        shuttlePurchases.value = purchasesJson
            .map((p) => ShuttlePurchase.fromMap(Map<String, dynamic>.from(p)))
            .toList();
      }

      shuttlesUsed.value = _storage.read<int>('shuttlesUsed') ?? 0;
    } catch (e) {
      debugPrint('Storage load error: $e');
    }

    // If completely first launch, load rich sample data
    if (members.isEmpty) {
      loadInitialSampleData();
    }

    // Default all active members to present for matchmaking
    selectedPresentMemberIds.assignAll(
        members.where((m) => m.isActive).map((m) => m.id));
  }

  void saveToStorage() {
    try {
      _storage.write('currencySymbol', currencySymbol.value);
      _storage.write('members', members.map((m) => m.toMap()).toList());
      _storage.write('collections', collections.map((c) => c.toMap()).toList());
      _storage.write('payments', payments.map((p) => p.toMap()).toList());
      _storage.write(
          'shuttlePurchases', shuttlePurchases.map((p) => p.toMap()).toList());
      _storage.write('shuttlesUsed', shuttlesUsed.value);
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
  void addMember({
    required String name,
    String phone = '',
    int skillLevel = 2,
  }) {
    final randomColor = avatarColors[Random().nextInt(avatarColors.length)];
    final newMember = Member(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: phone.trim(),
      colorValue: randomColor,
      isActive: true,
      joinedAt: DateTime.now(),
      skillLevel: skillLevel,
    );
    members.add(newMember);
    selectedPresentMemberIds.add(newMember.id);
    saveToStorage();
    _showSnackbar(
      'Member Added',
      '${newMember.name} joined the badminton club (${newMember.skillBadge})!',
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
    selectedPresentMemberIds.remove(id);
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
    buffer.writeln('🛒 Spent on Shuttles: ${currencySymbol.value}${totalSpentOnShuttles.toStringAsFixed(0)}');
    buffer.writeln('💵 Kitty Cash Remaining: ${currencySymbol.value}${kittyBalanceRemaining.toStringAsFixed(0)}');
    buffer.writeln('📦 Shuttle Stock: $currentShuttleStock Shuttle(s)');
    buffer.writeln('⏳ Total Pending Dues: ${currencySymbol.value}${totalGroupPending.toStringAsFixed(0)}');
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
        skillLevel: 2, // Good Player
      ),
      Member(
        id: 'm2',
        name: 'Amit Patel',
        phone: '+91 98111 22233',
        colorValue: 0xFF0277BD,
        joinedAt: now.subtract(const Duration(days: 30)),
        skillLevel: 1, // Regular
      ),
      Member(
        id: 'm3',
        name: 'Vikram Singh',
        phone: '+91 97222 33344',
        colorValue: 0xFFD84315,
        joinedAt: now.subtract(const Duration(days: 28)),
        skillLevel: 2, // Good Player
      ),
      Member(
        id: 'm4',
        name: 'Alex Johnson',
        phone: '+91 96333 44455',
        colorValue: 0xFF4A148C,
        joinedAt: now.subtract(const Duration(days: 25)),
        skillLevel: 1, // Regular
      ),
      Member(
        id: 'm5',
        name: 'David Miller',
        phone: '+91 95444 55566',
        colorValue: 0xFF00695C,
        joinedAt: now.subtract(const Duration(days: 20)),
        skillLevel: 2, // Good Player
      ),
      Member(
        id: 'm6',
        name: 'Suresh Kumar',
        phone: '+91 94555 66677',
        colorValue: 0xFFC2185B,
        joinedAt: now.subtract(const Duration(days: 15)),
        skillLevel: 1, // Regular
      ),
      Member(
        id: 'm7',
        name: 'Priya Verma',
        phone: '+91 93666 77788',
        colorValue: 0xFF283593,
        joinedAt: now.subtract(const Duration(days: 10)),
        skillLevel: 2, // Good Player
      ),
      Member(
        id: 'm8',
        name: 'Rohan Das',
        phone: '+91 92777 88899',
        colorValue: 0xFF4E342E,
        joinedAt: now.subtract(const Duration(days: 5)),
        skillLevel: 1, // Regular
      ),
    ];

    members.value = sampleMembers;
    selectedPresentMemberIds.assignAll(sampleMembers.map((m) => m.id));

    // A collection entry: 500 for Yonex Mavis 350 shuttles
    final sampleCollection = CollectionEvent(
      id: 'c1',
      title: 'New Shuttles (Yonex Mavis 350)',
      amountPerMember: 500,
      notes: 'Monthly shuttle pool - 6 shuttles',
      targetMemberIds: ['m1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8'],
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

    // Sample shuttle purchase: 2 shuttles for 700 (matching user's example!)
    final samplePurchase = ShuttlePurchase(
      id: 'sp1',
      title: 'Yonex Mavis 350 (2 shuttles)',
      quantity: 2,
      totalCost: 700,
      date: now.subtract(const Duration(days: 2)),
      notes: 'Bought for club games',
    );
    shuttlePurchases.value = [samplePurchase];
    shuttlesUsed.value = 0;

    saveToStorage();
  }

  void resetAllData() {
    members.clear();
    collections.clear();
    payments.clear();
    shuttlePurchases.clear();
    shuttlesUsed.value = 0;
    _storage.erase();
    loadInitialSampleData();
    _showSnackbar(
      'Reset Complete',
      'Sample badminton data restored.',
    );
  }

  // MARK: - Shuttle Purchase & Stock Operations
  void recordShuttlePurchase({
    required String title,
    required int quantity,
    required double totalCost,
    String notes = '',
  }) {
    final purchase = ShuttlePurchase(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Badminton Shuttles' : title.trim(),
      quantity: quantity > 0 ? quantity : 1,
      totalCost: totalCost,
      date: DateTime.now(),
      notes: notes.trim(),
    );

    shuttlePurchases.insert(0, purchase);
    saveToStorage();

    _showSnackbar(
      'Shuttles Purchased 🏸',
      'Bought $quantity shuttle(s) for ${currencySymbol.value}${totalCost.toStringAsFixed(0)}. Remaining in Kitty: ${currencySymbol.value}${kittyBalanceRemaining.toStringAsFixed(0)}',
      backgroundColor: const Color(0xFF0F9D58),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.shopping_bag, color: Colors.white),
    );
  }

  void useShuttle({int count = 1}) {
    if (currentShuttleStock <= 0) {
      _showSnackbar(
        'Out of Stock! ⚠️',
        'No shuttles left in stock. Tap "+ Buy Shuttles" to add new stock!',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    shuttlesUsed.value += count;
    saveToStorage();

    _showSnackbar(
      'Shuttle Used 🏸',
      'Used $count shuttle. $currentShuttleStock shuttle(s) remaining in stock.',
      backgroundColor: Colors.blue.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.sports_tennis, color: Colors.white),
    );
  }

  void deleteShuttlePurchase(String id) {
    shuttlePurchases.removeWhere((p) => p.id == id);
    saveToStorage();
    _showSnackbar(
      'Purchase Deleted',
      'Shuttle purchase removed and kitty balance restored.',
      duration: const Duration(seconds: 2),
    );
  }

  // MARK: - Matchmaking Methods

  void toggleMemberAttendance(String id) {
    if (selectedPresentMemberIds.contains(id)) {
      selectedPresentMemberIds.remove(id);
    } else {
      selectedPresentMemberIds.add(id);
    }
  }

  void selectAllAttendance(bool selectAll) {
    if (selectAll) {
      selectedPresentMemberIds.assignAll(
          members.where((m) => m.isActive).map((m) => m.id));
    } else {
      selectedPresentMemberIds.clear();
    }
  }

  void updateMemberSkill(String id, int skillLevel) {
    final idx = members.indexWhere((m) => m.id == id);
    if (idx != -1) {
      members[idx] = members[idx].copyWith(skillLevel: skillLevel);
      saveToStorage();
      if (currentMatchRound.value != null) {
        generateBalancedMatches(isNextRound: false, showNotice: false);
      }
    }
  }

  /// Generate Balanced Doubles Matches in sets of 2
  void generateBalancedMatches({bool isNextRound = false, bool showNotice = true}) {
    final presentPlayers = members
        .where((m) => selectedPresentMemberIds.contains(m.id))
        .toList();

    if (presentPlayers.length < 4) {
      if (showNotice) {
        _showSnackbar(
          'Need At Least 4 Players',
          'Please select at least 4 present players using the checkboxes to create balanced sets of 2 (doubles).',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
      }
      return;
    }

    if (isNextRound) {
      matchRoundNumber.value++;
    }

    final roundNum = matchRoundNumber.value;
    final int courtsCount = presentPlayers.length ~/ 4;
    final int activeCount = courtsCount * 4;
    final int restingCount = presentPlayers.length - activeCount;

    // Prioritize rotation for resting players:
    // Players who rested in the last round will be guaranteed to play in this round.
    List<Member> activeList = [];
    List<Member> restingList = [];

    if (restingCount > 0) {
      final sortedForRotation = List<Member>.from(presentPlayers);
      sortedForRotation.sort((a, b) {
        final aRested = lastRestedMemberIds.contains(a.id) ? 0 : 1;
        final bRested = lastRestedMemberIds.contains(b.id) ? 0 : 1;
        return aRested.compareTo(bRested);
      });

      activeList = sortedForRotation.sublist(0, activeCount);
      restingList = sortedForRotation.sublist(activeCount);
      lastRestedMemberIds.value = restingList.map((m) => m.id).toList();
    } else {
      activeList = List<Member>.from(presentPlayers);
      restingList = [];
      lastRestedMemberIds.clear();
    }

    // Balance active players into `courtsCount` matches of 2 vs 2!
    final matches = _findBestBalancedMatches(activeList, courtsCount);

    currentMatchRound.value = MatchRound(
      roundNumber: roundNum,
      matches: matches,
      restingPlayers: restingList,
    );

    if (showNotice) {
      _showSnackbar(
        'Matches Generated! 🏸',
        'Set $roundNum ready with ${matches.length} balanced court${matches.length > 1 ? 's' : ''} in sets of 2.',
        backgroundColor: const Color(0xFF0F9D58),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.sports_tennis, color: Colors.white),
      );
    }
  }

  /// Internal optimization to pair players into sets of 2 with minimal skill difference
  List<BadmintonMatch> _findBestBalancedMatches(
      List<Member> players, int courtsCount) {
    if (courtsCount == 1) {
      return [_findBestDoublesMatch(players, 1)];
    }

    // For multiple courts, run randomized local optimization over permutations
    // to find the grouping of 4-player courts that produces the fairest games
    List<BadmintonMatch> bestMatches = [];
    int bestPenalty = 999999;
    final random = Random();

    for (int iter = 0; iter < 150; iter++) {
      final shuffled = List<Member>.from(players)..shuffle(random);
      int currentPenalty = 0;
      List<BadmintonMatch> currentMatches = [];

      for (int c = 0; c < courtsCount; c++) {
        final groupOf4 = shuffled.sublist(c * 4, (c + 1) * 4);
        final match = _findBestDoublesMatch(groupOf4, c + 1);
        currentMatches.add(match);
        currentPenalty += (match.skillDifference * 10);
      }

      if (currentPenalty < bestPenalty) {
        bestPenalty = currentPenalty;
        bestMatches = currentMatches;
        if (bestPenalty == 0) break; // Found 0 difference across all courts!
      }
    }

    return bestMatches;
  }

  /// Given 4 players, finds the most balanced 2 vs 2 doubles pairing
  BadmintonMatch _findBestDoublesMatch(
      List<Member> fourPlayers, int courtNumber) {
    final p = fourPlayers;
    // 3 possible pairings:
    // Pairing 1: (p0, p1) vs (p2, p3)
    // Pairing 2: (p0, p2) vs (p1, p3)
    // Pairing 3: (p0, p3) vs (p1, p2)

    final diff1 = ((p[0].skillLevel + p[1].skillLevel) -
            (p[2].skillLevel + p[3].skillLevel))
        .abs();
    final diff2 = ((p[0].skillLevel + p[2].skillLevel) -
            (p[1].skillLevel + p[3].skillLevel))
        .abs();
    final diff3 = ((p[0].skillLevel + p[3].skillLevel) -
            (p[1].skillLevel + p[2].skillLevel))
        .abs();

    final minDiff = min(diff1, min(diff2, diff3));

    List<BadmintonTeam> teams;
    if (minDiff == diff3) {
      teams = [
        BadmintonTeam(name: 'Team A', players: [p[0], p[3]]),
        BadmintonTeam(name: 'Team B', players: [p[1], p[2]]),
      ];
    } else if (minDiff == diff2) {
      teams = [
        BadmintonTeam(name: 'Team A', players: [p[0], p[2]]),
        BadmintonTeam(name: 'Team B', players: [p[1], p[3]]),
      ];
    } else {
      teams = [
        BadmintonTeam(name: 'Team A', players: [p[0], p[1]]),
        BadmintonTeam(name: 'Team B', players: [p[2], p[3]]),
      ];
    }

    return BadmintonMatch(
      courtNumber: courtNumber,
      teamA: teams[0],
      teamB: teams[1],
    );
  }

  String generateMatchWhatsAppText() {
    final round = currentMatchRound.value;
    if (round == null || round.matches.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln(
        '🏸 *BADMINTON TEAMS - GAME ${round.roundNumber}* 🏸');
    buffer.writeln(
        '👥 ${selectedPresentMemberIds.length} Players • ${round.matches.length} Court(s)');
    buffer.writeln('-----------------------------------');

    for (var match in round.matches) {
      buffer.writeln('🏸 *COURT ${match.courtNumber} (2 vs 2):*');
      buffer.writeln('🟢 Team 1: ${match.teamA.playerNames}');
      buffer.writeln('   vs');
      buffer.writeln('🔵 Team 2: ${match.teamB.playerNames}');
      buffer.writeln('');
    }

    if (round.restingPlayers.isNotEmpty) {
      buffer.writeln(
          '⏳ *Resting this game:* ${round.restingPlayers.map((m) => m.name).join(', ')} (Plays next game!)');
      buffer.writeln('-----------------------------------');
    }

    buffer.writeln('🏸 Play hard and have fun! 🔥');
    return buffer.toString();
  }
}
