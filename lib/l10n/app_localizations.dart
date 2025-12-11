import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CitApp - Appointment Management'**
  String get appTitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your appointments'**
  String get signInToManage;

  /// Business ID input label
  ///
  /// In en, this message translates to:
  /// **'Business ID'**
  String get businessId;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Business ID validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your business ID'**
  String get pleaseEnterBusinessId;

  /// Password validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Appointments screen title
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// Services screen title
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// Employees screen title
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Business settings screen title
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// Summary section title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Confirmed status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Completed today label
  ///
  /// In en, this message translates to:
  /// **'Completed Today'**
  String get completedToday;

  /// Today's appointments section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todaysAppointments;

  /// View all link
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Empty state message for today's appointments
  ///
  /// In en, this message translates to:
  /// **'No appointments for today'**
  String get noAppointmentsToday;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Add appointment action
  ///
  /// In en, this message translates to:
  /// **'Add Appointment'**
  String get addAppointment;

  /// Create service action
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get createService;

  /// Add employee title
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// Calendar filter
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Empty state for calendar day
  ///
  /// In en, this message translates to:
  /// **'No appointments for this day'**
  String get noAppointmentsForDay;

  /// Customer label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Customer name label
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// Customer name validation
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get pleaseEnterCustomerName;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Phone validation
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// Select date step title
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Select time step title
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Select service step title
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// Select employee button
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// Deposit paid label
  ///
  /// In en, this message translates to:
  /// **'Deposit Paid'**
  String get depositPaid;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Name validation
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Activate action
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// Deactivate action
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Minutes unit
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Working hours tab
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// Exceptions tab
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get exceptions;

  /// Deposits tab
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get deposits;

  /// Logout action
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// New appointment title
  ///
  /// In en, this message translates to:
  /// **'New Appointment'**
  String get newAppointment;

  /// Edit employee title
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// Add service title
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// Edit service title
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Select date placeholder
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDatePlaceholder;

  /// Select time placeholder
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTimePlaceholder;

  /// No services available message
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get noServicesAvailable;

  /// Service selected count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {service selected} other {services selected}}'**
  String serviceSelected(int count);

  /// Service name validation
  ///
  /// In en, this message translates to:
  /// **'Please enter service name'**
  String get pleaseEnterServiceName;

  /// Duration validation
  ///
  /// In en, this message translates to:
  /// **'Please enter duration'**
  String get pleaseEnterDuration;

  /// Price validation
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get pleaseEnterPrice;

  /// Valid number validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// Description optional label
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// Duration minutes label
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// Employee name validation
  ///
  /// In en, this message translates to:
  /// **'Please enter employee name'**
  String get pleaseEnterEmployeeName;

  /// Error loading services message
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get errorLoadingServices;

  /// Error creating appointments message
  ///
  /// In en, this message translates to:
  /// **'Error creating appointments'**
  String get errorCreatingAppointments;

  /// Please select service validation
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get pleaseSelectAtLeastOneService;

  /// Appointment confirmed message
  ///
  /// In en, this message translates to:
  /// **'Appointment confirmed successfully'**
  String get appointmentConfirmedSuccessfully;

  /// Appointment cancelled message
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled successfully'**
  String get appointmentCancelledSuccessfully;

  /// Appointment completed message
  ///
  /// In en, this message translates to:
  /// **'Appointment completed successfully'**
  String get appointmentCompletedSuccessfully;

  /// Confirm appointment button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAppointment;

  /// Cancel appointment button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAppointment;

  /// Complete appointment button
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAppointment;

  /// Cancel appointment dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointmentTitle;

  /// Cancel appointment confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get cancelAppointmentMessage;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Yes cancel button
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Business name label
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Business name validation
  ///
  /// In en, this message translates to:
  /// **'Please enter business name'**
  String get pleaseEnterBusinessName;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Contact information section title
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// Timezone label
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// Timezone validation
  ///
  /// In en, this message translates to:
  /// **'Please enter timezone'**
  String get pleaseEnterTimezone;

  /// Timezone helper text
  ///
  /// In en, this message translates to:
  /// **'e.g., America/New_York'**
  String get timezoneHelper;

  /// Save profile button
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// Profile updated message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// Monday day name
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday day name
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday day name
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday day name
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday day name
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday day name
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday day name
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Closed status
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// Open status
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Add exception button
  ///
  /// In en, this message translates to:
  /// **'Add Exception'**
  String get addException;

  /// No exceptions message
  ///
  /// In en, this message translates to:
  /// **'No exceptions scheduled'**
  String get noExceptionsScheduled;

  /// Reason optional label
  ///
  /// In en, this message translates to:
  /// **'Reason (Optional)'**
  String get reasonOptional;

  /// Requires deposit label
  ///
  /// In en, this message translates to:
  /// **'Requires Deposit'**
  String get requiresDeposit;

  /// Enable deposit requirement subtitle
  ///
  /// In en, this message translates to:
  /// **'Enable deposit requirement for appointments'**
  String get enableDepositRequirement;

  /// Deposit type label
  ///
  /// In en, this message translates to:
  /// **'Deposit Type'**
  String get depositType;

  /// Fixed amount label
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get fixedAmount;

  /// Percentage label
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// Percentage input label
  ///
  /// In en, this message translates to:
  /// **'Percentage (%)'**
  String get percentageLabel;

  /// Amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Percentage helper text
  ///
  /// In en, this message translates to:
  /// **'Enter percentage (e.g., 20 for 20%)'**
  String get enterPercentage;

  /// Fixed amount helper text
  ///
  /// In en, this message translates to:
  /// **'Enter fixed amount'**
  String get enterFixedAmount;

  /// Value validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get pleaseEnterValue;

  /// Percentage range validation
  ///
  /// In en, this message translates to:
  /// **'Percentage must be between 0 and 100'**
  String get percentageMustBeBetween;

  /// Save settings button
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// Deposit settings updated message
  ///
  /// In en, this message translates to:
  /// **'Deposit settings updated'**
  String get depositSettingsUpdated;

  /// Filter by status label
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// Search by customer name placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by customer name'**
  String get searchByCustomerName;

  /// Search by service name placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by service name'**
  String get searchByServiceName;

  /// Search by employee name placeholder
  ///
  /// In en, this message translates to:
  /// **'Search by employee name'**
  String get searchByEmployeeName;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Profile settings description
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get profileDescription;

  /// Working hours settings description
  ///
  /// In en, this message translates to:
  /// **'Hours you are available'**
  String get workingHoursDescription;

  /// Exceptions settings description
  ///
  /// In en, this message translates to:
  /// **'Days when you are not available'**
  String get exceptionsDescription;

  /// Deposits settings description
  ///
  /// In en, this message translates to:
  /// **'Requires an amount to confirm appointments'**
  String get depositsDescription;

  /// Book appointment screen title
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// Customer information section title
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// Customer phone label
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// Enter customer name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get enterCustomerName;

  /// Enter customer phone placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter customer phone'**
  String get enterCustomerPhone;

  /// Customer phone validation
  ///
  /// In en, this message translates to:
  /// **'Please enter customer phone'**
  String get pleaseEnterCustomerPhone;

  /// Enter customer information button
  ///
  /// In en, this message translates to:
  /// **'Enter Customer Information'**
  String get enterCustomerInformation;

  /// Edit customer information button
  ///
  /// In en, this message translates to:
  /// **'Edit Customer Information'**
  String get editCustomerInformation;

  /// Customer info label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerInfo;

  /// No time slots available message
  ///
  /// In en, this message translates to:
  /// **'No time slots available for this date'**
  String get noTimeSlotsAvailable;

  /// Error loading time slots message
  ///
  /// In en, this message translates to:
  /// **'Error loading time slots'**
  String get errorLoadingTimeSlots;

  /// Appointment booked success message
  ///
  /// In en, this message translates to:
  /// **'Appointment booked successfully!'**
  String get appointmentBookedSuccessfully;

  /// Deposit required message
  ///
  /// In en, this message translates to:
  /// **'Deposit Required'**
  String get depositRequired;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No subscription status
  ///
  /// In en, this message translates to:
  /// **'No Subscription'**
  String get noSubscription;

  /// Subscribe message
  ///
  /// In en, this message translates to:
  /// **'Subscribe to access premium features'**
  String get subscribeToAccessPremium;

  /// View plans button
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No plan status
  ///
  /// In en, this message translates to:
  /// **'No Plan'**
  String get noPlan;

  /// No description provided for @daysRemainingInTrial.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 day remaining in trial} other {{count} days remaining in trial}}'**
  String daysRemainingInTrial(int count);

  /// No description provided for @renewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String renewsOn(String date);

  /// Manage subscription button
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// Error loading subscription message
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription'**
  String get errorLoadingSubscription;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Error creating customer message
  ///
  /// In en, this message translates to:
  /// **'Error creating customer'**
  String get errorCreatingCustomer;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Error loading dates message
  ///
  /// In en, this message translates to:
  /// **'Error loading dates'**
  String get errorLoadingDates;

  /// No appointment info message
  ///
  /// In en, this message translates to:
  /// **'No appointment information'**
  String get noAppointmentInfo;

  /// Download ticket button
  ///
  /// In en, this message translates to:
  /// **'Download Ticket'**
  String get downloadTicket;

  /// Ticket shared successfully message
  ///
  /// In en, this message translates to:
  /// **'Ticket shared successfully'**
  String get ticketSharedSuccessfully;

  /// Error sharing ticket message
  ///
  /// In en, this message translates to:
  /// **'Error sharing ticket'**
  String get errorSharingTicket;

  /// No phone number available message
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneNumberAvailable;

  /// Error opening WhatsApp message
  ///
  /// In en, this message translates to:
  /// **'Error opening WhatsApp'**
  String get errorOpeningWhatsApp;

  /// Appointment conflict error message
  ///
  /// In en, this message translates to:
  /// **'You already have an appointment at this time'**
  String get errorAppointmentConflict;

  /// Error booking appointments message
  ///
  /// In en, this message translates to:
  /// **'Error booking appointments'**
  String get errorBookingAppointments;

  /// No description provided for @errorBookingSomeAppointments.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments booked. There was an error'**
  String errorBookingSomeAppointments(int count);

  /// No employee available error message
  ///
  /// In en, this message translates to:
  /// **'No employee available for this service'**
  String get errorNoEmployeeAvailable;

  /// Time slot no longer available error message
  ///
  /// In en, this message translates to:
  /// **'This time slot is no longer available'**
  String get errorSlotNoLongerAvailable;

  /// Generic booking error message
  ///
  /// In en, this message translates to:
  /// **'Could not book the appointment. Please try again'**
  String get errorGenericBooking;

  /// Reschedule appointment title
  ///
  /// In en, this message translates to:
  /// **'Reschedule Appointment'**
  String get rescheduleAppointment;

  /// Reschedule button
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// Appointment rescheduled success message
  ///
  /// In en, this message translates to:
  /// **'Appointment rescheduled successfully'**
  String get appointmentRescheduledSuccessfully;

  /// Error rescheduling appointment message
  ///
  /// In en, this message translates to:
  /// **'Error rescheduling appointment'**
  String get errorReschedulingAppointment;

  /// Date selection validation
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectDate;

  /// Time selection validation
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get pleaseSelectTime;

  /// Service selection validation
  ///
  /// In en, this message translates to:
  /// **'Please select a service'**
  String get pleaseSelectService;

  /// Employee selection validation
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get pleaseSelectEmployee;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
