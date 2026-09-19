// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUserModel? _currentUser;
  bool _loading = false;
  String? _error;

  AppUserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // ── تسجيل الدخول بالإيميل ───────────────────────────
  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadOrCreateUser(cred.user!);
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _arabicError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'حدث خطأ غير متوقع';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── إنشاء حساب جديد بالإيميل ────────────────────────
  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // تحديث الاسم في Firebase Auth
      await cred.user!.updateDisplayName(name);

      final newUser = AppUserModel(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: 'employee', // الحساب الجديد موظف بشكل افتراضي
      );
      await FirestoreService.saveUser(newUser);
      _currentUser = newUser;
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _arabicError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'حدث خطأ غير متوقع';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── تسجيل الدخول بجوجل ──────────────────────────────
  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // فتح نافذة اختيار حساب جوجل
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // المستخدم أغلق النافذة
        _loading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      await _loadOrCreateUser(cred.user!);

      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _arabicError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'فشل تسجيل الدخول بجوجل';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── تسجيل الخروج ────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── التحقق من الجلسة عند فتح التطبيق ───────────────
  Future<void> checkCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUser = await FirestoreService.getUser(user.uid);
      // إذا لم يكن موجوداً في Firestore أنشئ له سجلاً
      if (_currentUser == null) {
        await _loadOrCreateUser(user);
      }
      notifyListeners();
    }
  }

  // ── مساعد: تحميل أو إنشاء مستخدم ───────────────────
  Future<void> _loadOrCreateUser(User firebaseUser) async {
    _currentUser = await FirestoreService.getUser(firebaseUser.uid);
    if (_currentUser == null) {
      final name = firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'مستخدم';
      _currentUser = AppUserModel(
        uid: firebaseUser.uid,
        name: name,
        email: firebaseUser.email ?? '',
        role: 'employee',
      );
      await FirestoreService.saveUser(_currentUser!);
    }
  }

  // ── ترجمة أكواد الخطأ ───────────────────────────────
  String _arabicError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'weak-password':
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return 'تحقق من الاتصال بالإنترنت';
      default:
        return 'حدث خطأ، حاول مرة أخرى';
    }
  }
}
