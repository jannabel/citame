// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CitApp - Gestión de Citas';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get welcomeBack => 'Bienvenido de Nuevo';

  @override
  String get signInToManage => 'Inicia sesión para gestionar tus citas';

  @override
  String get businessId => 'ID del Negocio';

  @override
  String get password => 'Contraseña';

  @override
  String get pleaseEnterBusinessId => 'Por favor ingresa tu ID del negocio';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get dashboard => 'Inicio';

  @override
  String get appointments => 'Citas';

  @override
  String get services => 'Servicios';

  @override
  String get employees => 'Empleados';

  @override
  String get settings => 'Configuración';

  @override
  String get businessSettings => 'Configuración del Negocio';

  @override
  String get summary => 'Resumen';

  @override
  String get pending => 'Pendiente';

  @override
  String get confirmed => 'Confirmada';

  @override
  String get completed => 'Completada';

  @override
  String get cancelled => 'Cancelada';

  @override
  String get completedToday => 'Completadas Hoy';

  @override
  String get todaysAppointments => 'Citas de Hoy';

  @override
  String get viewAll => 'Ver Todas';

  @override
  String get noAppointmentsToday => 'No hay citas para hoy';

  @override
  String get quickActions => 'Acciones Rápidas';

  @override
  String get addAppointment => 'Agregar Cita';

  @override
  String get createService => 'Crear Servicio';

  @override
  String get addEmployee => 'Agregar Empleado';

  @override
  String get calendar => 'Calendario';

  @override
  String get noAppointmentsForDay => 'No hay citas para este día';

  @override
  String get customer => 'Cliente';

  @override
  String get customerName => 'Nombre';

  @override
  String get pleaseEnterCustomerName => 'Por favor ingresa tu nombre';

  @override
  String get phone => 'Teléfono';

  @override
  String get pleaseEnterPhone => 'Por favor ingresa el teléfono';

  @override
  String get selectDate => 'Seleccionar Fecha';

  @override
  String get selectTime => 'Seleccionar Hora';

  @override
  String get selectService => 'Seleccionar Servicio';

  @override
  String get selectEmployee => 'Seleccionar Empleado';

  @override
  String get depositPaid => 'Depósito Pagado';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get name => 'Nombre';

  @override
  String get pleaseEnterName => 'Por favor ingresa el nombre';

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get activate => 'Activar';

  @override
  String get deactivate => 'Desactivar';

  @override
  String get price => 'Precio';

  @override
  String get duration => 'Duración';

  @override
  String get minutes => 'minutos';

  @override
  String get profile => 'Perfil';

  @override
  String get workingHours => 'Horario de Trabajo';

  @override
  String get exceptions => 'Excepciones';

  @override
  String get deposits => 'Depósitos';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get noItems => 'No hay elementos';

  @override
  String get error => 'Error';

  @override
  String get newAppointment => 'Nueva Cita';

  @override
  String get editEmployee => 'Editar Empleado';

  @override
  String get addService => 'Agregar Servicio';

  @override
  String get editService => 'Editar Servicio';

  @override
  String get date => 'Fecha';

  @override
  String get time => 'Hora';

  @override
  String get selectDatePlaceholder => 'Seleccionar fecha';

  @override
  String get selectTimePlaceholder => 'Seleccionar hora';

  @override
  String get noServicesAvailable => 'No hay servicios disponibles';

  @override
  String serviceSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'servicios seleccionados',
      one: 'servicio seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get pleaseEnterServiceName => 'Por favor ingresa el nombre del servicio';

  @override
  String get pleaseEnterDuration => 'Por favor ingresa la duración';

  @override
  String get pleaseEnterPrice => 'Por favor ingresa el precio';

  @override
  String get pleaseEnterValidNumber => 'Por favor ingresa un número válido';

  @override
  String get descriptionOptional => 'Descripción (Opcional)';

  @override
  String get durationMinutes => 'Duración (minutos)';

  @override
  String get pleaseEnterEmployeeName => 'Por favor ingresa el nombre del empleado';

  @override
  String get errorLoadingServices => 'Error al cargar servicios';

  @override
  String get errorCreatingAppointments => 'Error al crear citas';

  @override
  String get pleaseSelectAtLeastOneService => 'Por favor selecciona al menos un servicio';

  @override
  String get appointmentConfirmedSuccessfully => 'Cita confirmada exitosamente';

  @override
  String get appointmentCancelledSuccessfully => 'Cita cancelada exitosamente';

  @override
  String get appointmentCompletedSuccessfully => 'Cita completada exitosamente';

  @override
  String get confirmAppointment => 'Confirmar';

  @override
  String get cancelAppointment => 'Cancelar';

  @override
  String get completeAppointment => 'Completar';

  @override
  String get cancelAppointmentTitle => 'Cancelar Cita';

  @override
  String get cancelAppointmentMessage => '¿Estás seguro de que quieres cancelar esta cita?';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Sí, Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get businessName => 'Nombre del Negocio';

  @override
  String get pleaseEnterBusinessName => 'Por favor ingresa el nombre del negocio';

  @override
  String get description => 'Descripción';

  @override
  String get address => 'Dirección';

  @override
  String get contactInformation => 'Información de Contacto';

  @override
  String get timezone => 'Zona Horaria';

  @override
  String get pleaseEnterTimezone => 'Por favor ingresa la zona horaria';

  @override
  String get timezoneHelper => 'ej., America/New_York';

  @override
  String get saveProfile => 'Guardar Perfil';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualizado exitosamente';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get closed => 'Cerrado';

  @override
  String get open => 'Abierto';

  @override
  String get startTime => 'Hora de Inicio';

  @override
  String get endTime => 'Hora de Fin';

  @override
  String get addException => 'Agregar Excepción';

  @override
  String get noExceptionsScheduled => 'No hay excepciones programadas';

  @override
  String get reasonOptional => 'Razón (Opcional)';

  @override
  String get requiresDeposit => 'Requiere Depósito';

  @override
  String get enableDepositRequirement => 'Habilitar requerimiento de depósito para citas';

  @override
  String get depositType => 'Tipo de Depósito';

  @override
  String get fixedAmount => 'Cantidad Fija';

  @override
  String get percentage => 'Porcentaje';

  @override
  String get percentageLabel => 'Porcentaje (%)';

  @override
  String get amount => 'Cantidad';

  @override
  String get enterPercentage => 'Ingresa el porcentaje (ej., 20 para 20%)';

  @override
  String get enterFixedAmount => 'Ingresa la cantidad fija';

  @override
  String get pleaseEnterValue => 'Por favor ingresa un valor';

  @override
  String get percentageMustBeBetween => 'El porcentaje debe estar entre 0 y 100';

  @override
  String get saveSettings => 'Guardar Configuración';

  @override
  String get depositSettingsUpdated => 'Configuración de depósitos actualizada';

  @override
  String get filterByStatus => 'Filtrar por Estado';

  @override
  String get searchByCustomerName => 'Buscar por nombre del cliente';

  @override
  String get searchByServiceName => 'Buscar por nombre del servicio';

  @override
  String get searchByEmployeeName => 'Buscar por nombre del empleado';

  @override
  String get all => 'Todos';

  @override
  String get profileDescription => 'Información del negocio';

  @override
  String get workingHoursDescription => 'Horarios de atención';

  @override
  String get exceptionsDescription => 'Horarios no disponibles';

  @override
  String get depositsDescription => 'Establecer si se requiere depósito para confirmar la cita';

  @override
  String get bookAppointment => 'Reservar Cita';

  @override
  String get customerInformation => 'Información del Cliente';

  @override
  String get customerPhone => 'Teléfono';

  @override
  String get enterCustomerName => 'Ingresa el nombre del cliente';

  @override
  String get enterCustomerPhone => 'Ingresa el teléfono';

  @override
  String get pleaseEnterCustomerPhone => 'Por favor ingresa el teléfono del cliente';

  @override
  String get enterCustomerInformation => 'Ingresar Información del Cliente';

  @override
  String get editCustomerInformation => 'Editar Información del Cliente';

  @override
  String get customerInfo => 'Cliente';

  @override
  String get noTimeSlotsAvailable => 'No hay horarios disponibles para esta fecha';

  @override
  String get errorLoadingTimeSlots => 'Error al cargar horarios disponibles';

  @override
  String get appointmentBookedSuccessfully => '¡Cita reservada exitosamente!';

  @override
  String get depositRequired => 'Depósito Requerido';

  @override
  String get total => 'Total';

  @override
  String get noSubscription => 'Sin Suscripción';

  @override
  String get subscribeToAccessPremium => 'Suscríbete para acceder a funciones premium';

  @override
  String get viewPlans => 'Ver Planes';

  @override
  String get noPlan => 'Sin Plan';

  @override
  String daysRemainingInTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días restantes en prueba',
      one: '1 día restante en prueba',
    );
    return '$_temp0';
  }

  @override
  String renewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get manageSubscription => 'Gestionar Suscripción';

  @override
  String get errorLoadingSubscription => 'Error al cargar suscripción';

  @override
  String get retry => 'Reintentar';

  @override
  String get errorCreatingCustomer => 'Error al crear cliente';

  @override
  String get back => 'Atrás';

  @override
  String get errorLoadingDates => 'Error al cargar fechas';

  @override
  String get noAppointmentInfo => 'No hay información de cita';

  @override
  String get downloadTicket => 'Descargar Ticket';

  @override
  String get ticketSharedSuccessfully => 'Ticket compartido exitosamente';

  @override
  String get errorSharingTicket => 'Error al compartir ticket';

  @override
  String get noPhoneNumberAvailable => 'No hay número de teléfono disponible';

  @override
  String get errorOpeningWhatsApp => 'Error al abrir WhatsApp';

  @override
  String get errorAppointmentConflict => 'Ya tienes una cita en este horario';

  @override
  String get errorBookingAppointments => 'Error al reservar citas';

  @override
  String errorBookingSomeAppointments(int count) {
    return 'Se reservaron $count citas. Hubo un error';
  }

  @override
  String get errorNoEmployeeAvailable => 'No hay empleado disponible para este servicio';

  @override
  String get errorSlotNoLongerAvailable => 'Este horario ya no está disponible';

  @override
  String get errorGenericBooking => 'No se pudo reservar la cita. Por favor intenta de nuevo';

  @override
  String get rescheduleAppointment => 'Reagendar Cita';

  @override
  String get reschedule => 'Reagendar';

  @override
  String get appointmentRescheduledSuccessfully => 'Cita reagendada exitosamente';

  @override
  String get errorReschedulingAppointment => 'Error al reagendar la cita';

  @override
  String get pleaseSelectDate => 'Por favor selecciona una fecha';

  @override
  String get pleaseSelectTime => 'Por favor selecciona una hora';

  @override
  String get pleaseSelectService => 'Por favor selecciona un servicio';

  @override
  String get pleaseSelectEmployee => 'Por favor selecciona un empleado';
}
