import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart' show isSameDay;
import '../../core/models/service_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helper.dart';
import 'customer_booking_providers.dart';
import 'customer_information_form.dart';
import '../../core/models/customer_models.dart';
import '../../core/providers/api_providers.dart';
import '../schedule/schedule_providers.dart';
import '../../core/models/schedule_models.dart';
import '../business/business_providers.dart';
import '../../core/models/business_models.dart';
import '../employees/employees_providers.dart';
import '../../core/models/employee_models.dart';
import 'customer_booking_modal.dart';

class CustomerBookingScreen extends ConsumerStatefulWidget {
  final String businessId;

  const CustomerBookingScreen({super.key, required this.businessId});

  @override
  ConsumerState<CustomerBookingScreen> createState() =>
      _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends ConsumerState<CustomerBookingScreen> {
  final List<Service> _selectedServices = [];
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  Customer? _customer;
  String?
  _selectedEmployeeId; // For filtering time slots when multiple employees
  int _currentTab = 0; // 0 = Info, 1 = Booking
  final TextEditingController _serviceSearchController =
      TextEditingController();
  bool _isBookingInProgress = false; // Prevent duplicate booking requests

  @override
  void initState() {
    super.initState();
    // Don't set date automatically - let user choose from available dates
    _selectedDate = null;
    _serviceSearchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _serviceSearchController.removeListener(_filterServices);
    _serviceSearchController.dispose();
    super.dispose();
  }

  void _filterServices() {
    // Trigger rebuild when search text changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final servicesAsync = ref.watch(publicServicesProvider(widget.businessId));
    final schedulesAsync = ref.watch(schedulesProvider(widget.businessId));
    final businessAsync = ref.watch(businessProvider(widget.businessId));

    // Removed automatic date selection - user must choose

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      extendBodyBehindAppBar: true,

      body: SafeArea(
        child: businessAsync.when(
          data: (business) => schedulesAsync.when(
            data: (schedules) => servicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      child: Text(
                        l10n.noServicesAvailable,
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return _buildBusinessBookingPage(
                  business,
                  schedules,
                  services,
                  l10n,
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Text(
                    l10n.errorLoadingServices,
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingXL),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Text(
                  'Error loading schedule',
                  style: AppTheme.textStyleBody.copyWith(color: AppTheme.error),
                ),
              ),
            ),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingXL),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Text(
                'Error loading business information',
                style: AppTheme.textStyleBody.copyWith(color: AppTheme.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessBookingPage(
    Business business,
    List<Schedule> schedules,
    List<Service> services,
    dynamic l10n,
  ) {
    return Stack(
      children: [
        // Main Scrollable Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildModernHero(business, services, schedules, l10n),

              // Business Info Section
              _buildModernBusinessInfo(business, schedules, l10n),

              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        ),

        // Floating Action Button for Booking
        if (_selectedServices.isNotEmpty &&
            _selectedDate != null &&
            _selectedTimeSlot != null &&
            _customer != null)
          Positioned(
            bottom: AppTheme.spacingMD,
            left: AppTheme.spacingMD,
            right: AppTheme.spacingMD,
            child: Consumer(
              builder: (context, ref, child) {
                final appointmentState = ref.watch(
                  customerAppointmentNotifierProvider,
                );
                return _buildFloatingBookingButton(
                  l10n,
                  appointmentState,
                  business,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildModernHero(
    Business business,
    List<Service> services,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    return Container(
      color: AppTheme.backgroundMain,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                      business.logoUrl != null && business.logoUrl!.isNotEmpty
                      ? business.logoUrl!.startsWith('http')
                            ? Image.network(
                                business.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultLogo(),
                              )
                            : _buildDefaultLogo()
                      : _buildDefaultLogo(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // Business Name
              Text(
                business.name,
                style: AppTheme.textStyleH1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Business Description
              if (business.description != null &&
                  business.description!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                  ),
                  child: Text(
                    business.description!,
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXL * 2),
              // Action Buttons
              Column(
                children: [
                  // Booking Button (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showBookingModal(
                        context,
                        business,
                        services,
                        schedules,
                        l10n,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.indigoMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingLG + AppTheme.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Agendar cita',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  // WhatsApp Button (Secondary)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _openWhatsApp(business),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingLG + AppTheme.spacingSM,
                        ),
                        side: BorderSide(
                          color: AppTheme.borderLight,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat,
                            size: 20,
                            color: const Color(0xFF25D366),
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          const Text(
                            'Escribir a WhatsApp',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(Business business) async {
    final l10n = context.l10n;
    if (business.phone == null || business.phone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noPhoneNumberAvailable),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final phone = business.phone!.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOpeningWhatsApp}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showBookingModal(
    BuildContext context,
    Business business,
    List<Service> services,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingModalFullScreen(
        business: business,
        services: services,
        schedules: schedules,
        businessId: widget.businessId,
        l10n: l10n,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: textColor ?? Colors.white),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              label,
              style: AppTheme.textStyleBodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBusinessInfo(
    Business business,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Info Section
          if (business.phone != null || business.address != null) ...[
            _buildInfoCard(
              title: l10n.contactInformation,
              icon: Icons.contact_phone_rounded,
              children: [
                if (business.phone != null && business.phone!.isNotEmpty)
                  _buildSimpleInfoRow(
                    icon: Icons.phone_rounded,
                    text: business.phone!,
                  ),
                if (business.address != null &&
                    business.address!.isNotEmpty) ...[
                  if (business.phone != null && business.phone!.isNotEmpty)
                    const SizedBox(height: AppTheme.spacingMD),
                  _buildSimpleInfoRow(
                    icon: Icons.location_on_rounded,
                    text: business.address!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),
          ],

          // Working Hours Section
          _buildInfoCard(
            title: l10n.workingHours,
            icon: Icons.access_time_rounded,
            children: [
              ...List.generate(7, (index) {
                final dayOfWeek = (index + 1) % 7;
                final schedule = schedules.firstWhere(
                  (s) => s.dayOfWeek == dayOfWeek,
                  orElse: () =>
                      Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
                );
                final isToday = DateTime.now().weekday == (index + 1);
                final days = [
                  l10n.monday,
                  l10n.tuesday,
                  l10n.wednesday,
                  l10n.thursday,
                  l10n.friday,
                  l10n.saturday,
                  l10n.sunday,
                ];
                final isClosed =
                    schedule.isClosed ||
                    schedule.startTime == null ||
                    schedule.endTime == null;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < 6 ? AppTheme.spacingSM : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        days[index],
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday
                              ? AppTheme.indigoMain
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isClosed
                            ? l10n.closed
                            : '${schedule.startTime} - ${schedule.endTime}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: isClosed
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.indigoMain),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                title,
                style: AppTheme.textStyleH3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            text,
            style: AppTheme.textStyleBody.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMain,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.indigoMain.withOpacity(0.15),
                  AppTheme.indigoDark.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigoMain.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: AppTheme.indigoMain),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.textStyleCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  value,
                  style: AppTheme.textStyleBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            text,
            style: AppTheme.textStyleBodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          decoration: BoxDecoration(
            color: AppTheme.indigoMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.indigoMain, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: AppTheme.textStyleCaption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTheme.textStyleBody.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesShowcase(List<Service> services, dynamic l10n) {
    // Filter services based on search
    final searchQuery = _serviceSearchController.text.toLowerCase();
    final filteredServices = searchQuery.isEmpty
        ? services
        : services.where((service) {
            return service.name.toLowerCase().contains(searchQuery) ||
                (service.description != null &&
                    service.description!.toLowerCase().contains(searchQuery));
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMD,
            AppTheme.spacingLG,
            AppTheme.spacingMD,
            AppTheme.spacingMD,
          ),
          child: Row(
            children: [
              Text(
                l10n.services,
                style: AppTheme.textStyleH2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_selectedServices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoMain,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedServices.length} ${_selectedServices.length == 1 ? 'seleccionado' : 'seleccionados'}',
                    style: AppTheme.textStyleBodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _serviceSearchController,
            builder: (context, value, child) {
              return TextField(
                controller: _serviceSearchController,
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _serviceSearchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.backgroundMain,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.indigoMain,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        // Modern list without cards
        if (filteredServices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            child: Center(
              child: Text(
                'No se encontraron servicios',
                style: AppTheme.textStyleBody.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          )
        else
          ...filteredServices.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            final isSelected = _selectedServices.any((s) => s.id == service.id);
            return _buildModernServiceItem(
              service,
              isSelected,
              l10n,
              index == filteredServices.length - 1,
            );
          }),
        const SizedBox(height: AppTheme.spacingLG),
      ],
    );
  }

  Widget _buildModernServiceItem(
    Service service,
    bool isSelected,
    dynamic l10n,
    bool isLast,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedServices.removeWhere((s) => s.id == service.id);
          } else {
            _selectedServices.add(service);
          }
          if (_selectedServices.isEmpty) {
            _selectedTimeSlot = null;
            _selectedEmployeeId = null;
            _selectedDate = null;
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(
          left: AppTheme.spacingMD,
          right: AppTheme.spacingMD,
          bottom: isLast ? 0 : AppTheme.spacingMD,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMD,
          horizontal: AppTheme.spacingMD,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isSelected ? AppTheme.indigoMain : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.indigoMain : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.indigoMain
                      : AppTheme.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // Service info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.durationMinutes} ${l10n.minutes}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${service.price.toStringAsFixed(2)}',
                  style: AppTheme.textStyleH3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.indigoMain,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListItem(Service service, bool isSelected, dynamic l10n) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedServices.removeWhere((s) => s.id == service.id);
          } else {
            _selectedServices.add(service);
          }
          if (_selectedServices.isEmpty) {
            _selectedTimeSlot = null;
            _selectedEmployeeId = null;
            _selectedDate = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.indigoMain
                : AppTheme.borderLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.indigoMain : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.indigoMain
                      : AppTheme.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      service.description!,
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${service.durationMinutes} ${l10n.minutes}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${service.price.toStringAsFixed(2)}',
                  style: AppTheme.textStyleH3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.indigoMain,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBookingSection(
    List<Service> services,
    Business business,
    dynamic l10n,
  ) {
    if (_selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(l10n),
          const SizedBox(height: AppTheme.spacingLG),
          // Booking Flow
          _buildBookingFlow(services, business, l10n),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(dynamic l10n) {
    final currentStep = _getCurrentStep();
    final steps = [
      {'label': 'Servicios', 'completed': _selectedServices.isNotEmpty},
      {'label': 'Fecha', 'completed': _selectedDate != null},
      {'label': 'Hora', 'completed': _selectedTimeSlot != null},
      {'label': 'Información', 'completed': _customer != null},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isActive = index == currentStep;
        final isCompleted = step['completed'] as bool;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              // Step Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.indigoMain
                      : isActive
                      ? AppTheme.indigoMain.withOpacity(0.2)
                      : AppTheme.borderLight,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? AppTheme.indigoMain
                        : AppTheme.borderLight,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: AppTheme.textStyleBodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppTheme.indigoMain
                                : AppTheme.textSecondary,
                          ),
                        ),
                ),
              ),
              // Connector Line
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.indigoMain
                          : AppTheme.borderLight,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  int _getCurrentStep() {
    if (_customer != null) return 3;
    if (_selectedTimeSlot != null) return 2;
    if (_selectedDate != null) return 1;
    if (_selectedServices.isNotEmpty) return 0;
    return 0;
  }

  Widget _buildFloatingBookingButton(
    dynamic l10n,
    CustomerAppointmentState appointmentState,
    Business business,
  ) {
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigoMain.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (appointmentState.isLoading || _isBookingInProgress)
            ? null
            : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.indigoMain,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingMD + AppTheme.spacingSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: (appointmentState.isLoading || _isBookingInProgress)
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.bookAppointment,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabSelector(dynamic l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingMD,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.info_outline_rounded,
              label: 'Sobre Nosotros',
              isSelected: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              icon: Icons.calendar_today_rounded,
              label: l10n.bookAppointment,
              isSelected: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMD,
          horizontal: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.indigoMain, AppTheme.indigoDark],
                )
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: AppTheme.textStyleBodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoTab(
    Business business,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingMD),
          _buildBusinessInfoCard(business, l10n),
          const SizedBox(height: AppTheme.spacingMD),
          _buildWorkingHoursCard(schedules, l10n),
          const SizedBox(height: AppTheme.spacingXL),
        ],
      ),
    );
  }

  Widget _buildBookingTab(
    List<Service> services,
    Business business,
    dynamic l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: _buildBookingFlow(services, business, l10n),
    );
  }

  Widget _buildBusinessHero(Business business, dynamic l10n) {
    return Stack(
      children: [
        // Animated Gradient Background
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1), // Indigo
                const Color(0xFF8B5CF6), // Purple
                const Color(0xFFEC4899), // Pink
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Container(
          width: double.infinity,
          height: 320,
          padding: const EdgeInsets.only(
            top: AppTheme.spacingXL,
            bottom: AppTheme.spacingXL + AppTheme.spacingLG,
            left: AppTheme.spacingMD,
            right: AppTheme.spacingMD,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Business Logo with Glow Effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        business.logoUrl != null && business.logoUrl!.isNotEmpty
                        ? business.logoUrl!.startsWith('http')
                              ? Image.network(
                                  business.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultLogo(),
                                )
                              : _buildDefaultLogo()
                        : _buildDefaultLogo(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG + AppTheme.spacingMD),

              // Business Name with Gradient Text Effect
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: Text(
                  business.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Business Description
              if (business.description != null &&
                  business.description!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                  ),
                  child: Text(
                    business.description!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      color: AppTheme.indigoMain.withOpacity(0.2),
      child: const Icon(Icons.business, size: 60, color: Colors.white),
    );
  }

  Widget _buildBusinessInfoCard(Business business, dynamic l10n) {
    return Transform.translate(
      offset: const Offset(0, -AppTheme.spacingLG),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG + AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.indigoMain.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.indigoMain.withOpacity(0.15),
                        AppTheme.indigoDark.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.contact_phone,
                    size: 24,
                    color: AppTheme.indigoMain,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Text(
                  l10n.contactInformation,
                  style: AppTheme.textStyleH3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // Phone
            if (business.phone != null && business.phone!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.phone_rounded,
                label: l10n.phone,
                value: business.phone!,
              ),

            // Address
            if (business.address != null && business.address!.isNotEmpty) ...[
              if (business.phone != null && business.phone!.isNotEmpty)
                const SizedBox(height: AppTheme.spacingLG),
              _buildInfoRow(
                icon: Icons.location_on_rounded,
                label: l10n.address,
                value: business.address!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMain,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.indigoMain.withOpacity(0.15),
                  AppTheme.indigoDark.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigoMain.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 24, color: AppTheme.indigoMain),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.textStyleCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  value,
                  style: AppTheme.textStyleBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursCard(List<Schedule> schedules, dynamic l10n) {
    final days = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG + AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.indigoMain.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.indigoMain.withOpacity(0.15),
                      AppTheme.indigoDark.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  size: 24,
                  color: AppTheme.indigoMain,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Text(
                l10n.workingHours,
                style: AppTheme.textStyleH3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          ...List.generate(7, (index) {
            final dayOfWeek = (index + 1) % 7; // Monday=1, Sunday=0
            final schedule = schedules.firstWhere(
              (s) => s.dayOfWeek == dayOfWeek,
              orElse: () =>
                  Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
            );

            final isToday = DateTime.now().weekday == (index + 1);
            final isClosed =
                schedule.isClosed ||
                schedule.startTime == null ||
                schedule.endTime == null;

            return Container(
              margin: EdgeInsets.only(
                bottom: index < 6 ? AppTheme.spacingMD : 0,
              ),
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.indigoMain.withOpacity(0.08)
                    : AppTheme.backgroundMain,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isToday
                      ? AppTheme.indigoMain.withOpacity(0.3)
                      : AppTheme.borderLight.withOpacity(0.5),
                  width: isToday ? 2 : 1,
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppTheme.indigoMain.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isClosed
                              ? AppTheme.textSecondary
                              : AppTheme.indigoMain,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Text(
                        days[index],
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isToday
                              ? AppTheme.indigoMain
                              : AppTheme.textPrimary,
                          fontSize: isToday ? 16 : 15,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: AppTheme.spacingSM),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSM,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.indigoMain,
                                AppTheme.indigoDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.indigoMain.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Today',
                            style: AppTheme.textStyleCaption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: isClosed
                          ? AppTheme.textSecondary.withOpacity(0.1)
                          : AppTheme.indigoMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      isClosed
                          ? l10n.closed
                          : '${schedule.startTime} - ${schedule.endTime}',
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: isClosed
                            ? AppTheme.textSecondary
                            : AppTheme.indigoMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookingFlow(
    List<Service> services,
    Business business,
    dynamic l10n,
  ) {
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );
    final depositInfo = _calculateDepositInfo(totalAmount, business);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Service Selection - Button to open modal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(l10n.selectService, style: AppTheme.textStyleH2),
            ),
            if (_selectedServices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSM,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.indigoMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '${_selectedServices.length} ${l10n.serviceSelected(_selectedServices.length)}',
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.indigoMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMD),
        // Service Selection Button
        InkWell(
          onTap: () => _showServiceSelectionModal(context, services, l10n),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedServices.isEmpty
                            ? l10n.selectService
                            : '${_selectedServices.length} ${l10n.serviceSelected(_selectedServices.length)}',
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _selectedServices.isEmpty
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (_selectedServices.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          _selectedServices.map((s) => s.name).join(', '),
                          style: AppTheme.textStyleBodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),

        // Selected Services Summary & Totals
        if (_selectedServices.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMD),
          _buildStepCard(
            title: l10n.selectService,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._selectedServices.map((service) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          _selectedServices.indexOf(service) <
                              _selectedServices.length - 1
                          ? AppTheme.spacingMD
                          : 0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: AppTheme.textStyleBody.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: AppTheme.spacingXS),
                                  Text(
                                    '${service.durationMinutes} ${l10n.minutes}',
                                    style: AppTheme.textStyleBodySmall.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${service.price.toStringAsFixed(2)}',
                          style: AppTheme.textStyleBody.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_selectedServices.length > 1) ...[
                  const Divider(height: AppTheme.spacingLG),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.total,
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: AppTheme.textStyleH3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.indigoMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            'Duración total',
                            style: AppTheme.textStyleBodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDuration(
                          _selectedServices.fold<int>(
                            0,
                            (sum, s) => sum + s.durationMinutes,
                          ),
                          l10n,
                        ),
                        style: AppTheme.textStyleBodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (business.requiresDeposit && depositInfo.amount > 0) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.info,
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.depositRequired,
                                style: AppTheme.textStyleBodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.info,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                business.depositType == DepositType.fixed
                                    ? '${l10n.deposits}: \$${depositInfo.amount.toStringAsFixed(2)}'
                                    : '${l10n.deposits}: ${depositInfo.percentage.toStringAsFixed(0)}% (\$${depositInfo.amount.toStringAsFixed(2)})',
                                style: AppTheme.textStyleCaption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingSM),
              ],
            ),
            isCompleted: true,
          ),
        ],

        // Date Selection
        if (_selectedServices.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingMD),
          _selectedDate == null
              ? _buildDateSelector(l10n)
              : _buildStepCard(
                  title: l10n.selectDate,
                  content: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM d').format(_selectedDate!),
                          style: AppTheme.textStyleBody,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDate(),
                        child: Text(l10n.edit),
                      ),
                    ],
                  ),
                  isCompleted: true,
                ),
        ],

        // Time Selection
        if (_selectedDate != null) ...[
          const SizedBox(height: AppTheme.spacingMD),
          _buildTimeSection(l10n),
        ],

        // Customer Info
        if (_selectedTimeSlot != null) ...[
          const SizedBox(height: AppTheme.spacingMD),
          _buildStepCard(
            title: 'Tu información',
            content: Column(
              children: [
                if (_customer != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customer!.name,
                              style: AppTheme.textStyleBody.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              _customer!.phone,
                              style: AppTheme.textStyleBodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCustomerInfoForm(),
                    icon: Icon(
                      _customer == null ? Icons.add : Icons.edit,
                      size: 18,
                    ),
                    label: Text(
                      _customer == null ? 'Completar datos' : 'Editar datos',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingMD,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            isCompleted: _customer != null,
          ),
        ],

        const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  Widget _buildStepCard({
    required String title,
    required Widget content,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isCompleted ? AppTheme.indigoMain : AppTheme.borderLight,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.indigoMain
                      : AppTheme.borderLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                title,
                style: AppTheme.textStyleBodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          content,
        ],
      ),
    );
  }

  ({double percentage, double amount}) _calculateDepositInfo(
    double totalAmount,
    Business business,
  ) {
    if (!business.requiresDeposit || business.depositAmount == null) {
      return (percentage: 0, amount: 0);
    }
    if (business.depositType == DepositType.fixed) {
      return (percentage: 0, amount: business.depositAmount!);
    } else if (business.depositType == DepositType.percentage) {
      final depositAmount = (totalAmount * business.depositAmount! / 100);
      return (percentage: business.depositAmount!, amount: depositAmount);
    }
    return (percentage: 0, amount: 0);
  }

  /// Formats duration in minutes to "X horas Y minutos" or just "Y minutos"
  String _formatDuration(int totalMinutes, dynamic l10n) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ${hours == 1 ? 'hora' : 'horas'} $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'hora' : 'horas'}';
    } else {
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }
  }

  void _showServiceSelectionModal(
    BuildContext context,
    List<Service> services,
    dynamic l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceSelectionModal(
        services: services,
        selectedServices: _selectedServices,
        onServicesChanged: (selected) {
          setState(() {
            _selectedServices.clear();
            _selectedServices.addAll(selected);
            if (_selectedServices.isEmpty) {
              _selectedTimeSlot = null;
              _selectedEmployeeId = null;
            } else {
              // Reset employee and time slot when services change
              _selectedTimeSlot = null;
              _selectedEmployeeId = null;
            }
          });
        },
        l10n: l10n,
      ),
    );
  }

  Widget _buildDateSelector(dynamic l10n) {
    final schedulesAsync = ref.watch(schedulesProvider(widget.businessId));
    final exceptionsAsync = ref.watch(exceptionsProvider(widget.businessId));

    return schedulesAsync.when(
      data: (schedules) => exceptionsAsync.when(
        data: (exceptions) =>
            _buildDateSelectorChips(l10n, schedules, exceptions),
        loading: () => _buildStepCard(
          title: l10n.selectDate,
          content: const Center(child: CircularProgressIndicator()),
          isCompleted: false,
        ),
        error: (_, __) => _buildStepCard(
          title: l10n.selectDate,
          content: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _selectDate(),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(l10n.selectDate),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMD,
                ),
              ),
            ),
          ),
          isCompleted: false,
        ),
      ),
      loading: () => _buildStepCard(
        title: l10n.selectDate,
        content: const Center(child: CircularProgressIndicator()),
        isCompleted: false,
      ),
      error: (_, __) => _buildStepCard(
        title: l10n.selectDate,
        content: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(l10n.selectDate),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
            ),
          ),
        ),
        isCompleted: false,
      ),
    );
  }

  Widget _buildDateSelectorChips(
    dynamic l10n,
    List<Schedule> schedules,
    List<ScheduleException> exceptions,
  ) {
    final now = DateTime.now();
    final minBookingTime = now.add(const Duration(minutes: 30));
    final firstDate = DateTime(now.year, now.month, now.day);
    final canBookToday =
        minBookingTime.day == now.day &&
        minBookingTime.month == now.month &&
        minBookingTime.year == now.year;
    final actualFirstDate = canBookToday
        ? firstDate
        : firstDate.add(const Duration(days: 1));
    final exceptionDates = exceptions.map((e) => e.date).toSet();

    // Generate next 14 available dates
    List<DateTime> availableDates = [];
    DateTime currentDate = actualFirstDate;
    int attempts = 0;

    while (availableDates.length < 14 && attempts < 60) {
      if (_isDateAvailable(currentDate, schedules, exceptionDates, now)) {
        availableDates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
      attempts++;
    }

    if (availableDates.isEmpty) {
      return _buildStepCard(
        title: l10n.selectDate,
        content: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Text(
            'No hay fechas disponibles en los próximos días',
            style: AppTheme.textStyleBodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        isCompleted: false,
      );
    }

    return _buildStepCard(
      title: l10n.selectDate,
      content: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: availableDates.length,
          itemBuilder: (context, index) {
            final date = availableDates[index];
            final isSelected =
                _selectedDate != null && isSameDay(_selectedDate!, date);
            final isToday = isSameDay(date, now);

            return Padding(
              padding: EdgeInsets.only(
                right: index < availableDates.length - 1
                    ? AppTheme.spacingSM
                    : 0,
              ),
              child: _buildDateChip(date, isSelected, isToday, l10n),
            );
          },
        ),
      ),
      isCompleted: _selectedDate != null,
    );
  }

  Widget _buildDateChip(
    DateTime date,
    bool isSelected,
    bool isToday,
    dynamic l10n,
  ) {
    final dayName = DateFormat('EEE', 'es').format(date);
    final dayNumber = date.day;
    final monthName = DateFormat('MMM', 'es').format(date);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
          _selectedEmployeeId = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain
              : isToday
              ? AppTheme.indigoMain.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.indigoMain
                : isToday
                ? AppTheme.indigoMain.withOpacity(0.3)
                : AppTheme.borderLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName.toUpperCase(),
              style: AppTheme.textStyleCaption.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNumber',
              style: AppTheme.textStyleH3.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 24,
              ),
            ),
            Text(
              monthName,
              style: AppTheme.textStyleCaption.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDateAvailable(
    DateTime date,
    List<Schedule> schedules,
    Set<String> exceptionDates,
    DateTime now,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (dateOnly.isBefore(todayOnly)) {
      return false;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (exceptionDates.contains(dateStr)) {
      return false;
    }
    final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
    final daySchedule = schedules.firstWhere(
      (s) => s.dayOfWeek == dayOfWeek,
      orElse: () => Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
    );
    if (daySchedule.isClosed ||
        daySchedule.startTime == null ||
        daySchedule.endTime == null) {
      return false;
    }
    return true;
  }

  Widget _buildTimeSection(dynamic l10n) {
    if (_selectedServices.isEmpty || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    // Calculate total duration of all selected services
    final totalDurationMinutes = _selectedServices.fold<int>(
      0,
      (sum, service) => sum + service.durationMinutes,
    );

    print(
      '[BookingScreen] Selected ${_selectedServices.length} services: ${_selectedServices.map((s) => '${s.name} (${s.durationMinutes} min)').join(', ')}',
    );
    print(
      '[BookingScreen] Total duration: $totalDurationMinutes minutes (${totalDurationMinutes / 60} hours)',
    );

    // Use the first selected service for employee filtering
    final firstService = _selectedServices.first;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final params = AvailableTimeSlotsParams(
      businessId: widget.businessId,
      date: dateStr,
      serviceId: firstService.id,
      totalDurationMinutes: totalDurationMinutes,
    );

    print(
      '[BookingScreen] Created params with totalDurationMinutes: ${params.totalDurationMinutes}',
    );

    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider(params));

    if (_selectedTimeSlot != null) {
      // Get unique employees from all available slots to check if we should show employee name
      return timeSlotsAsync.when(
        data: (allSlots) {
          final uniqueEmployeeIds = allSlots.map((s) => s.employeeId).toSet();
          final shouldShowEmployeeName = uniqueEmployeeIds.length > 1;

          // Recalculate endTime based on current total duration
          // Parse the start time
          final startParts = _selectedTimeSlot!.startTime.split(':');
          final startHour = int.parse(startParts[0]);
          final startMinute = int.parse(startParts[1]);
          final startMinutes = startHour * 60 + startMinute;

          // Calculate new end time based on total duration
          final endMinutes = startMinutes + totalDurationMinutes;
          final endHour = endMinutes ~/ 60;
          final endMin = endMinutes % 60;
          final calculatedEndTime =
              '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';

          return _buildStepCard(
            title: l10n.selectTime,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedTimeSlot!.startTime} - $calculatedEndTime',
                            style: AppTheme.textStyleBody,
                          ),
                          if (shouldShowEmployeeName) ...[
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              _selectedTimeSlot!.employeeName,
                              style: AppTheme.textStyleBodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          if (_selectedServices.length > 1) ...[
                            const SizedBox(height: AppTheme.spacingXS),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.spacingXS),
                                Text(
                                  _formatDuration(totalDurationMinutes, l10n),
                                  style: AppTheme.textStyleBodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTimeSlot = null;
                          _selectedEmployeeId = null;
                        });
                      },
                      child: Text(l10n.edit),
                    ),
                  ],
                ),
              ],
            ),
            isCompleted: true,
          );
        },
        loading: () => _buildStepCard(
          title: l10n.selectTime,
          content: const Padding(
            padding: EdgeInsets.all(AppTheme.spacingMD),
            child: Center(child: CircularProgressIndicator()),
          ),
          isCompleted: false,
        ),
        error: (error, stack) => _buildStepCard(
          title: l10n.selectTime,
          content: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Text(
              l10n.errorLoadingTimeSlots,
              style: AppTheme.textStyleBodySmall.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
          isCompleted: false,
        ),
      );
    }

    return timeSlotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return _buildStepCard(
            title: l10n.selectTime,
            content: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Text(
                l10n.noTimeSlotsAvailable,
                style: AppTheme.textStyleBodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            isCompleted: false,
          );
        }

        // Get unique employees
        final uniqueEmployees =
            <String, String>{}; // employeeId -> employeeName
        for (final slot in slots) {
          uniqueEmployees[slot.employeeId] = slot.employeeName;
        }

        final hasMultipleEmployees = uniqueEmployees.length > 1;

        // Filter slots by selected employee if one is selected
        final filteredSlots = _selectedEmployeeId != null
            ? slots
                  .where((slot) => slot.employeeId == _selectedEmployeeId)
                  .toList()
            : slots;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Employee selection (only if multiple employees)
            if (hasMultipleEmployees) ...[
              _buildStepCard(
                title: l10n.selectEmployee,
                content: Wrap(
                  spacing: AppTheme.spacingSM,
                  runSpacing: AppTheme.spacingSM,
                  children: uniqueEmployees.entries.map((entry) {
                    final employeeId = entry.key;
                    final employeeName = entry.value;
                    final isSelected = _selectedEmployeeId == employeeId;
                    return ChoiceChip(
                      label: Text(employeeName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedEmployeeId = employeeId;
                            _selectedTimeSlot =
                                null; // Reset time slot selection
                          } else {
                            _selectedEmployeeId = null;
                          }
                        });
                      },
                      selectedColor: AppTheme.indigoMain.withOpacity(0.2),
                      checkmarkColor: AppTheme.indigoMain,
                      labelStyle: AppTheme.textStyleBodySmall.copyWith(
                        color: isSelected
                            ? AppTheme.indigoMain
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                isCompleted: _selectedEmployeeId != null,
              ),
              const SizedBox(height: AppTheme.spacingMD),
            ],
            // Time slots
            _buildStepCard(
              title: l10n.selectTime,
              content: filteredSlots.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      child: Text(
                        hasMultipleEmployees && _selectedEmployeeId == null
                            ? l10n.selectEmployee
                            : l10n.noTimeSlotsAvailable,
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Wrap(
                      spacing: AppTheme.spacingSM,
                      runSpacing: AppTheme.spacingSM,
                      children: filteredSlots.take(12).map((slot) {
                        return _TimeSlotButton(
                          slot: slot,
                          showEmployeeName: hasMultipleEmployees,
                          onTap: () {
                            setState(() {
                              _selectedTimeSlot = slot;
                            });
                          },
                        );
                      }).toList(),
                    ),
              isCompleted: false,
            ),
          ],
        );
      },
      loading: () => _buildStepCard(
        title: l10n.selectTime,
        content: const Padding(
          padding: EdgeInsets.all(AppTheme.spacingMD),
          child: Center(child: CircularProgressIndicator()),
        ),
        isCompleted: false,
      ),
      error: (error, stack) => _buildStepCard(
        title: l10n.selectTime,
        content: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Text(
            l10n.errorLoadingTimeSlots,
            style: AppTheme.textStyleBodySmall.copyWith(color: AppTheme.error),
          ),
        ),
        isCompleted: false,
      ),
    );
  }

  Widget _buildBottomButton(
    dynamic l10n,
    CustomerAppointmentState appointmentState,
    Business? business,
  ) {
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );
    final depositInfo = business != null
        ? _calculateDepositInfo(totalAmount, business)
        : (percentage: 0, amount: 0);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.backgroundMain,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.total,
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: AppTheme.textStyleH3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.indigoMain,
                        ),
                      ),
                    ],
                  ),
                  if (business?.requiresDeposit == true &&
                      depositInfo.amount > 0) ...[
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              l10n.depositRequired,
                              style: AppTheme.textStyleBodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${depositInfo.amount.toStringAsFixed(2)}',
                          style: AppTheme.textStyleBody.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (appointmentState.isLoading || _isBookingInProgress)
                    ? null
                    : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.indigoMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  elevation: 0,
                ),
                child: appointmentState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        l10n.bookAppointment,
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minBookingTime = now.add(const Duration(minutes: 30));
    final firstDate = DateTime(now.year, now.month, now.day);
    final canBookToday =
        minBookingTime.day == now.day &&
        minBookingTime.month == now.month &&
        minBookingTime.year == now.year;
    final actualFirstDate = canBookToday
        ? firstDate
        : firstDate.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 60));

    final schedulesAsync = ref.read(
      schedulesProvider(widget.businessId).future,
    );
    final exceptionsAsync = ref.read(
      exceptionsProvider(widget.businessId).future,
    );
    final schedules = await schedulesAsync;
    final exceptions = await exceptionsAsync;
    final exceptionDates = exceptions.map((e) => e.date).toSet();

    // Helper function to check if a date is selectable
    bool isDateSelectable(DateTime date) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      if (dateOnly.isBefore(todayOnly)) {
        return false;
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (exceptionDates.contains(dateStr)) {
        return false;
      }
      final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
      final daySchedule = schedules.firstWhere(
        (s) => s.dayOfWeek == dayOfWeek,
        orElse: () => Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
      );
      if (daySchedule.isClosed ||
          daySchedule.startTime == null ||
          daySchedule.endTime == null) {
        return false;
      }
      return true;
    }

    // Find the first selectable date starting from actualFirstDate or _selectedDate
    DateTime findFirstSelectableDate(DateTime startDate) {
      DateTime currentDate = startDate;
      int attempts = 0;
      while (attempts < 365 &&
          (currentDate.isBefore(lastDate) ||
              currentDate.isAtSameMomentAs(lastDate))) {
        if (isDateSelectable(currentDate)) {
          return currentDate;
        }
        currentDate = currentDate.add(const Duration(days: 1));
        attempts++;
      }
      return startDate; // Fallback to start date if no selectable date found
    }

    // Ensure initialDate is selectable
    DateTime initialDateToUse = actualFirstDate;
    if (_selectedDate != null && !_selectedDate!.isBefore(actualFirstDate)) {
      if ((_selectedDate!.isBefore(lastDate) ||
              _selectedDate!.isAtSameMomentAs(lastDate)) &&
          isDateSelectable(_selectedDate!)) {
        initialDateToUse = _selectedDate!;
      } else {
        initialDateToUse = findFirstSelectableDate(_selectedDate!);
      }
    } else {
      initialDateToUse = findFirstSelectableDate(actualFirstDate);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDateToUse,
      firstDate: actualFirstDate,
      lastDate: lastDate,
      selectableDayPredicate: isDateSelectable,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        _selectedEmployeeId =
            null; // Reset employee selection when date changes
      });
    }
  }

  Future<void> _showCustomerInfoForm() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerInformationForm(initialCustomer: _customer),
    );
    if (customer != null) {
      setState(() {
        _customer = customer;
      });
    }
  }

  /// Converts technical error messages to user-friendly messages in Spanish
  String _getUserFriendlyError(String errorMessage) {
    final l10n = context.l10n;
    final errorLower = errorMessage.toLowerCase();

    if (errorLower.contains('customer already has an appointment') ||
        errorLower.contains('already has an appointment at this time')) {
      return l10n.errorAppointmentConflict;
    }

    if (errorLower.contains('no employee available') ||
        errorLower.contains('employee available')) {
      return l10n.errorNoEmployeeAvailable;
    }

    if (errorLower.contains('no longer available') ||
        errorLower.contains('slot') && errorLower.contains('available')) {
      return l10n.errorSlotNoLongerAvailable;
    }

    // Default to generic error message
    return l10n.errorGenericBooking;
  }

  Future<void> _bookAppointment() async {
    final l10n = context.l10n;
    if (_selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTimeSlot == null ||
        _customer == null) {
      return;
    }

    final apiService = ref.read(apiServiceProvider);
    String customerId = _customer!.id;
    if (customerId.isEmpty) {
      try {
        final createdCustomer = await apiService.createCustomer(_customer!);
        customerId = createdCustomer.id;
      } catch (e) {
        setState(() {
          _isBookingInProgress = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorCreatingCustomer}: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
    }

    // Create appointment for each selected service
    int successCount = 0;
    int errorCount = 0;
    String? lastError;

    for (final service in _selectedServices) {
      // Find an employee who can perform this service
      final employeesAsync = await ref.read(
        employeesProvider(widget.businessId).future,
      );
      final activeEmployees = employeesAsync.where((e) => e.active).toList();

      // Try to find employee who can do this service, otherwise use the time slot's employee
      final availableEmployee = activeEmployees.firstWhere(
        (e) => e.serviceIds.contains(service.id),
        orElse: () => activeEmployees.firstWhere(
          (e) => e.id == _selectedTimeSlot!.employeeId,
          orElse: () => activeEmployees.isNotEmpty
              ? activeEmployees.first
              : Employee(id: '', name: '', active: false, serviceIds: []),
        ),
      );

      if (availableEmployee.id.isEmpty) {
        errorCount++;
        lastError = l10n.errorNoEmployeeAvailable;
        continue;
      }

      // Calculate start time for each service
      // For now, we'll use the same time slot for all services
      // In a real app, you'd want to calculate sequential times
      final appointmentData = {
        'businessId': widget.businessId,
        'employeeId': availableEmployee.id,
        'customerId': customerId,
        'serviceId': service.id,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'startTime': _selectedTimeSlot!.startTime,
      };

      try {
        await ref
            .read(customerAppointmentNotifierProvider.notifier)
            .createCustomerAppointment(appointmentData);
        successCount++;
      } catch (e) {
        errorCount++;
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        lastError = _getUserFriendlyError(errorMessage);
      }
    }

    if (mounted) {
      if (errorCount == 0) {
        setState(() {
          _isBookingInProgress = false;
          _selectedServices.clear();
          _selectedDate = null; // Don't auto-select date
          _selectedTimeSlot = null;
          _customer = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 1
                  ? '$successCount ${context.l10n.appointments} booked successfully'
                  : context.l10n.appointmentBookedSuccessfully,
            ),
            backgroundColor: AppTheme.success,
          ),
        );

        ref.read(customerAppointmentNotifierProvider.notifier).reset();
      } else {
        setState(() {
          _isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? l10n.errorBookingSomeAppointments(successCount)
                  : '${l10n.errorBookingAppointments}: $lastError',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } else {
      // Reset flag if widget is unmounted
      _isBookingInProgress = false;
    }
  }
}

class _TimeSlotButton extends StatelessWidget {
  final TimeSlot slot;
  final bool showEmployeeName;
  final VoidCallback onTap;

  const _TimeSlotButton({
    required this.slot,
    required this.showEmployeeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slot.startTime,
            style: AppTheme.textStyleBodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showEmployeeName) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              slot.employeeName,
              style: AppTheme.textStyleCaption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceSelectionModal extends StatefulWidget {
  final List<Service> services;
  final List<Service> selectedServices;
  final Function(List<Service>) onServicesChanged;
  final dynamic l10n;

  const _ServiceSelectionModal({
    required this.services,
    required this.selectedServices,
    required this.onServicesChanged,
    required this.l10n,
  });

  @override
  State<_ServiceSelectionModal> createState() => _ServiceSelectionModalState();
}

class _ServiceSelectionModalState extends State<_ServiceSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Service> _filteredServices = [];
  List<Service> _tempSelectedServices = [];

  @override
  void initState() {
    super.initState();
    _filteredServices = widget.services;
    _tempSelectedServices = List.from(widget.selectedServices);
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterServices);
    _searchController.dispose();
    super.dispose();
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredServices = widget.services;
      } else {
        _filteredServices = widget.services.where((service) {
          return service.name.toLowerCase().contains(query) ||
              (service.description != null &&
                  service.description!.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  void _toggleService(Service service) {
    setState(() {
      if (_tempSelectedServices.any((s) => s.id == service.id)) {
        _tempSelectedServices.removeWhere((s) => s.id == service.id);
      } else {
        _tempSelectedServices.add(service);
      }
    });
  }

  void _confirmSelection() {
    widget.onServicesChanged(_tempSelectedServices);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingSM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.l10n.selectService, style: AppTheme.textStyleH2),
                if (_tempSelectedServices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.indigoMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      '${_tempSelectedServices.length} ${widget.l10n.serviceSelected(_tempSelectedServices.length)}',
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.indigoMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.l10n.searchByServiceName,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide(
                        color: AppTheme.indigoMain,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          // Services list
          Expanded(
            child: _filteredServices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Text(
                          widget.l10n.noServicesAvailable,
                          style: AppTheme.textStyleBody.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                    ),
                    itemCount: _filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = _filteredServices[index];
                      final isSelected = _tempSelectedServices.any(
                        (s) => s.id == service.id,
                      );
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _filteredServices.length - 1
                              ? AppTheme.spacingMD
                              : 0,
                        ),
                        child: _buildServiceCard(
                          service: service,
                          isSelected: isSelected,
                          onTap: () => _toggleService(service),
                        ),
                      );
                    },
                  ),
          ),
          // Footer with confirm button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigoMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.l10n.save,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required Service service,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.indigoMain.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.indigoMain : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? AppTheme.indigoMain : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.indigoMain
                      : AppTheme.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      service.description!,
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${service.durationMinutes} ${widget.l10n.minutes}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: AppTheme.textStyleBodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingModal extends ConsumerStatefulWidget {
  final String businessId;
  final Business business;
  final dynamic l10n;

  const _BookingModal({
    required this.businessId,
    required this.business,
    required this.l10n,
  });

  @override
  ConsumerState<_BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends ConsumerState<_BookingModal> {
  final List<Service> _selectedServices = [];
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  Customer? _customer;
  String? _selectedEmployeeId;
  bool _isBookingInProgress = false; // Prevent duplicate booking requests

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(publicServicesProvider(widget.businessId));
    final schedulesAsync = ref.watch(schedulesProvider(widget.businessId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingSM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.l10n.bookAppointment,
                  style: AppTheme.textStyleH2.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: servicesAsync.when(
              data: (services) => schedulesAsync.when(
                data: (schedules) {
                  if (services.isEmpty) {
                    return Center(
                      child: Text(
                        widget.l10n.noServicesAvailable,
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                    ),
                    child: Column(
                      children: [
                        _buildBookingWizard(services, schedules, widget.l10n),
                        const SizedBox(height: AppTheme.spacingXL),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading schedule',
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  widget.l10n.errorLoadingServices,
                  style: AppTheme.textStyleBody.copyWith(color: AppTheme.error),
                ),
              ),
            ),
          ),
          // Bottom Button
          if (_selectedServices.isNotEmpty &&
              _selectedDate != null &&
              _selectedTimeSlot != null &&
              _customer != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Consumer(
                  builder: (context, ref, child) {
                    final appointmentState = ref.watch(
                      customerAppointmentNotifierProvider,
                    );
                    return _buildBookingButton(
                      widget.l10n,
                      appointmentState,
                      widget.business,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingWizard(
    List<Service> services,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Service Selection
        _buildServiceSelectionSection(services, l10n),
        const SizedBox(height: AppTheme.spacingMD),

        // Date Selection
        if (_selectedServices.isNotEmpty) ...[
          _buildDateSelectionSection(l10n),
          const SizedBox(height: AppTheme.spacingMD),
        ],

        // Time Selection
        if (_selectedDate != null) ...[
          _buildTimeSelectionSection(services, schedules, l10n),
          const SizedBox(height: AppTheme.spacingMD),
        ],

        // Customer Info
        if (_selectedTimeSlot != null) ...[_buildCustomerInfoSection(l10n)],
      ],
    );
  }

  Widget _buildServiceSelectionSection(List<Service> services, dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectService,
            style: AppTheme.textStyleH3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          ...services.map((service) {
            final isSelected = _selectedServices.any((s) => s.id == service.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.removeWhere((s) => s.id == service.id);
                    } else {
                      _selectedServices.add(service);
                    }
                    if (_selectedServices.isEmpty) {
                      _selectedTimeSlot = null;
                      _selectedEmployeeId = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.indigoMain.withOpacity(0.1)
                        : AppTheme.backgroundMain,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.indigoMain
                          : AppTheme.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.indigoMain
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.indigoMain
                                : AppTheme.borderLight,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: AppTheme.textStyleBody.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.indigoMain
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (service.description != null &&
                                service.description!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingXS),
                              Text(
                                service.description!,
                                style: AppTheme.textStyleBodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Text(
                        '\$${service.price.toStringAsFixed(2)}',
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.indigoMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateSelectionSection(dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectDate,
            style: AppTheme.textStyleH3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          InkWell(
            onTap: () => _selectDate(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.backgroundMain,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.indigoMain,
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('EEEE, MMMM d').format(_selectedDate!)
                          : l10n.selectDate,
                      style: AppTheme.textStyleBody,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionSection(
    List<Service> services,
    List<Schedule> schedules,
    dynamic l10n,
  ) {
    if (_selectedServices.isEmpty || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    final totalDurationMinutes = _selectedServices.fold<int>(
      0,
      (sum, service) => sum + service.durationMinutes,
    );

    final firstService = _selectedServices.first;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final params = AvailableTimeSlotsParams(
      businessId: widget.businessId,
      date: dateStr,
      serviceId: firstService.id,
      totalDurationMinutes: totalDurationMinutes,
    );

    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider(params));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectTime,
            style: AppTheme.textStyleH3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          timeSlotsAsync.when(
            data: (slots) {
              if (slots.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    child: Text(
                      l10n.noTimeSlotsAvailable,
                      style: AppTheme.textStyleBodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: AppTheme.spacingSM,
                runSpacing: AppTheme.spacingSM,
                children: slots.take(12).map((slot) {
                  final isSelected =
                      _selectedTimeSlot?.startTime == slot.startTime;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMD,
                        vertical: AppTheme.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.indigoMain
                            : AppTheme.backgroundMain,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.indigoMain
                              : AppTheme.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        slot.startTime,
                        style: AppTheme.textStyleBodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                child: Text(
                  l10n.errorLoadingTimeSlots,
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection(dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu información',
            style: AppTheme.textStyleH3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          if (_customer != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer!.name,
                        style: AppTheme.textStyleBody.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        _customer!.phone,
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomerInfoForm(),
              icon: Icon(_customer == null ? Icons.add : Icons.edit, size: 18),
              label: Text(
                _customer == null ? 'Completar datos' : 'Editar datos',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMD,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final minBookingTime = now.add(const Duration(minutes: 30));
    final firstDate = DateTime(now.year, now.month, now.day);
    final canBookToday =
        minBookingTime.day == now.day &&
        minBookingTime.month == now.month &&
        minBookingTime.year == now.year;
    final actualFirstDate = canBookToday
        ? firstDate
        : firstDate.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 60));

    final schedulesAsync = await ref.read(
      schedulesProvider(widget.businessId).future,
    );
    final exceptionsAsync = await ref.read(
      exceptionsProvider(widget.businessId).future,
    );
    final schedules = schedulesAsync;
    final exceptions = exceptionsAsync;
    final exceptionDates = exceptions.map((e) => e.date).toSet();

    // Helper function to check if a date is selectable
    bool isDateSelectable(DateTime date) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      if (dateOnly.isBefore(todayOnly)) {
        return false;
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (exceptionDates.contains(dateStr)) {
        return false;
      }
      final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
      final daySchedule = schedules.firstWhere(
        (s) => s.dayOfWeek == dayOfWeek,
        orElse: () => Schedule(id: '', dayOfWeek: dayOfWeek, isClosed: true),
      );
      if (daySchedule.isClosed ||
          daySchedule.startTime == null ||
          daySchedule.endTime == null) {
        return false;
      }
      return true;
    }

    // Find the first selectable date starting from actualFirstDate or _selectedDate
    DateTime findFirstSelectableDate(DateTime startDate) {
      DateTime currentDate = startDate;
      int attempts = 0;
      while (attempts < 365 &&
          (currentDate.isBefore(lastDate) ||
              currentDate.isAtSameMomentAs(lastDate))) {
        if (isDateSelectable(currentDate)) {
          return currentDate;
        }
        currentDate = currentDate.add(const Duration(days: 1));
        attempts++;
      }
      return startDate; // Fallback to start date if no selectable date found
    }

    // Ensure initialDate is selectable
    DateTime initialDateToUse = actualFirstDate;
    if (_selectedDate != null && !_selectedDate!.isBefore(actualFirstDate)) {
      if ((_selectedDate!.isBefore(lastDate) ||
              _selectedDate!.isAtSameMomentAs(lastDate)) &&
          isDateSelectable(_selectedDate!)) {
        initialDateToUse = _selectedDate!;
      } else {
        initialDateToUse = findFirstSelectableDate(_selectedDate!);
      }
    } else {
      initialDateToUse = findFirstSelectableDate(actualFirstDate);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDateToUse,
      firstDate: actualFirstDate,
      lastDate: lastDate,
      selectableDayPredicate: isDateSelectable,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        _selectedEmployeeId = null;
      });
    }
  }

  Future<void> _showCustomerInfoForm() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerInformationForm(initialCustomer: _customer),
    );
    if (customer != null) {
      setState(() {
        _customer = customer;
      });
    }
  }

  /// Converts technical error messages to user-friendly messages in Spanish
  String _getUserFriendlyError(String errorMessage) {
    final l10n = context.l10n;
    final errorLower = errorMessage.toLowerCase();

    if (errorLower.contains('customer already has an appointment') ||
        errorLower.contains('already has an appointment at this time')) {
      return l10n.errorAppointmentConflict;
    }

    if (errorLower.contains('no employee available') ||
        errorLower.contains('employee available')) {
      return l10n.errorNoEmployeeAvailable;
    }

    if (errorLower.contains('no longer available') ||
        errorLower.contains('slot') && errorLower.contains('available')) {
      return l10n.errorSlotNoLongerAvailable;
    }

    // Default to generic error message
    return l10n.errorGenericBooking;
  }

  Widget _buildBookingButton(
    dynamic l10n,
    CustomerAppointmentState appointmentState,
    Business business,
  ) {
    final totalAmount = _selectedServices.fold<double>(
      0,
      (sum, service) => sum + service.price,
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (appointmentState.isLoading || _isBookingInProgress)
            ? null
            : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.indigoMain,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: (appointmentState.isLoading || _isBookingInProgress)
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.bookAppointment,
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: AppTheme.textStyleBody.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final l10n = context.l10n;
    if (_selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTimeSlot == null ||
        _customer == null) {
      return;
    }

    final apiService = ref.read(apiServiceProvider);
    String customerId = _customer!.id;
    if (customerId.isEmpty) {
      try {
        final createdCustomer = await apiService.createCustomer(_customer!);
        customerId = createdCustomer.id;
      } catch (e) {
        setState(() {
          _isBookingInProgress = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorCreatingCustomer}: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
    }

    int successCount = 0;
    int errorCount = 0;
    String? lastError;

    for (final service in _selectedServices) {
      final employeesAsync = await ref.read(
        employeesProvider(widget.businessId).future,
      );
      final activeEmployees = employeesAsync.where((e) => e.active).toList();

      final availableEmployee = activeEmployees.firstWhere(
        (e) => e.serviceIds.contains(service.id),
        orElse: () => activeEmployees.firstWhere(
          (e) => e.id == _selectedTimeSlot!.employeeId,
          orElse: () => activeEmployees.isNotEmpty
              ? activeEmployees.first
              : Employee(id: '', name: '', active: false, serviceIds: []),
        ),
      );

      if (availableEmployee.id.isEmpty) {
        errorCount++;
        lastError = l10n.errorNoEmployeeAvailable;
        continue;
      }

      final appointmentData = {
        'businessId': widget.businessId,
        'employeeId': availableEmployee.id,
        'customerId': customerId,
        'serviceId': service.id,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'startTime': _selectedTimeSlot!.startTime,
      };

      try {
        await ref
            .read(customerAppointmentNotifierProvider.notifier)
            .createCustomerAppointment(appointmentData);
        successCount++;
      } catch (e) {
        errorCount++;
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        lastError = _getUserFriendlyError(errorMessage);
      }
    }

    if (mounted) {
      if (errorCount == 0) {
        setState(() {
          _isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 1
                  ? '$successCount ${context.l10n.appointments} booked successfully'
                  : context.l10n.appointmentBookedSuccessfully,
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
        ref.read(customerAppointmentNotifierProvider.notifier).reset();
      } else {
        setState(() {
          _isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? l10n.errorBookingSomeAppointments(successCount)
                  : '${l10n.errorBookingAppointments}: $lastError',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } else {
      // Reset flag if widget is unmounted
      _isBookingInProgress = false;
    }
  }
}
