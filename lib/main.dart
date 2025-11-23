import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'screens/email_otp_verification_screen.dart';
import 'utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/cache_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/record_repository.dart';
import 'services/record_service.dart';
import 'services/notification_service.dart';
import 'repositories/doctor_repository.dart';
import 'services/booking_service.dart';
import 'repositories/booking_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/review_repository.dart';
import 'services/stream_service.dart';
import 'repositories/conversation_repository.dart';
import 'repositories/message_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Create singleton instances of services
  final cacheService = CacheService();
  await cacheService.init();
  final notificationService = NotificationService();
  await notificationService.init();
  final streamService = StreamService(cacheService);
  final notificationRepository =
      NotificationRepository(notificationService, streamService, cacheService);
  final dbService = DatabaseService(cacheService);
  final userRepository = UserRepository(dbService, cacheService, streamService);
  final recordService = RecordService();
  final recordRepository =
      RecordRepository(recordService, cacheService, streamService);
  final doctorRepository =
      DoctorRepository(dbService, cacheService, streamService);
  final bookingService = BookingService();
  final bookingRepository =
      BookingRepository(bookingService, cacheService, streamService);
  final reviewRepository =
      ReviewRepository(dbService, cacheService, streamService);

  final authService =
      AuthService(FirebaseAuth.instance, dbService, cacheService);
  final conversationRepository =
      ConversationRepository(cacheService, streamService);
  final messageRepository = MessageRepository(cacheService, streamService);

  runApp(MyApp(
    authService: authService,
    cacheService: cacheService,
    notificationService: notificationService,
    notificationRepository: notificationRepository,
    userRepository: userRepository,
    databaseService: dbService,
    recordRepository: recordRepository,
    doctorRepository: doctorRepository,
    bookingRepository: bookingRepository,
    reviewRepository: reviewRepository,
    conversationRepository: conversationRepository,
    messageRepository: messageRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final CacheService cacheService;
  final NotificationService notificationService;
  final NotificationRepository notificationRepository;
  final UserRepository userRepository;
  final DatabaseService databaseService;
  final RecordRepository recordRepository;
  final DoctorRepository doctorRepository;
  final BookingRepository bookingRepository;
  final ReviewRepository reviewRepository;
  final ConversationRepository conversationRepository;
  final MessageRepository messageRepository;

  const MyApp({
    super.key,
    required this.authService,
    required this.cacheService,
    required this.notificationService,
    required this.notificationRepository,
    required this.userRepository,
    required this.databaseService,
    required this.recordRepository,
    required this.doctorRepository,
    required this.bookingRepository,
    required this.reviewRepository,
    required this.conversationRepository,
    required this.messageRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // 2. Provide the singleton instances to the widget tree
        Provider<AuthService>.value(value: authService),
        Provider<CacheService>.value(value: cacheService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<NotificationRepository>.value(value: notificationRepository),
        Provider<UserRepository>.value(value: userRepository),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<RecordRepository>.value(value: recordRepository),
        Provider<DoctorRepository>.value(value: doctorRepository),
        Provider<BookingRepository>.value(value: bookingRepository),
        Provider<ReviewRepository>.value(value: reviewRepository),
        Provider<ConversationRepository>.value(value: conversationRepository),
        Provider<MessageRepository>.value(value: messageRepository),
        StreamProvider<User?>(
          create: (context) => authService.authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'DermAI',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode
            .light, // I will add darkmode soon once colors are finalized
        debugShowCheckedModeBanner: false,
        // home: const OtpVerificationScreen(
        //   verificationId: 'dummy-verification-id',
        //   phoneNumber: '+639123456789',
        // ), // Changed for UI preview
        home: const AuthWrapper(), 
        routes: {
          '/auth': (context) => const AuthScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();
    final cacheService = context.read<CacheService>();

    if (firebaseUser != null) {
      return OtpVerificationHandler(
        firebaseUser: firebaseUser,
        child: const MainScreen(),
      );
    }

    // Offline check
    if (cacheService.isLoggedIn()) {
      return const MainScreen();
    }

    return const AuthScreen();
  }


}

class OtpVerificationHandler extends StatefulWidget {
  final User firebaseUser;
  final Widget child;

  OtpVerificationHandler({
    super.key,
    required this.firebaseUser,
    required this.child,
  });

  @override
  State<OtpVerificationHandler> createState() =>
      _OtpVerificationHandlerState();
}

class _OtpVerificationHandlerState extends State<OtpVerificationHandler> {
  bool _isOtpVerified = false;

  @override
  void initState() {
    super.initState();
    _checkOtpVerification();
  }

  @override
  void didUpdateWidget(covariant OtpVerificationHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firebaseUser.uid != oldWidget.firebaseUser.uid) {
      _checkOtpVerification();
    }
  }

  Future<void> _checkOtpVerification() async {
    final databaseService = context.read<DatabaseService>();
    final userDoc = await databaseService.getUserData(widget.firebaseUser.uid);
    if (userDoc.exists) {
      _isOtpVerified = (userDoc.data() as Map<String, dynamic>)['isEmailVerified'] ?? false;
    } else {
      _isOtpVerified = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isOtpVerified) {
      return widget.child;
    } else {
      return EmailOtpVerificationScreen(
        email: widget.firebaseUser.email!,
        onVerified: () async {
          await context.read<AuthService>().updateUserVerificationStatus(widget.firebaseUser.uid);
          _isOtpVerified = true;
          setState(() {});
        },
      );
    }
  }
}
