import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:crm_admin/data/models/subscription/subscription_models.dart';
import 'package:crm_admin/data/repositories/subscription_repository.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepository _repository;

  SubscriptionProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SubscriptionDetails? _subscription;
  SubscriptionDetails? get subscription => _subscription;

  PricingData? _pricing;
  PricingData? get pricing => _pricing;

  CostEstimate? _estimate;
  CostEstimate? get estimate => _estimate;

  Map<String, dynamic>? _requestCalculation;
  Map<String, dynamic>? get requestCalculation => _requestCalculation;

  List<SubscriptionRequest> _myRequests = [];
  List<SubscriptionRequest> get myRequests => _myRequests;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    dev.log('🔄 [SubscriptionProvider] Loading: $value', name: 'SUBSCRIPTION');
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    dev.log('⚠️ [SubscriptionProvider] Error: $value', name: 'SUBSCRIPTION');
    _error = value;
    notifyListeners();
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data['message'] != null) {
        return e.response?.data['message'];
      }
      return e.message ?? 'An unexpected error occurred';
    }
    return e.toString();
  }

  /// Check if user has an active (non-expired) subscription
  bool get hasActiveSubscription {
    final active = _subscription?.isActive ?? false;
    dev.log(
      '✅ [SubscriptionProvider] Has active subscription: $active',
      name: 'SUBSCRIPTION',
    );
    return active;
  }

  /// Check if subscription is expired
  bool get isExpired {
    final expired = _subscription?.expired ?? true;
    dev.log(
      '⏰ [SubscriptionProvider] Subscription expired: $expired',
      name: 'SUBSCRIPTION',
    );
    return expired;
  }

  Future<void> fetchUserSubscription(String userId) async {
    dev.log(
      '🚀 [SubscriptionProvider] Fetching subscription for user: $userId',
      name: 'SUBSCRIPTION',
    );
    _setLoading(true);
    try {
      _subscription = await _repository.getUserSubscription(userId);
      if (_subscription != null) {
        dev.log(
          '✅ [SubscriptionProvider] Subscription: Plan=${_subscription!.planName}, Expired=${_subscription!.expired}, Days=${_subscription!.daysRemaining}',
          name: 'SUBSCRIPTION',
        );
      } else {
        dev.log(
          '📭 [SubscriptionProvider] No subscription found',
          name: 'SUBSCRIPTION',
        );
      }
      _error = null;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionProvider] Fetch failed: $e',
        name: 'SUBSCRIPTION',
      );
      _error = _handleError(e);
    }
    _setLoading(false);
  }

  Future<void> fetchPricing() async {
    dev.log(
      '🚀 [SubscriptionProvider] Fetching pricing...',
      name: 'SUBSCRIPTION',
    );
    _setLoading(true);
    try {
      _pricing = await _repository.getPricing();
      dev.log(
        '✅ [SubscriptionProvider] Pricing fetched successfully',
        name: 'SUBSCRIPTION',
      );
      _error = null;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionProvider] Pricing fetch failed: $e',
        name: 'SUBSCRIPTION',
      );
      _error = _handleError(e);
    }
    _setLoading(false);
  }

  Future<bool> estimateCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    dev.log(
      '🚀 [SubscriptionProvider] Estimating plan: SubAdmins=$numSubAdmins, Employees=$numEmployees, Days=$subscriptionDurationDays',
      name: 'SUBSCRIPTION',
    );
    _setLoading(true);
    try {
      _estimate = await _repository.estimateCustomPlan(
        numSubAdmins: numSubAdmins,
        numEmployees: numEmployees,
        subscriptionDurationDays: subscriptionDurationDays,
      );
      dev.log(
        '✅ [SubscriptionProvider] Estimate: ${_estimate?.totalCost}',
        name: 'SUBSCRIPTION',
      );
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionProvider] Estimate failed: $e',
        name: 'SUBSCRIPTION',
      );
      _error = _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> requestCustomPlan({
    required int numSubAdmins,
    required int numEmployees,
    required int subscriptionDurationDays,
  }) async {
    dev.log(
      '🚀 [SubscriptionProvider] Requesting plan: SubAdmins=$numSubAdmins, Employees=$numEmployees, Days=$subscriptionDurationDays',
      name: 'SUBSCRIPTION',
    );
    _setLoading(true);
    try {
      _requestCalculation = await _repository.requestCustomPlan(
        numSubAdmins: numSubAdmins,
        numEmployees: numEmployees,
        subscriptionDurationDays: subscriptionDurationDays,
      );
      dev.log(
        '✅ [SubscriptionProvider] Plan requested successfully',
        name: 'SUBSCRIPTION',
      );

      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionProvider] Request failed: $e',
        name: 'SUBSCRIPTION',
      );
      _error = _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchMyRequests() async {
    dev.log(
      '🚀 [SubscriptionProvider] Fetching my requests...',
      name: 'SUBSCRIPTION',
    );
    _setLoading(true);
    try {
      _myRequests = await _repository.getMyRequests();
      dev.log(
        '✅ [SubscriptionProvider] Found ${_myRequests.length} requests',
        name: 'SUBSCRIPTION',
      );
      _error = null;
    } catch (e) {
      dev.log(
        '❌ [SubscriptionProvider] Fetch requests failed: $e',
        name: 'SUBSCRIPTION',
      );
      _error = _handleError(e);
    }
    _setLoading(false);
  }

  void clearEstimate() {
    dev.log(
      '🗑️ [SubscriptionProvider] Clearing estimate',
      name: 'SUBSCRIPTION',
    );
    _estimate = null;
    _requestCalculation = null;
    notifyListeners();
  }
}
