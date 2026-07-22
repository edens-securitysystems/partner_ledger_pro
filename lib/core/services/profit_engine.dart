import '../models/entities/partner.dart';
import '../models/entities/transaction.dart';

class PartnerProfitShare {
  final String partnerId;
  final String partnerName;
  final double ownershipPercentage;
  final double shareAmount;
  final double percentageOfTotal;

  const PartnerProfitShare({
    required this.partnerId,
    required this.partnerName,
    required this.ownershipPercentage,
    required this.shareAmount,
    required this.percentageOfTotal,
  });
}

class ProfitSummary {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final double profitMargin;
  final List<PartnerProfitShare> partnerShares;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final int transactionCount;

  const ProfitSummary({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netProfit = 0.0,
    this.profitMargin = 0.0,
    this.partnerShares = const [],
    this.incomeByCategory = const {},
    this.expenseByCategory = const {},
    this.transactionCount = 0,
  });
}

class ProfitEngine {
  ProfitSummary calculateNetProfit(List<Transaction> transactions) {
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
        incomeByCategory.update(
          t.category ?? 'Uncategorized',
          (v) => v + t.amount,
          ifAbsent: () => t.amount,
        );
      } else if (t.isExpense) {
        totalExpense += t.amount;
        expenseByCategory.update(
          t.category ?? 'Uncategorized',
          (v) => v + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    final netProfit = totalIncome - totalExpense;
    final profitMargin =
        totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0.0;

    return ProfitSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netProfit: netProfit,
      profitMargin: profitMargin,
      incomeByCategory: Map.from(incomeByCategory),
      expenseByCategory: Map.from(expenseByCategory),
      transactionCount: transactions.length,
    );
  }

  List<PartnerProfitShare> distributeByPercentage({
    required double profit,
    required List<Partner> partners,
  }) {
    if (partners.isEmpty) return [];

    final totalOwnership =
        partners.fold(0.0, (sum, p) => sum + p.ownershipPercentage);
    if (totalOwnership <= 0) return [];

    return partners.map((partner) {
      final share =
          profit * (partner.ownershipPercentage / totalOwnership);
      return PartnerProfitShare(
        partnerId: partner.id,
        partnerName: partner.name,
        ownershipPercentage: partner.ownershipPercentage,
        shareAmount: share,
        percentageOfTotal:
            totalOwnership > 0
                ? (partner.ownershipPercentage / totalOwnership) * 100
                : 0.0,
      );
    }).toList();
  }

  List<PartnerProfitShare> distributeEqually({
    required double profit,
    required List<Partner> partners,
  }) {
    if (partners.isEmpty) return [];

    final sharePerPartner = profit / partners.length;
    final percentagePerPartner =
        partners.isNotEmpty ? 100.0 / partners.length : 0.0;

    return partners.map((partner) {
      return PartnerProfitShare(
        partnerId: partner.id,
        partnerName: partner.name,
        ownershipPercentage: percentagePerPartner,
        shareAmount: sharePerPartner,
        percentageOfTotal: percentagePerPartner,
      );
    }).toList();
  }

  List<PartnerProfitShare> distributeByCustomRatios({
    required double profit,
    required List<Partner> partners,
    required Map<String, double> customRatios,
  }) {
    if (partners.isEmpty) return [];

    final totalRatio =
        partners.fold(0.0, (sum, p) => sum + (customRatios[p.id] ?? 0.0));
    if (totalRatio <= 0) return [];

    return partners.map((partner) {
      final ratio = customRatios[partner.id] ?? 0.0;
      final share = profit * (ratio / totalRatio);
      return PartnerProfitShare(
        partnerId: partner.id,
        partnerName: partner.name,
        ownershipPercentage:
            totalRatio > 0 ? (ratio / totalRatio) * 100 : 0.0,
        shareAmount: share,
        percentageOfTotal:
            totalRatio > 0 ? (ratio / totalRatio) * 100 : 0.0,
      );
    }).toList();
  }

  List<PartnerProfitShare> calculatePartnerShares({
    required double profit,
    required List<Partner> partners,
  }) {
    return distributeByPercentage(profit: profit, partners: partners);
  }

  ProfitSummary generateProfitSummary({
    required List<Transaction> transactions,
    required List<Partner> partners,
  }) {
    final baseSummary = calculateNetProfit(transactions);
    final partnerShares =
        calculatePartnerShares(
      profit: baseSummary.netProfit,
      partners: partners.where((p) => p.canReceiveProfit).toList(),
    );

    return ProfitSummary(
      totalIncome: baseSummary.totalIncome,
      totalExpense: baseSummary.totalExpense,
      netProfit: baseSummary.netProfit,
      profitMargin: baseSummary.profitMargin,
      partnerShares: partnerShares,
      incomeByCategory: baseSummary.incomeByCategory,
      expenseByCategory: baseSummary.expenseByCategory,
      transactionCount: baseSummary.transactionCount,
    );
  }
}
