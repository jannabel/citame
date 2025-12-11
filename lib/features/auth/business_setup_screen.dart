import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/schedule_models.dart';
import '../../core/providers/api_providers.dart';
import 'auth_providers.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  final String accessToken;
  final String? userEmail;
  final String? userPhone;

  const BusinessSetupScreen({
    super.key,
    required this.accessToken,
    this.userEmail,
    this.userPhone,
  });

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Business info controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedTimezone = 'America/Mexico_City';

  // Schedule data
  final Map<int, Map<String, dynamic>> _schedules = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize schedules for all days (Monday = 1, Sunday = 0)
    for (int i = 0; i < 7; i++) {
      final dayOfWeek = (i + 1) % 7;
      _schedules[dayOfWeek] = {
        'isClosed': dayOfWeek == 0, // Sunday closed by default
        'startTime': dayOfWeek == 0 ? null : '09:00',
        'endTime': dayOfWeek == 0 ? null : '18:00',
      };
    }

    // Pre-fill phone if available
    if (widget.userPhone != null) {
      _phoneController.text = widget.userPhone!;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<String> get _timezones => [
    'America/Mexico_City',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Bogota',
    'America/Argentina/Buenos_Aires',
    'America/Santiago',
    'Europe/Madrid',
    'Europe/London',
  ];

  List<String> get _dayNames => [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      // Validate business info step
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      // Validate schedules step and create business
      await _createBusiness();
    }
  }

  Future<void> _createBusiness() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      // Create business
      final businessData = {
        'name': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'timezone': _selectedTimezone,
        'requiresDeposit': false,
      };

      final business = await apiService.createBusiness(businessData);

      // Create schedules
      for (final entry in _schedules.entries) {
        final dayOfWeek = entry.key;
        final scheduleData = entry.value;

        if (scheduleData['isClosed'] == false) {
          final schedule = Schedule(
            id: '',
            dayOfWeek: dayOfWeek,
            isClosed: false,
            startTime: scheduleData['startTime'] as String?,
            endTime: scheduleData['endTime'] as String?,
          );

          await apiService.createSchedule(business.id, schedule);
        }
      }

      // Login with the businessId
      // We need to get the businessId from the business object
      // For now, we'll try to login using email or get businessId from response
      // The backend should return businessId in the signup response
      // If not, we'll need to get it from the created business

      // Refresh auth state with the new businessId
      await ref.read(authStateProvider.notifier).loadSavedAuth();

      // Save businessId to auth state
      // The business was created with the authenticated user's token
      // We need to update the auth state with the businessId
      if (business.id.isNotEmpty) {
        // Save businessId to storage
        final storage = ref.read(secureStorageProvider);
        await storage.saveBusinessId(business.id);

        // Update auth state - we need to reload auth to get the updated state
        await ref.read(authStateProvider.notifier).loadSavedAuth();

        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'No se pudo obtener el ID del negocio. Por favor inicia sesión manualmente.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _formatTime12Hour(String? time24) {
    if (time24 == null) return '--:--';
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showCopyScheduleDialog(int currentDayOfWeek) async {
    // Show dialog to select which days to copy TO
    final currentDayName = _dayNames[_getDayIndex(currentDayOfWeek)];
    final currentSchedule = _schedules[currentDayOfWeek];
    final isClosed = currentSchedule?['isClosed'] as bool? ?? true;
    final startTime = currentSchedule?['startTime'] as String?;
    final endTime = currentSchedule?['endTime'] as String?;

    String currentScheduleText = isClosed
        ? 'Cerrado'
        : '${_formatTime12Hour(startTime)} - ${_formatTime12Hour(endTime)}';

    final selectedDays = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        final selectedDaysSet = <int>{};

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Copiar horario de $currentDayName'),
                Text(
                  currentScheduleText,
                  style: AppTheme.textStyleBodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final dayOfWeek = (index + 1) % 7;
                  final dayName = _dayNames[index];
                  // Don't show current day
                  if (dayOfWeek == currentDayOfWeek)
                    return const SizedBox.shrink();

                  final isSelected = selectedDaysSet.contains(dayOfWeek);

                  return CheckboxListTile(
                    title: Text(dayName),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedDaysSet.add(dayOfWeek);
                        } else {
                          selectedDaysSet.remove(dayOfWeek);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(selectedDaysSet.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.indigoMain,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Copiar'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedDays != null && selectedDays.isNotEmpty) {
      _copyScheduleToDays(currentDayOfWeek, selectedDays);
    }
  }

  void _copyScheduleToDays(int sourceDayOfWeek, List<int> targetDays) {
    // Get the source day's schedule
    final sourceSchedule = _schedules[sourceDayOfWeek];

    if (sourceSchedule != null) {
      // Create a new map with copied values (deep copy)
      final isClosed = sourceSchedule['isClosed'] as bool;
      final startTime = sourceSchedule['startTime'] as String?;
      final endTime = sourceSchedule['endTime'] as String?;

      setState(() {
        for (final targetDay in targetDays) {
          _schedules[targetDay] = {
            'isClosed': isClosed,
            'startTime': startTime,
            'endTime': endTime,
          };
        }
      });

      // Show feedback
      if (mounted) {
        final sourceDayName = _dayNames[_getDayIndex(sourceDayOfWeek)];
        final targetDaysNames = targetDays
            .map((d) => _dayNames[_getDayIndex(d)])
            .join(', ');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Horario de $sourceDayName copiado a $targetDaysNames',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.indigoMain,
          ),
        );
      }
    }
  }

  int _getDayIndex(int dayOfWeek) {
    // Convert dayOfWeek to index in _dayNames array
    // dayOfWeek: Monday=1, Tuesday=2, ..., Sunday=0
    // _dayNames index: Monday=0, Tuesday=1, ..., Sunday=6
    return dayOfWeek == 0 ? 6 : dayOfWeek - 1;
  }

  Future<void> _selectTimeForDay(int dayOfWeek, bool isStart) async {
    final schedule = _schedules[dayOfWeek]!;
    final currentTime = isStart
        ? schedule['startTime'] as String?
        : schedule['endTime'] as String?;

    TimeOfDay? initialTime;
    if (currentTime != null) {
      final parts = currentTime.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      initialTime = const TimeOfDay(hour: 9, minute: 0);
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        // Get MediaQuery and force 12-hour format
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          // Force 12-hour format (AM/PM)
          data: mediaQueryData.copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: AppTheme.indigoMain),
            ),
            child: child!,
          ),
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        final timeString =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _schedules[dayOfWeek]!['startTime'] = timeString;
        } else {
          _schedules[dayOfWeek]!['endTime'] = timeString;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Row(
                children: List.generate(2, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < 1 ? AppTheme.spacingSM : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? AppTheme.indigoMain
                            : AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        _currentStep == 0
                            ? 'Información del Negocio'
                            : 'Horarios de Trabajo',
                        style: AppTheme.textStyleH1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Text(
                        _currentStep == 0
                            ? 'Completa la información básica de tu negocio'
                            : 'Configura los horarios de atención',
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingXXL),
                      // Error message
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.error),
                          ),
                          child: Text(
                            _error!,
                            style: AppTheme.textStyleBodySmall.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                      ],
                      // Step content
                      if (_currentStep == 0) ...[
                        _buildBusinessInfoStep(),
                      ] else ...[
                        _buildScheduleStep(),
                      ],
                      const SizedBox(height: AppTheme.spacingXL),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom buttons
            Container(
              padding: EdgeInsets.only(
                left: AppTheme.spacingLG,
                right: AppTheme.spacingLG,
                top: AppTheme.spacingMD,
                bottom:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacingMD,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _currentStep--;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMD + 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Atrás'),
                        ),
                      ),
                    if (_currentStep > 0)
                      const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      flex: _currentStep > 0 ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.indigoMain,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMD + 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _currentStep == 0 ? 'Continuar' : 'Finalizar',
                                style: AppTheme.textStyleBody.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Negocio *',
              prefixIcon: Icon(
                Icons.store_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa el nombre del negocio';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingMD),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa tu teléfono';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingMD),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.next,
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              prefixIcon: Icon(
                Icons.description_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.next,
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          DropdownButtonFormField<String>(
            initialValue: _selectedTimezone,
            decoration: const InputDecoration(
              labelText: 'Zona Horaria *',
              prefixIcon: Icon(
                Icons.access_time,
                color: AppTheme.textSecondary,
              ),
            ),
            items: _timezones.map((timezone) {
              return DropdownMenuItem(value: timezone, child: Text(timezone));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTimezone = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona una zona horaria';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return AppTheme.card(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configura los horarios de atención para cada día de la semana',
            style: AppTheme.textStyleBody.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),
          ...List.generate(7, (index) {
            final dayOfWeek = (index + 1) % 7; // Monday = 1, Sunday = 0
            final dayName = _dayNames[index];
            final schedule = _schedules[dayOfWeek]!;
            final isClosed = schedule['isClosed'] as bool;
            final startTime = schedule['startTime'] as String?;
            final endTime = schedule['endTime'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundMain,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dayName,
                            style: AppTheme.textStyleBody.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showCopyScheduleDialog(dayOfWeek),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.copy,
                                size: 20,
                                color: AppTheme.indigoMain,
                              ),
                            ),
                          ),
                        ),
                        Switch(
                          value: !isClosed,
                          onChanged: (value) {
                            setState(() {
                              _schedules[dayOfWeek]!['isClosed'] = !value;
                            });
                          },
                          activeThumbColor: AppTheme.indigoMain,
                        ),
                        Text(
                          isClosed ? 'Cerrado' : 'Abierto',
                          style: AppTheme.textStyleBodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (!isClosed) ...[
                      const SizedBox(height: AppTheme.spacingMD),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTimeForDay(dayOfWeek, true),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppTheme.spacingMD,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Inicio',
                                      style: AppTheme.textStyleBodySmall
                                          .copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                    Text(
                                      _formatTime12Hour(startTime ?? '09:00'),
                                      style: AppTheme.textStyleBody.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTimeForDay(dayOfWeek, false),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppTheme.spacingMD,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fin',
                                      style: AppTheme.textStyleBodySmall
                                          .copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                    Text(
                                      _formatTime12Hour(endTime ?? '18:00'),
                                      style: AppTheme.textStyleBody.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
