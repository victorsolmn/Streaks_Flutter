# 🛠️ Streaker Premium - Detailed Development Implementation Plan

## Executive Summary
Complete technical implementation plan for premium features with UI/UX modifications, addressing the constraint of 5 existing bottom navigation tabs.

---

## 🎯 Navigation Architecture Solution

### Current Problem: 5 Tabs Already Exist
```
Current: [Home] [Streaks] [Nutrition] [Workouts] [Profile]
```

### **RECOMMENDED SOLUTION: Premium Integration Strategy**

#### Option 1: **Transform "Workouts" Tab** (RECOMMENDED)
```
New: [Home] [Streaks] [Nutrition] [AI Coach 👑] [Profile]
```
- Rename "Workouts" to "AI Coach"
- Add crown badge for premium indicator
- This becomes the premium feature hub
- Free users see limited AI features
- Premium users get full AI coaching

#### Option 2: **Floating Action Button (FAB)**
```
Main Screen:
┌─────────────────────────────┐
│                             │
│     Main Content            │
│                             │
│                    [+👑]    │ ← Floating premium button
├─────┬─────┬─────┬─────┬────┤
│Home │Streak│Food │Work │You │
└─────┴─────┴─────┴─────┴────┘
```

#### Option 3: **Profile Screen Integration**
- Add "Upgrade to Premium" as first item in Profile
- Show subscription status prominently
- Less intrusive but lower visibility

**RECOMMENDATION: Use Option 1 + Premium indicators across all screens**

---

## 📐 Detailed UI/UX Layout Modifications

### 1. **Home Screen Changes**

#### Current Layout Enhancement:
```dart
// home_screen_clean.dart modifications

// Add to top of screen (below sync indicator)
Container(
  height: showPremiumBanner ? 48 : 0,
  child: PremiumPromoBanner(
    message: "Unlock 15+ premium features",
    ctaText: "Try Free",
    onTap: () => navigateToPaywall(),
  ),
)

// Modify metric cards to show premium indicators
MetricCard(
  title: "Advanced Analytics",
  value: isPremium ? actualValue : "---",
  trailing: !isPremium ? PremiumBadge() : null,
  onTap: !isPremium ? showUpgradePrompt : showDetails,
)
```

### 2. **Nutrition Screen Modifications**

```dart
// nutrition_screen.dart

// Add AI scan button with premium gate
FloatingActionButton.extended(
  onPressed: () {
    if (userTier == 'free' && dailyScansUsed >= 3) {
      showUpgradeBottomSheet(
        title: "Daily limit reached",
        message: "You've used 3/3 free AI scans today",
        cta: "Upgrade for unlimited",
      );
    } else {
      launchAIScanner();
    }
  },
  label: Row(
    children: [
      Icon(Icons.camera_alt),
      Text("AI Scan"),
      if (userTier == 'free')
        Badge(label: Text("${3-dailyScansUsed}/3")),
    ],
  ),
)

// Modify food entry cards
NutritionEntryCard(
  showPremiumFeatures: userTier != 'free',
  onPremiumFeatureTap: userTier == 'free'
    ? () => showUpgradePrompt()
    : null,
)
```

### 3. **Profile Screen - Premium Hub**

```dart
// profile_screen.dart

// Add subscription status card at top
SubscriptionStatusCard(
  tier: userTier, // 'free', 'plus', 'pro'
  expiryDate: subscriptionEndDate,
  onManage: () => navigateToSubscriptionManager(),
  onUpgrade: () => navigateToPaywall(),
)

// Premium settings section
ListTile(
  leading: Icon(Icons.crown, color: Colors.amber),
  title: Text(
    userTier == 'free'
      ? "Upgrade to Premium"
      : "Manage Subscription"
  ),
  subtitle: Text(
    userTier == 'free'
      ? "Unlock all features"
      : "Premium member since $startDate"
  ),
  trailing: userTier != 'free'
    ? PremiumBadge(tier: userTier)
    : Icon(Icons.arrow_forward),
  onTap: () => navigateToPaywall(),
)
```

---

## 🏗️ Technical Implementation Architecture

### Phase 1: Infrastructure Setup (Week 1)

#### 1.1 **Subscription Service**
```dart
// lib/services/subscription_service.dart

class SubscriptionService extends ChangeNotifier {
  String _userTier = 'free'; // 'free', 'plus', 'pro'
  DateTime? _subscriptionEndDate;
  Map<String, int> _featureUsage = {};

  // RevenueCat integration
  Future<void> initializePurchases() async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.configure(
      PurchasesConfiguration(apiKey)
        ..appUserID = userId
    );
  }

  // Check subscription status
  Future<void> checkSubscriptionStatus() async {
    final purchaserInfo = await Purchases.getCustomerInfo();
    _updateTierFromEntitlements(purchaserInfo.entitlements);
  }

  // Purchase subscription
  Future<PurchaseResult> purchaseSubscription(String productId) async {
    try {
      final purchaseResult = await Purchases.purchaseProduct(productId);
      return PurchaseResult.success(purchaseResult);
    } catch (e) {
      return PurchaseResult.error(e.toString());
    }
  }
}
```

#### 1.2 **Feature Gating System**
```dart
// lib/services/feature_gate_service.dart

class FeatureGateService {
  static final Map<String, FeatureConfig> features = {
    'ai_scan': FeatureConfig(
      freeLimit: 3,
      plusLimit: null,
      proLimit: null,
      resetPeriod: Duration(days: 1),
    ),
    'detailed_analytics': FeatureConfig(
      freeLimit: 0,
      plusLimit: 30, // days of history
      proLimit: null,
    ),
    'streak_protection': FeatureConfig(
      freeLimit: 1,
      plusLimit: 2,
      proLimit: 5,
      resetPeriod: Duration(days: 30),
    ),
  };

  static bool canUseFeature(String feature, String userTier) {
    final config = features[feature];
    final usage = getFeatureUsage(feature);

    switch(userTier) {
      case 'free':
        return usage < (config.freeLimit ?? 0);
      case 'plus':
        return config.plusLimit == null || usage < config.plusLimit;
      case 'pro':
        return true; // Pro users have unlimited access
    }
  }
}
```

#### 1.3 **Database Schema Updates**
```sql
-- Supabase migrations

-- User subscription table
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  tier VARCHAR(10) DEFAULT 'free',
  status VARCHAR(20) DEFAULT 'active',
  started_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Feature usage tracking
CREATE TABLE feature_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  feature_name VARCHAR(50),
  usage_count INT DEFAULT 0,
  last_reset TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, feature_name)
);

-- Premium feature logs
CREATE TABLE premium_feature_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  feature_name VARCHAR(50),
  action VARCHAR(20), -- 'attempted', 'blocked', 'upgraded'
  user_tier VARCHAR(10),
  timestamp TIMESTAMP DEFAULT NOW()
);
```

### Phase 2: UI Components Library (Week 2)

#### 2.1 **Premium Badge Widget**
```dart
// lib/widgets/premium_badge.dart

class PremiumBadge extends StatelessWidget {
  final String tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier == 'pro'
            ? [Colors.grey[300]!, Colors.grey[600]!] // Diamond
            : [Colors.amber[300]!, Colors.amber[600]!], // Gold
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier == 'pro' ? Icons.diamond : Icons.crown,
            size: size,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            tier.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 2.2 **Locked Feature Overlay**
```dart
// lib/widgets/locked_feature_overlay.dart

class LockedFeatureOverlay extends StatelessWidget {
  final Widget child;
  final String featureName;
  final String requiredTier;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred content
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: child,
        ),
        // Lock overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "$featureName",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  PremiumBadge(tier: requiredTier),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onUpgrade,
                    child: Text("Unlock with $requiredTier"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

#### 2.3 **Upgrade Prompt Bottom Sheet**
```dart
// lib/widgets/upgrade_prompt_sheet.dart

class UpgradePromptSheet extends StatelessWidget {
  final String title;
  final String message;
  final String feature;
  final String requiredTier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),

          // Icon animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.amber,
                ),
              );
            },
          ),

          SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headline6),
          SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Feature comparison
          _buildFeatureComparison(),

          SizedBox(height: 24),

          // CTA buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Maybe Later"),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaywallScreen(
                          source: feature,
                        ),
                      ),
                    );
                  },
                  child: Text("Upgrade Now"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Phase 3: Paywall Implementation (Week 3)

#### 3.1 **Main Paywall Screen**
```dart
// lib/screens/premium/paywall_screen.dart

class PaywallScreen extends StatefulWidget {
  final String source; // Track where user came from

  @override
  _PaywallScreenState createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int selectedPlanIndex = 1; // Default to annual
  bool isLoading = false;

  final plans = [
    PlanOption(
      id: 'monthly_plus',
      name: 'Monthly',
      price: '₹499',
      period: '/month',
      savePercentage: 0,
    ),
    PlanOption(
      id: 'annual_plus',
      name: 'Annual',
      price: '₹333',
      period: '/month',
      originalPrice: '₹5,988',
      discountedPrice: '₹3,999',
      savePercentage: 33,
      badge: 'BEST VALUE',
    ),
    PlanOption(
      id: 'lifetime_pro',
      name: 'Lifetime',
      price: '₹9,999',
      period: 'one time',
      savePercentage: 67,
      badge: 'LIMITED OFFER',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Feature carousel
                    _buildFeatureCarousel(),

                    // Plan selector
                    _buildPlanSelector(),

                    // Features list
                    _buildFeaturesList(),

                    // Testimonials
                    _buildTestimonials(),

                    // FAQ
                    _buildFAQ(),
                  ],
                ),
              ),
            ),

            // Sticky CTA
            _buildStickyCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          final isSelected = selectedPlanIndex == index;

          return GestureDetector(
            onTap: () => setState(() => selectedPlanIndex = index),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                  ? Colors.amber.withOpacity(0.1)
                  : Colors.grey[50],
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                          ),
                        )
                      : null,
                  ),
                  SizedBox(width: 12),

                  // Plan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (plan.badge != null) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  plan.badge!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: plan.price,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: plan.period,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.savePercentage > 0)
                          Text(
                            "Save ${plan.savePercentage}%",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

### Phase 4: Feature Gating Implementation (Week 4)

#### 4.1 **AI Scan Gating**
```dart
// lib/screens/main/ai_scanner_screen.dart

class AIScannerScreen extends StatefulWidget {
  @override
  _AIScannerScreenState createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends State<AIScannerScreen> {
  int dailyScansUsed = 0;
  final int freeScanLimit = 3;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    final usage = await FeatureGateService.getFeatureUsage('ai_scan');
    setState(() => dailyScansUsed = usage);
  }

  Future<void> _handleScan() async {
    final userTier = context.read<SubscriptionService>().userTier;

    // Check limits for free users
    if (userTier == 'free' && dailyScansUsed >= freeScanLimit) {
      _showUpgradePrompt();
      return;
    }

    // Proceed with scan
    final result = await _performScan();

    // Update usage
    await FeatureGateService.incrementUsage('ai_scan');
    setState(() => dailyScansUsed++);

    // Show remaining scans for free users
    if (userTier == 'free') {
      final remaining = freeScanLimit - dailyScansUsed;
      if (remaining > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$remaining free scans remaining today"),
            action: SnackBarAction(
              label: "Get Unlimited",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaywallScreen()),
              ),
            ),
          ),
        );
      }
    }
  }

  void _showUpgradePrompt() {
    showModalBottomSheet(
      context: context,
      builder: (_) => UpgradePromptSheet(
        title: "Daily Limit Reached",
        message: "You've used all 3 free AI scans for today. "
                 "Upgrade to get unlimited scans!",
        feature: "ai_scan",
        requiredTier: "plus",
      ),
    );
  }
}
```

#### 4.2 **Analytics Gating**
```dart
// lib/screens/main/analytics_screen.dart

class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userTier = context.watch<SubscriptionService>().userTier;
    final isPremium = userTier != 'free';

    return Scaffold(
      appBar: AppBar(title: Text("Analytics")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Basic stats (free)
            StatsCard(
              title: "This Week",
              data: weeklyData,
              isPremium: true, // Always visible
            ),

            // Advanced analytics (premium)
            if (isPremium)
              AdvancedAnalyticsCard(data: advancedData)
            else
              LockedFeatureOverlay(
                featureName: "Advanced Analytics",
                requiredTier: "plus",
                onUpgrade: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaywallScreen()),
                ),
                child: Container(
                  height: 300,
                  child: AdvancedAnalyticsCard(
                    data: mockData, // Show blurred preview
                  ),
                ),
              ),

            // Historical data (premium)
            if (isPremium)
              HistoricalDataCard(data: historicalData)
            else
              ListTile(
                leading: Icon(Icons.lock, color: Colors.amber),
                title: Text("30-Day History"),
                subtitle: Text("View detailed historical data"),
                trailing: PremiumBadge(tier: 'plus'),
                onTap: () => _showUpgradePrompt(context),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Phase 5: Streak Protection System (Week 5)

#### 5.1 **Streak Protection Implementation**
```dart
// lib/services/streak_protection_service.dart

class StreakProtectionService {
  static Future<bool> canProtectStreak(String userId) async {
    final userTier = await getUserTier(userId);
    final protectionsUsed = await getProtectionsUsedThisMonth(userId);

    final limits = {
      'free': 1,
      'plus': 2,
      'pro': 5,
    };

    return protectionsUsed < limits[userTier]!;
  }

  static Future<void> showStreakAtRiskNotification(
    BuildContext context,
    int currentStreak,
  ) async {
    final canProtect = await canProtectStreak(userId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Streak at Risk!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your $currentStreak-day streak will end in 2 hours!",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (canProtect) ...[
              Text("You have streak protection available"),
              Text(
                "Protections remaining this month: ${getRemaining()}",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              Text(
                "No streak protections remaining",
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 8),
              PremiumBadge(tier: 'plus'),
              Text(
                "Upgrade for more protections",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Let it go"),
          ),
          ElevatedButton(
            onPressed: canProtect
              ? () async {
                  await useStreakProtection();
                  Navigator.pop(context);
                  showSuccessToast("Streak protected!");
                }
              : () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaywallScreen()),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: canProtect ? Colors.green : Colors.amber,
            ),
            child: Text(canProtect ? "Protect Streak" : "Get Protection"),
          ),
        ],
      ),
    );
  }
}
```

### Phase 6: Analytics & Tracking (Week 6)

#### 6.1 **Premium Analytics Events**
```dart
// lib/services/analytics_service.dart

class PremiumAnalytics {
  static void trackPaywallView(String source) {
    FirebaseAnalytics.instance.logEvent(
      name: 'paywall_viewed',
      parameters: {
        'source': source,
        'user_tier': currentTier,
        'days_since_install': daysSinceInstall,
      },
    );
  }

  static void trackUpgradeAttempt(String plan) {
    FirebaseAnalytics.instance.logEvent(
      name: 'upgrade_attempted',
      parameters: {
        'plan': plan,
        'price': getPlanPrice(plan),
        'source': lastPaywallSource,
      },
    );
  }

  static void trackFeatureBlocked(String feature) {
    FirebaseAnalytics.instance.logEvent(
      name: 'premium_feature_blocked',
      parameters: {
        'feature': feature,
        'user_tier': currentTier,
        'usage_count': getFeatureUsage(feature),
      },
    );
  }

  static void trackConversion(String plan, double revenue) {
    FirebaseAnalytics.instance.logEvent(
      name: 'purchase',
      parameters: {
        'plan': plan,
        'revenue': revenue,
        'currency': 'INR',
      },
    );
  }
}
```

---

## 📋 Development Timeline & Effort Estimation

### **Team Structure Required**
- 1 Senior Flutter Developer (Lead)
- 1 Mid-level Flutter Developer
- 1 Backend Developer (Supabase/Functions)
- 1 UI/UX Designer (Part-time)
- 1 QA Tester (Part-time)

### **Detailed Sprint Plan**

#### **Sprint 1 (Week 1-2): Foundation**
**Effort: 80 hours**

Tasks:
1. RevenueCat SDK integration (8h)
2. Subscription service implementation (12h)
3. Database schema updates (8h)
4. Feature gate service (12h)
5. Basic premium badge components (8h)
6. User tier management (8h)
7. Testing infrastructure setup (8h)
8. Documentation (4h)
9. Code review & fixes (12h)

#### **Sprint 2 (Week 3-4): UI Components**
**Effort: 80 hours**

Tasks:
1. Premium badges across app (12h)
2. Locked feature overlays (8h)
3. Upgrade prompt sheets (8h)
4. Paywall screen design (16h)
5. Plan selector component (8h)
6. Feature comparison cards (8h)
7. Animation implementations (8h)
8. A/B testing setup (8h)
9. Testing & bug fixes (12h)

#### **Sprint 3 (Week 5-6): Feature Gating**
**Effort: 80 hours**

Tasks:
1. AI scan limiting logic (12h)
2. Analytics gating (12h)
3. Streak protection system (12h)
4. History limitations (8h)
5. Usage tracking implementation (8h)
6. Reset mechanisms (8h)
7. Notification system updates (8h)
8. Edge case handling (12h)

#### **Sprint 4 (Week 7-8): Polish & Launch**
**Effort: 60 hours**

Tasks:
1. End-to-end testing (16h)
2. Performance optimization (8h)
3. Analytics integration (8h)
4. App store setup (8h)
5. Migration scripts (4h)
6. Documentation (4h)
7. Bug fixes from beta (12h)

**Total Effort: 300 hours (7-8 weeks)**

---

## 🔧 Technical Decisions Required

### **Before Starting Development:**

1. **Payment Provider Choice**
   - Option A: RevenueCat (Recommended) - Handles iOS/Android
   - Option B: Direct integration (StoreKit + Google Play)
   - Option C: Stripe for web support

2. **Pricing Strategy**
   - Need final prices for each tier
   - Decide on trial length (3, 7, or 14 days)
   - Regional pricing considerations

3. **Feature Limits**
   - Finalize exact limits for each tier
   - Decide reset periods (daily/monthly)
   - Grace period policies

4. **Navigation Decision**
   - Confirm replacing "Workouts" with "AI Coach"
   - Or implement FAB approach
   - Or keep current structure with Profile integration

5. **Migration Strategy**
   - Grandfather existing users?
   - Introductory pricing?
   - Beta testing approach

---

## 🚨 Risk Mitigation

### **Potential Issues & Solutions:**

1. **App Store Rejection**
   - Solution: Follow guidelines strictly
   - Have clear subscription terms
   - Implement restore purchases

2. **User Backlash**
   - Solution: Generous free tier
   - Grandfather early users
   - Clear communication

3. **Technical Issues**
   - Solution: Gradual rollout
   - Feature flags for quick disable
   - Comprehensive testing

4. **Low Conversion**
   - Solution: A/B testing framework
   - Quick iteration capability
   - User feedback loops

---

## 📊 Success Metrics to Track

### **Key Performance Indicators:**
1. **Paywall views** per user
2. **Trial start rate** (target: 25%)
3. **Trial-to-paid conversion** (target: 45%)
4. **Feature usage** by tier
5. **Churn rate** by plan
6. **Average revenue per user** (ARPU)
7. **Lifetime value** (LTV)
8. **Time to first upgrade**

### **A/B Tests to Run:**
1. Paywall timing (day 3 vs 7)
2. Price anchoring (show annual first)
3. Trial length (7 vs 14 days)
4. Feature limits (2 vs 3 AI scans)
5. Upgrade prompt copy variations

---

## ✅ Pre-Development Checklist

Before starting development, confirm:

- [ ] Navigation structure decision (AI Coach tab vs FAB)
- [ ] Final pricing for all tiers
- [ ] Exact feature limits per tier
- [ ] Payment provider selection
- [ ] Design mockups approved
- [ ] Analytics events defined
- [ ] Database migration plan
- [ ] Beta testing group ready
- [ ] App store assets prepared
- [ ] Legal terms updated

---

## 🎯 Next Steps

1. **Review this plan** and provide feedback
2. **Make navigation decision** (AI Coach tab recommended)
3. **Approve pricing structure**
4. **Confirm feature limits**
5. **Approve UI mockups** (I can create these)
6. **Begin Sprint 1** implementation

**Awaiting your approval to proceed with development!**