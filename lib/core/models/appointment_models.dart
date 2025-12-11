import 'customer_models.dart';
import 'employee_models.dart';
import 'service_models.dart';

class Appointment {
  final String id;
  final String businessId;
  final String employeeId;
  final String customerId;
  final String serviceId;
  final String date;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;
  final bool? depositPaid;
  final Customer? customer;
  final Employee? employee;
  final Service? service;

  Appointment({
    required this.id,
    required this.businessId,
    required this.employeeId,
    required this.customerId,
    required this.serviceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.depositPaid,
    this.customer,
    this.employee,
    this.service,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        employeeId: json['employeeId'] as String,
        customerId: json['customerId'] as String,
        serviceId: json['serviceId'] as String,
        date: json['date'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        status: AppointmentStatus.fromString(json['status'] as String),
        depositPaid: json['depositPaid'] as bool?,
        customer: json['customer'] != null
            ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
        employee: json['employee'] != null
            ? Employee.fromJson(json['employee'] as Map<String, dynamic>)
            : null,
        service: json['service'] != null
            ? Service.fromJson(json['service'] as Map<String, dynamic>)
            : null,
      );
}

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  static AppointmentStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.pending;
      case 'CONFIRMED':
        return AppointmentStatus.confirmed;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      default:
        throw ArgumentError('Invalid appointment status: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.completed:
        return 'COMPLETED';
    }
  }
}

class AppointmentStatusUpdate {
  final AppointmentStatus? status;
  final bool? depositPaid;

  AppointmentStatusUpdate({
    this.status,
    this.depositPaid,
  });

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status!.toString(),
        if (depositPaid != null) 'depositPaid': depositPaid,
      };
}

class RescheduleAppointmentRequest {
  final String date;
  final String startTime;
  final String employeeId;
  final String serviceId;

  RescheduleAppointmentRequest({
    required this.date,
    required this.startTime,
    required this.employeeId,
    required this.serviceId,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'startTime': startTime,
        'employeeId': employeeId,
        'serviceId': serviceId,
      };
}

