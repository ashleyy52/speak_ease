import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class for appointments
class Appointment {
  final String id;
  final DateTime date;
  final String doctorName;
  final String appointmentType;
  final String location;
  final String treatmentPlan;
  final String duration;
  final List<String> toDo; // New field for To Do tasks

  Appointment({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.appointmentType,
    required this.location,
    required this.treatmentPlan,
    required this.duration,
    this.toDo = const [], // Default to an empty list
  });

  // Convert appointment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'doctorName': doctorName,
      'appointmentType': appointmentType,
      'location': location,
      'treatmentPlan': treatmentPlan,
      'duration': duration,
      'toDo': toDo, // Add toDo to JSON
    };
  }

  // Create appointment from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      doctorName: json['doctorName'],
      appointmentType: json['appointmentType'],
      location: json['location'],
      treatmentPlan: json['treatmentPlan'],
      duration: json['duration'],
      toDo: List<String>.from(json['toDo'] ?? []), // Parse toDo list, default to empty if null
    );
  }

  // Create a copy of this appointment with updated fields
  Appointment copyWith({
    DateTime? date,
    String? doctorName,
    String? appointmentType,
    String? location,
    String? treatmentPlan,
    String? duration,
    List<String>? toDo, // Add toDo to copyWith
  }) {
    return Appointment(
      id: this.id,
      date: date ?? this.date,
      doctorName: doctorName ?? this.doctorName,
      appointmentType: appointmentType ?? this.appointmentType,
      location: location ?? this.location,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      duration: duration ?? this.duration,
      toDo: toDo ?? this.toDo, // Use new toDo if provided, otherwise use existing
    );
  }
}

// Appointment storage service
class AppointmentService {
  static const String _appointmentsKey = 'appointments';

  // Save all appointments
  static Future<void> saveAppointments(List<Appointment> appointments) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = appointments.map((appointment) =>
        jsonEncode(appointment.toJson())
    ).toList();

    await prefs.setStringList(_appointmentsKey, jsonList);
  }

  // Get all appointments
  static Future<List<Appointment>> getAppointments() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_appointmentsKey);

    if (jsonList == null) {
      return [];
    }

    return jsonList.map((json) =>
        Appointment.fromJson(jsonDecode(json))
    ).toList();
  }

  // Update a specific appointment with a new Appointment object
  static Future<void> updateAppointment(String id, Appointment updatedAppointment) async {
    final List<Appointment> appointments = await getAppointments();
    final int index = appointments.indexWhere((appointment) => appointment.id == id);

    if (index != -1) {
      appointments[index] = updatedAppointment;
      await saveAppointments(appointments);
    }
  }
}

// Animated Dialog Widget
class AnimatedDialog extends StatefulWidget {
  final Widget child;

  const AnimatedDialog({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedDialogState createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<AnimatedDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

// PIN Verification Dialog
class PinVerificationDialog extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const PinVerificationDialog({Key? key, required this.scaffoldMessengerKey}) : super(key: key);

  @override
  _PinVerificationDialogState createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final TextEditingController pinController = TextEditingController();
  int attempts = 0;
  final int maxAttempts = 3;
  String? errorText;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  Future<String> _getParentalPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('parental_pin') ?? '1234';
  }

  void _onVerify() async {
    final parentalPin = await _getParentalPin();
    if (pinController.text == parentalPin) {
      Navigator.pop(context, true);
    } else {
      attempts++;
      if (attempts < maxAttempts) {
        setState(() {
          errorText = 'Incorrect PIN. ${maxAttempts - attempts} attempts remaining.';
        });
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Incorrect PIN. ${maxAttempts - attempts} attempts remaining.',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Too many incorrect attempts. Please try again later.',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Parental PIN Required',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter the parental PIN to reschedule the appointment.',
            style: GoogleFonts.nunito(fontSize: 16),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: errorText,
            ),
            maxLength: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _onVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A8FE3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Verify',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Appointment details page
// Appointment details page
class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadAppointments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Load all appointments
  Future<void> _loadAppointments() async {
    final appointments = await AppointmentService.getAppointments();
    setState(() {
      _appointments = appointments; // Load all appointments
      _isLoading = false;
    });
  }

  // Verify parental PIN
  Future<bool> _verifyParentalPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool parentalLockEnabled = prefs.getBool('parental_lock_enabled') ?? true;
    if (!parentalLockEnabled) return true;

    final bool? isCorrect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PinVerificationDialog(scaffoldMessengerKey: _scaffoldMessengerKey),
    );

    return isCorrect ?? false;
  }

  // Update appointment
  Future<void> _updateAppointment(Appointment updatedAppointment) async {
    await AppointmentService.updateAppointment(updatedAppointment.id, updatedAppointment);

    // Reload appointments to reflect changes
    await _loadAppointments();

    // Show success message
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Appointment successfully updated',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Get level progress from SharedPreferences
  Future<double> _getLevelProgress(String levelTask) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    double progress = 0.0;

    final levelNumber = int.tryParse(levelTask.replaceAll('Complete Level ', '')) ?? 0;
    if (levelNumber == 0) return 0.0;

    String key;
    switch (levelNumber) {
      case 1:
        key = 'wordRecognized';
        break;
      case 2:
        key = 'level2_wordRecognized';
        break;
      case 3:
        key = 'level3_wordRecognized';
        break;
      case 4:
        key = 'level4_wordRecognized';
        break;
      case 5:
        key = 'level5_wordRecognized';
        break;
      case 6:
        key = 'level6_wordRecognized';
        break;
      case 7:
        key = 'level7_wordRecognized';
        break;
      default:
        return 0.0;
    }

    List<String>? savedRecognized = prefs.getStringList(key);
    if (savedRecognized != null) {
      progress = savedRecognized.where((e) => e == 'true').length / 5;
    }

    return progress;
  }

  Future<void> _showRescheduleDialog(BuildContext context, Appointment appointment) async {
    // Verify parental PIN before proceeding
    final bool isPinCorrect = await _verifyParentalPin();
    if (!isPinCorrect) return;

    // Controllers for the form fields
    final TextEditingController doctorNameController = TextEditingController(text: appointment.doctorName);
    final TextEditingController appointmentTypeController = TextEditingController(text: appointment.appointmentType);
    final TextEditingController locationController = TextEditingController(text: appointment.location);
    final TextEditingController treatmentPlanController = TextEditingController(text: appointment.treatmentPlan);
    final TextEditingController durationController = TextEditingController(text: appointment.duration);
    final TextEditingController toDoController = TextEditingController(text: appointment.toDo.join(', '));

    DateTime selectedDate = appointment.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appointment.date);

    // First pick date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF323232),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Rescheduling cancelled.',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    selectedDate = pickedDate;

    // Then pick time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF323232),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Rescheduling cancelled.',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    selectedTime = pickedTime;

    // Combine date and time
    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Show form dialog to update all details with animation
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AnimatedDialog(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FA),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Reschedule Appointment',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: const Color(0xFF323232),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Doctor Mode',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Update the appointment details below:',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Date and Time Display
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Colors.deepPurple, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${_getWeekday(newDateTime)}, ${newDateTime.month}/${newDateTime.day}/${newDateTime.year}",
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF323232),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.deepPurple, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(newDateTime),
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF323232),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Doctor Name
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: doctorNameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.person_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter Doctor Name',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Appointment Type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: appointmentTypeController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.medical_services_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter Appointment Type',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Location
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter Location',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          maxLines: 3,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Treatment Plan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: treatmentPlanController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.description_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter Treatment Plan',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          maxLines: 3,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: durationController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.timer_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter Duration',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // To Do Tasks
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: toDoController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.task_alt_rounded, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                            hintText: 'Enter To Do Tasks (comma-separated)',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Basic validation
                  if (doctorNameController.text.isEmpty ||
                      appointmentTypeController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      treatmentPlanController.text.isEmpty ||
                      durationController.text.isEmpty) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fill in all fields',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      // Parse the To Do tasks from the input
      final toDoTasks = toDoController.text
          .split(',')
          .map((task) => task.trim())
          .where((task) => task.isNotEmpty)
          .toList();

      // Create updated appointment
      final updatedAppointment = appointment.copyWith(
        date: newDateTime,
        doctorName: doctorNameController.text,
        appointmentType: appointmentTypeController.text,
        location: locationController.text,
        treatmentPlan: treatmentPlanController.text,
        duration: durationController.text,
        toDo: toDoTasks,
      );

      // Update appointment using the service
      await _updateAppointment(updatedAppointment);
    }

    // Dispose controllers
    doctorNameController.dispose();
    appointmentTypeController.dispose();
    locationController.dispose();
    treatmentPlanController.dispose();
    durationController.dispose();
    toDoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        key: _scaffoldMessengerKey,extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Scaffold(
        key: _scaffoldMessengerKey,extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,),
        body: Center(
          child: Text(
            'No appointments found',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF323232),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldMessengerKey,
     extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF323232),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFCC80),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0,right: 20,bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0),
                    child: Row(
                      children: [
                        Text(
                          'UPCOMING',
                          style: TextStyle(
                            fontFamily: "Impact",
                            fontSize: 40,
                            color: Color(0xFF323232),
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 15,),
                        Text(
                          'VISIT',
                          style: TextStyle(
                            fontFamily: "Impact",
                            fontSize: 40,
                            color: Color(0xFFFAA83E),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15,),

                  // Swipeable main card for consultations
                  SizedBox(
                    height: 200, // Adjust height as needed
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _appointments[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.deepPurple,
                                Color(0xFF6A67E8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.appointmentType,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    "${_getWeekday(appointment.date)}, ${appointment.date.month}/${appointment.date.day}/${appointment.date.year}",
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatTime(appointment.date),
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    appointment.doctorName,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Page indicator dots
                  if (_appointments.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _appointments.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: _currentPage == index ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? Colors.deepPurple : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  Text(
                    "Appointment Details",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF323232),
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildDetailCard(
                    icon: Icons.location_on_rounded,
                    title: "Location",
                    content: _appointments[_currentPage].location,
                  ),

                  const SizedBox(height: 15),

                  _buildDetailCard(
                    icon: Icons.medical_services_rounded,
                    title: "Treatment Plan",
                    content: _appointments[_currentPage].treatmentPlan,
                  ),

                  const SizedBox(height: 15),

                  _buildDetailCard(
                    icon: Icons.history_rounded,
                    title: "Duration",
                    content: _appointments[_currentPage].duration,
                  ),

                  const SizedBox(height: 15),

                  // To Do Section
                  if (_appointments[_currentPage].toDo.isNotEmpty) ...[
                    Text(
                      "To Do",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF323232),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.task_alt_rounded,
                                  color: Colors.deepPurple,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "Tasks Assigned",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // List of To Do tasks
                          ..._appointments[_currentPage].toDo.map((task) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  FutureBuilder<double>(
                                    future: _getLevelProgress(task),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.deepPurple,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        );
                                      }
                                      final progress = snapshot.data!;
                                      return Icon(
                                        progress == 1.0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                                        color: progress == 1.0 ? Colors.green : Colors.red,
                                        size: 20,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showRescheduleDialog(context, _appointments[_currentPage]);
                          },
                          icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
                          label: Text(
                            "Reschedule",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF323232),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    switch (date.weekday) {
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      case 7: return "Sunday";
      default: return "";
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}

// Helper function to initialize sample appointments (for testing)
Future<void> initializeAppointments() async {
  final existingAppointments = await AppointmentService.getAppointments();

  // Only initialize if no appointments exist
  if (existingAppointments.isEmpty) {
    final sampleAppointments = [
      Appointment(
        id: '1',
        date: DateTime.now().add(const Duration(days: 2)),
        doctorName: 'Dr. Sarah Johnson',
        appointmentType: 'Speech Therapy',
        location: '123 Speech Therapy Center\n5th Floor, Suite 503\nNew York, NY 10001',
        treatmentPlan: "Articulation therapy focused on improving 'r' and 's' sounds production.",
        duration: '45 minutes',
        toDo: ['Complete Level 1', 'Complete Level 2'], // Add To Do tasks
      ),
      Appointment(
        id: '2',
        date: DateTime.now().add(const Duration(days: 7)),
        doctorName: 'Dr. Michael Chen',
        appointmentType: 'Follow-up Consultation',
        location: '123 Speech Therapy Center\n5th Floor, Suite 505\nNew York, NY 10001',
        treatmentPlan: 'Review progress and adjust exercises as needed.',
        duration: '30 minutes',
        toDo: ['Complete Level 3'], // Add To Do tasks
      ),
    ];

    await AppointmentService.saveAppointments(sampleAppointments);
  }
}