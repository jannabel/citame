// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Citame';

  @override
  String get login => 'Login';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToManage => 'Sign in to manage your appointments';

  @override
  String get businessId => 'Business ID';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterBusinessId => 'Please enter your business ID';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get appointments => 'Appointments';

  @override
  String get services => 'Services';

  @override
  String get employees => 'Employees';

  @override
  String get settings => 'Settings';

  @override
  String get businessSettings => 'Business Settings';

  @override
  String get summary => 'Summary';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completedToday => 'Completed Today';

  @override
  String get todaysAppointments => 'Today\'s Appointments';

  @override
  String get viewAll => 'View All';

  @override
  String get noAppointmentsToday => 'No appointments for today';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addAppointment => 'Add Appointment';

  @override
  String get createService => 'Create Service';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get calendar => 'Calendar';

  @override
  String get noAppointmentsForDay => 'No appointments for this day';

  @override
  String get customer => 'Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get pleaseEnterCustomerName => 'Please enter customer name';

  @override
  String get phone => 'Phone';

  @override
  String get pleaseEnterPhone => 'Please enter phone number';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get selectService => 'Select Service';

  @override
  String get selectEmployee => 'Select Employee';

  @override
  String get depositPaid => 'Deposit Paid';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get name => 'Name';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get price => 'Price';

  @override
  String get duration => 'Duration';

  @override
  String get minutes => 'minutes';

  @override
  String get profile => 'Profile';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get exceptions => 'Exceptions';

  @override
  String get deposits => 'Deposits';

  @override
  String get logout => 'Logout';

  @override
  String get noItems => 'No items';

  @override
  String get error => 'Error';

  @override
  String get newAppointment => 'New Appointment';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get addService => 'Add Service';

  @override
  String get editService => 'Edit Service';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get selectDatePlaceholder => 'Select date';

  @override
  String get selectTimePlaceholder => 'Select time';

  @override
  String get noServicesAvailable => 'No services available';

  @override
  String serviceSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'services selected',
      one: 'service selected',
    );
    return '$_temp0';
  }

  @override
  String get pleaseEnterServiceName => 'Please enter service name';

  @override
  String get pleaseEnterDuration => 'Please enter duration';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get pleaseEnterEmployeeName => 'Please enter employee name';

  @override
  String get errorLoadingServices => 'Error loading services';

  @override
  String get errorCreatingAppointments => 'Error creating appointments';

  @override
  String get pleaseSelectAtLeastOneService => 'Please select at least one service';

  @override
  String get appointmentConfirmedSuccessfully => 'Appointment confirmed successfully';

  @override
  String get appointmentCancelledSuccessfully => 'Appointment cancelled successfully';

  @override
  String get appointmentCompletedSuccessfully => 'Appointment completed successfully';

  @override
  String get confirmAppointment => 'Confirm';

  @override
  String get cancelAppointment => 'Cancel';

  @override
  String get completeAppointment => 'Complete';

  @override
  String get cancelAppointmentTitle => 'Cancel Appointment';

  @override
  String get cancelAppointmentMessage => 'Are you sure you want to cancel this appointment?';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get businessName => 'Business Name';

  @override
  String get pleaseEnterBusinessName => 'Please enter business name';

  @override
  String get description => 'Description';

  @override
  String get address => 'Address';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get timezone => 'Timezone';

  @override
  String get pleaseEnterTimezone => 'Please enter timezone';

  @override
  String get timezoneHelper => 'e.g., America/New_York';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get closed => 'Closed';

  @override
  String get open => 'Open';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get addException => 'Add Exception';

  @override
  String get noExceptionsScheduled => 'No exceptions scheduled';

  @override
  String get reasonOptional => 'Reason (Optional)';

  @override
  String get requiresDeposit => 'Requires Deposit';

  @override
  String get enableDepositRequirement => 'Enable deposit requirement for appointments';

  @override
  String get depositType => 'Deposit Type';

  @override
  String get fixedAmount => 'Fixed Amount';

  @override
  String get percentage => 'Percentage';

  @override
  String get percentageLabel => 'Percentage (%)';

  @override
  String get amount => 'Amount';

  @override
  String get enterPercentage => 'Enter percentage (e.g., 20 for 20%)';

  @override
  String get enterFixedAmount => 'Enter fixed amount';

  @override
  String get pleaseEnterValue => 'Please enter a value';

  @override
  String get percentageMustBeBetween => 'Percentage must be between 0 and 100';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get depositSettingsUpdated => 'Deposit settings updated';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get searchByCustomerName => 'Search by customer name';

  @override
  String get searchByServiceName => 'Search by service name';

  @override
  String get searchByEmployeeName => 'Search by employee name';

  @override
  String get all => 'All';

  @override
  String get profileDescription => 'Business Information';

  @override
  String get workingHoursDescription => 'Hours you are available';

  @override
  String get exceptionsDescription => 'Days when you are not available';

  @override
  String get depositsDescription => 'Requires an amount to confirm appointments';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get customerInformation => 'Customer Information';

  @override
  String get customerPhone => 'Customer Phone';

  @override
  String get enterCustomerName => 'Enter customer name';

  @override
  String get enterCustomerPhone => 'Enter customer phone';

  @override
  String get pleaseEnterCustomerPhone => 'Please enter customer phone';

  @override
  String get enterCustomerInformation => 'Enter Customer Information';

  @override
  String get editCustomerInformation => 'Edit Customer Information';

  @override
  String get customerInfo => 'Customer';

  @override
  String get noTimeSlotsAvailable => 'No time slots available for this date';

  @override
  String get errorLoadingTimeSlots => 'Error loading time slots';

  @override
  String get appointmentBookedSuccessfully => 'Appointment booked successfully!';

  @override
  String get depositRequired => 'Deposit Required';

  @override
  String get total => 'Total';

  @override
  String get noSubscription => 'No Subscription';

  @override
  String get subscribeToAccessPremium => 'Subscribe to access premium features';

  @override
  String get viewPlans => 'View Plans';

  @override
  String get noPlan => 'No Plan';

  @override
  String daysRemainingInTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days remaining in trial',
      one: '1 day remaining in trial',
    );
    return '$_temp0';
  }

  @override
  String renewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get errorLoadingSubscription => 'Error loading subscription';

  @override
  String get retry => 'Retry';

  @override
  String get errorCreatingCustomer => 'Error creating customer';

  @override
  String get back => 'Back';

  @override
  String get errorLoadingDates => 'Error loading dates';

  @override
  String get noAppointmentInfo => 'No appointment information';

  @override
  String get downloadTicket => 'Download Ticket';

  @override
  String get ticketSharedSuccessfully => 'Ticket shared successfully';

  @override
  String get errorSharingTicket => 'Error sharing ticket';

  @override
  String get noPhoneNumberAvailable => 'No phone number available';

  @override
  String get errorOpeningWhatsApp => 'Error opening WhatsApp';

  @override
  String get errorAppointmentConflict => 'You already have an appointment at this time';

  @override
  String get errorBookingAppointments => 'Error booking appointments';

  @override
  String errorBookingSomeAppointments(int count) {
    return '$count appointments booked. There was an error';
  }

  @override
  String get errorNoEmployeeAvailable => 'No employee available for this service';

  @override
  String get errorSlotNoLongerAvailable => 'This time slot is no longer available';

  @override
  String get errorGenericBooking => 'Could not book the appointment. Please try again';

  @override
  String get rescheduleAppointment => 'Reschedule Appointment';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get appointmentRescheduledSuccessfully => 'Appointment rescheduled successfully';

  @override
  String get errorReschedulingAppointment => 'Error rescheduling appointment';

  @override
  String get pleaseSelectDate => 'Please select a date';

  @override
  String get pleaseSelectTime => 'Please select a time';

  @override
  String get pleaseSelectService => 'Please select a service';

  @override
  String get pleaseSelectEmployee => 'Please select an employee';
}
