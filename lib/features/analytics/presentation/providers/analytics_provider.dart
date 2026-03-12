import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/portfolio_analytics.dart';
import '../../domain/usecases/get_portfolio_analytics.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../../deposits/presentation/providers/deposit_providers.dart';

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepositoryImpl>((ref) {
  final depositRepository = ref.watch(depositRepositoryProvider);
  return AnalyticsRepositoryImpl(depositRepository);
});

// Use case provider
final analyticsUseCaseProvider = Provider<AnalyticsUseCase>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsUseCase(repository);
});

// Portfolio analytics provider
final portfolioAnalyticsProvider =
    FutureProvider<PortfolioAnalytics>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getPortfolioAnalytics();
});

// Portfolio summary provider
final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getPortfolioSummary();
});

// Bank distribution provider
final bankDistributionProvider =
    FutureProvider<List<BankDistribution>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getBankDistribution();
});

// Status distribution provider
final statusDistributionProvider =
    FutureProvider<List<StatusDistribution>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getStatusDistribution();
});

// Monthly trends provider
final monthlyTrendsProvider = FutureProvider<List<MonthlyTrend>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getMonthlyTrends();
});

// Maturity timeline provider
final maturityTimelineProvider =
    FutureProvider<List<MaturityTimeline>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getMaturityTimeline();
});

// Performance metrics provider
final performanceMetricsProvider =
    FutureProvider<PerformanceMetrics>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getPerformanceMetrics();
});

// Holder distribution provider
final holderDistributionProvider =
    FutureProvider<List<HolderDistribution>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getHolderDistribution();
});

// Top performers provider
final topPerformersProvider = FutureProvider<List<TopPerformer>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  ref.watch(depositsListProvider);
  return await useCase.getTopPerformers();
});

// Chart data providers for easier consumption in UI
final bankChartDataProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  final banks = await useCase.getBankDistribution();
  return useCase.getBankChartData(banks);
});

final trendChartDataProvider =
    FutureProvider<List<TimeSeriesDataPoint>>((ref) async {
  final useCase = ref.watch(analyticsUseCaseProvider);
  final trends = await useCase.getMonthlyTrends();
  return useCase.getTrendChartData(trends);
});
