import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

// Imports from Milestone 2 and new auth screen
import 'services/firebase_service.dart';
import 'screens/auth/auth_screen.dart';
import 'models/user_profile.dart';

// Theme imports
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

// Imports for Milestone 4 screens
import 'screens/main_app/dashboard_screen.dart';
import 'screens/main_app/history_screen.dart';
import 'screens/main_app/add_expense_screen.dart';
import 'screens/main_app/budget_screen.dart';
import 'screens/main_app/summary_screen.dart';

// Sidebar and new screens
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/floating_sidebar.dart';

// Notification service
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully!");

    // Activate App Check after Firebase is initialized
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    debugPrint("Firebase App Check activated successfully!");

    // Initialize notification service
    debugPrint("Initializing notification service...");
    await NotificationService.initialize();
    debugPrint("Notification service initialized successfully!");
  } catch (e) {
    debugPrint(
      "Firebase initialization, App Check activation, or notification service initialization failed in main: $e",
    );
  }

  // Create the FirebaseService instance to be provided to the app
  final firebaseService = FirebaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => firebaseService),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Penni',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          onGenerateRoute: (settings) {
            if (settings.name == '/add-expense') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  transactionToEdit: args?['transaction'],
                  isEditing: args?['isEditing'] ?? false,
                ),
              );
            }
            if (settings.name == '/budget') {
              return MaterialPageRoute(
                builder: (context) => const BudgetScreen(),
              );
            }
            return null;
          },
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<User?>(
      stream: firebaseService.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Penni...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          // User is signed in
          return const MainAppScreen();
        } else {
          // User is not signed in, show auth screens
          return const AuthScreen();
        }
      },
    );
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isSidebarOpen = false;

  // Dynamic page titles that match the order of screens
  final List<String> _pageTitles = [
    'Dashboard',
    'Add Transaction',
    'History',
    'Summary',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _closeSidebar() {
    setState(() {
      _isSidebarOpen = false;
    });
  }

  void _navigateToProfile() {
    _closeSidebar();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToSettings() {
    _closeSidebar();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleSidebar,
        ),
        title: Text(
          _pageTitles[_selectedIndex],
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        actions: [
          Consumer<FirebaseService>(
            builder: (context, firebaseService, child) {
              return StreamBuilder<UserProfile?>(
                stream: firebaseService.getProfileStream(),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final user = firebaseService.auth.currentUser;
                  
                  return Container(
                    margin: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: profile?.hasProfileImage == true
                            ? NetworkImage(profile!.profileImageUrl!)
                            : null,
                        child: profile?.hasProfileImage == true
                            ? null
                            : Text(
                                profile?.initials ?? 
                                    (user?.displayName?.isNotEmpty == true
                                        ? user!.displayName![0].toUpperCase()
                                        : user?.email?.isNotEmpty == true
                                            ? user!.email![0].toUpperCase()
                                            : 'U'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              const DashboardScreen(),
              AddExpenseScreen(
                onTransactionAdded: () {
                  // Switch to History tab after transaction is added
                  _onItemTapped(2);
                },
              ),
              const HistoryScreen(),
              const SummaryScreen(),
            ],
          ),

          // Floating Sidebar
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _closeSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.4),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: _isSidebarOpen ? 16 : -300, // 16px margin from left edge
            top:
                MediaQuery.of(context).size.height *
                0.008, // Move higher up (8% from top)
            child: IgnorePointer(
              ignoring: !_isSidebarOpen,
              child: FloatingSidebar(
                onClose: _closeSidebar,
                onProfileTap: _navigateToProfile,
                onSettingsTap: _navigateToSettings,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Summary',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
