import 'package:riverpod/riverpod.dart';
import '../services/auth_service.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider to check if PIN is set
final isPinSetProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isPinSet();
});
