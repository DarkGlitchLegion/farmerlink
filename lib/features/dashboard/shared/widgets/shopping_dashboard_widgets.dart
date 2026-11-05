import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/domain/entities/user.dart';
import '../models/shopping_dashboard_models.dart';

class ShoppingDashboardHeader extends StatelessWidget {
  const ShoppingDashboardHeader({
    super.key,
    required this.user,
    required this.businessMode,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onSignOut,
    this.businessProfile,
  });

  final AuthUser user;
  final bool businessMode;
  final BusinessProfileData? businessProfile;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final businessName = businessProfile?.businessName.trim() ?? '';
    final title = businessName.isNotEmpty ? businessName : user.fullName;
    final subtitle = !businessMode
        ? 'Find fresh produce from FarmerLink sellers.'
        : businessProfile == null
        ? 'Business profile details are not available.'
        : [
            businessProfile!.businessAddress,
            businessProfile!.province,
          ].where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 23),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.darkGreen],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_rounded,
                color: AppColors.harvestYellow,
                size: 25,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FarmerLink  DAVNOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: .2,
                  ),
                ),
              ),
              _NotificationButton(
                count: unreadNotifications,
                onPressed: onNotifications,
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: onSignOut,
                color: Colors.white.withValues(alpha: .88),
                icon: const Icon(Icons.logout_rounded, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            businessMode ? 'Wholesale sourcing' : _greeting(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .76),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'FarmerLink shopper' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle.isEmpty
                          ? 'Business profile location not provided'
                          : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .76),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProfileAvatar(avatar: user.avatar),
            ],
          ),
          if (businessProfile != null) ...[
            const SizedBox(height: 10),
            _BusinessVerification(status: businessProfile!.verificationStatus),
          ],
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return '$greeting, ${user.firstName}';
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: count == 0 ? 'Notifications' : '$count unread notifications',
    onPressed: onPressed,
    color: Colors.white,
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.avatar});
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final value = avatar;
    if (value != null && value.startsWith('data:image/')) {
      try {
        final index = value.indexOf(',');
        if (index > 0) {
          return CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.memory(
                base64Decode(value.substring(index + 1)),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            ),
          );
        }
      } on FormatException {
        return _fallback();
      }
    }
    return _fallback();
  }

  Widget _fallback() => const CircleAvatar(
    radius: 24,
    backgroundColor: Color(0xFFEAF3E5),
    child: Icon(Icons.person_rounded, color: AppColors.primaryGreen),
  );
}

class _BusinessVerification extends StatelessWidget {
  const _BusinessVerification({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'approved' => 'Verified business',
      'rejected' => 'Verification not approved',
      _ => 'Verification pending',
    };
    final icon = status == 'approved'
        ? Icons.verified_rounded
        : Icons.hourglass_top_rounded;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: status == 'approved'
                  ? AppColors.accentGreen
                  : AppColors.harvestYellow,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingSectionHeader extends StatelessWidget {
  const ShoppingSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -.25,
          ),
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel!,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}

class MarketSearchField extends StatelessWidget {
  const MarketSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Search produce',
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: AppColors.primaryGreen,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6EBDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
      ),
    ),
  );
}

class CategoryFilters extends StatelessWidget {
  const CategoryFilters({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });
  final List<MarketCategory> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _CategoryChip(
          label: 'All produce',
          selected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        ...categories.map(
          (category) => _CategoryChip(
            label: category.name,
            selected: selectedId == category.id,
            onTap: () => onSelected(category.id),
          ),
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.darkGreen,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primaryGreen : const Color(0xFFE2E9DC),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
  );
}

class MarketProductCard extends StatelessWidget {
  const MarketProductCard({
    super.key,
    required this.product,
    required this.businessMode,
    this.onBulkOrder,
    this.onTap,
  });
  final MarketProduct product;
  final bool businessMode;
  final VoidCallback? onBulkOrder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EBDD)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x081A3824),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (product.qualityGrade?.isNotEmpty == true)
                      Text(
                        product.qualityGrade!,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                if (product.variety?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.variety!,
                    style: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: .62),
                      fontSize: 10.5,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Farmer #${product.farmerId}',
                  style: TextStyle(
                    color: AppColors.darkGreen.withValues(alpha: .57),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    Text(
                      '${_peso(product.pricePerUnit)} / ${product.unit}',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${product.availableQuantity} ${product.unit} available',
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .66),
                        fontSize: 10.5,
                      ),
                    ),
                    if (businessMode)
                      Text(
                        'Min. order ${product.minimumOrderQuantity} ${product.unit}',
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (businessMode) ...[
            const SizedBox(width: 9),
            IconButton.filledTonal(
              tooltip: onBulkOrder == null
                  ? 'No available harvest batch'
                  : 'Place bulk order',
              onPressed: onBulkOrder,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                backgroundColor: const Color(0xFFEAF3E5),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class ShoppingOrderCard extends StatelessWidget {
  const ShoppingOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onCancel,
  });
  final ShoppingOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7EBDD)),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3E5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Farmer #${order.farmerId} · ${formatShoppingDate(order.createdAt)}',
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _peso(order.totalAmount),
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _OrderStatus(status: order.status),
                ],
              ),
            ],
          ),
        ),
        if (onCancel != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Cancel order'),
            ),
          ),
      ],
    ),
  );
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ');
    final color = status == 'delivered'
        ? AppColors.primaryGreen
        : status == 'cancelled'
        ? const Color(0xFF9B1C1C)
        : const Color(0xFF8A6314);
    return Text(
      label.isEmpty ? 'Unknown' : label[0].toUpperCase() + label.substring(1),
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class SupplierSummaryCard extends StatelessWidget {
  const SupplierSummaryCard({
    super.key,
    required this.farmerId,
    required this.productCount,
  });
  final int farmerId;
  final int productCount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE6EBDD)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFEAF3E5),
          child: Icon(
            Icons.agriculture_rounded,
            color: AppColors.primaryGreen,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'Farmer #$farmerId',
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$productCount ${productCount == 1 ? 'listing' : 'listings'}',
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .58),
            fontSize: 10.5,
          ),
        ),
      ],
    ),
  );
}

class ShoppingEmptyState extends StatelessWidget {
  const ShoppingEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE6EBDD)),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.leafGreen, size: 30),
        const SizedBox(height: 9),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.darkGreen.withValues(alpha: .58),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class NotificationListSheet extends StatelessWidget {
  const NotificationListSheet({
    super.key,
    required this.notifications,
    required this.onMarkRead,
  });
  final List<ShoppingNotification> notifications;
  final Future<void> Function(int id) onMarkRead;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (notifications.isEmpty)
            const ShoppingEmptyState(
              title: 'You’re all caught up',
              message: 'New account notifications will appear here.',
              icon: Icons.notifications_none_rounded,
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      color: item.isRead
                          ? Colors.black38
                          : AppColors.primaryGreen,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 13,
                        fontWeight: item.isRead
                            ? FontWeight.w500
                            : FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      item.message,
                      style: TextStyle(
                        color: AppColors.darkGreen.withValues(alpha: .65),
                        fontSize: 11,
                      ),
                    ),
                    trailing: item.isRead
                        ? null
                        : TextButton(
                            onPressed: () async {
                              try {
                                await onMarkRead(item.id);
                                if (context.mounted) Navigator.pop(context);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not update this notification. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Mark read'),
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

class ShoppingDashboardLoading extends StatelessWidget {
  const ShoppingDashboardLoading({super.key, required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.primaryGreen,
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 190),
        Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Loading your dashboard…',
            style: TextStyle(color: AppColors.darkGreen),
          ),
        ),
      ],
    ),
  );
}

class ShoppingDashboardFailure extends StatelessWidget {
  const ShoppingDashboardFailure({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onSignIn,
  });
  final Object error;
  final Future<void> Function() onRetry;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final expired =
        error is ApiException && (error as ApiException).statusCode == 401;
    final message =
        error is ApiException && (error as ApiException).statusCode >= 500
        ? 'FarmerLink is having trouble right now. Please try again shortly.'
        : error is FormatException
        ? (error as FormatException).message
        : expired
        ? 'Your session has expired. Sign in again to load your shopping dashboard.'
        : 'Could not load dashboard data. Check your connection and try again.';
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        children: [
          const SizedBox(height: 170),
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.leafGreen,
            size: 46,
          ),
          const SizedBox(height: 16),
          const Text(
            'Dashboard unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: .65),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: expired
                ? FilledButton(
                    onPressed: onSignIn,
                    child: const Text('Sign in again'),
                  )
                : OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
          ),
        ],
      ),
    );
  }
}

String formatShoppingPeso(int amount) => _peso(amount);

String _peso(int amount) =>
    '₱${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

String formatShoppingDate(DateTime? date) {
  if (date == null) return 'Date unavailable';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final value = date.toLocal();
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
