import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'state/auth_scope.dart';
import 'state/auth_state.dart';
import 'state/expense_scope.dart';
import 'state/expense_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with DefaultFirebaseOptions for configured platforms (Android / iOS)
  try {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final storageService = StorageService();
  await storageService.init();

  final expenseState = ExpenseState(storageService);
  await expenseState.init();

  final authService = AuthService();
  final authState = AuthState(authService);

  // Automatically keep expenseState synchronized with current authenticated user
  void syncUserWithExpenseState() {
    final user = authState.user;
    expenseState.setUserId(
      user?.uid,
      email: user?.email,
      displayName: user?.displayName,
    );
  }

  authState.addListener(syncUserWithExpenseState);
  syncUserWithExpenseState();

  runApp(ExpenseTrackerApp(
    expenseState: expenseState,
    authState: authState,
  ));
}

class ExpenseTrackerApp extends StatelessWidget {
  final ExpenseState expenseState;
  final AuthState authState;

  const ExpenseTrackerApp({
    super.key,
    required this.expenseState,
    required this.authState,
  });

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authState: authState,
      child: ExpenseScope(
        state: expenseState,
        child: ListenableBuilder(
          listenable: Listenable.merge([expenseState, authState]),
          builder: (context, _) {
            return MaterialApp(
              title: 'IMREXPENSE - Personal Expense Tracker',
              debugShowCheckedModeBanner: false,
              themeMode: expenseState.themeMode,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    // Show smooth loader while Firebase and auth state are initializing
    if (!auth.isInitialized) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 50 : 30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    // If authenticated or user explicitly chose Guest / Offline mode, show main app
    if (auth.isAuthenticated || auth.isGuestMode) {
      return const MainScaffold();
    }

    // Default for first-time launch: Show Login / Sign Up screen
    return AuthScreen(authState: auth);
  }
}
