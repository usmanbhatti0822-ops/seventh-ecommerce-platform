import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/config/app_config.dart";
import "../../../../core/network/api_result.dart";
import "../providers/auth_provider.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 9) {
      setState(() => _error = "Enter a valid phone number");
      return;
    }
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.requestOtp("+92${_phoneController.text.trim()}");
    setState(() {
      _loading = false;
      switch (result) {
        case ApiSuccess():
          _otpSent = true;
        case ApiFailure(message: final msg):
          _error = msg;
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyOtp("+92${_phoneController.text.trim()}", _otpController.text.trim());
    setState(() => _loading = false);
    switch (result) {
      case ApiSuccess():
        ref.invalidate(isLoggedInProvider);
        if (mounted) context.go("/");
      case ApiFailure(message: final msg):
        setState(() => _error = msg);
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.socialLogin(provider, "demo-id-token");
    setState(() => _loading = false);
    switch (result) {
      case ApiSuccess():
        ref.invalidate(isLoggedInProvider);
        if (mounted) context.go("/");
      case ApiFailure(message: final msg):
        setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("SEVENTH", style: displayFont(fontSize: 30, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text("Sign in to continue shopping the drop.", style: bodyFont(fontSize: 14, color: AppColors.inkSoft)),
              const SizedBox(height: 36),
              AnimatedSwitcher(
                duration: AppDurations.medium,
                child: _otpSent
                    ? Column(
                        key: const ValueKey("otp"),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ENTER OTP", style: eyebrowFont()),
                          const SizedBox(height: 4),
                          Text("Sent to +92${_phoneController.text.trim()}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: bodyFont(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(hintText: "1234"),
                          ),
                          if (AppConfig.demoMode) ...[
                            const SizedBox(height: 8),
                            Text("Demo mode — use code 1234", style: bodyFont(fontSize: 11.5, color: AppColors.olive, fontWeight: FontWeight.w600)),
                          ],
                          TextButton(
                            onPressed: () => setState(() { _otpSent = false; _error = null; }),
                            child: const Text("Change number"),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey("phone"),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PHONE NUMBER", style: eyebrowFont()),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: bodyFont(fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(prefixText: "+92 ", hintText: "3XX XXXXXXX"),
                          ),
                        ],
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: bodyFont(fontSize: 13, color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_otpSent ? "VERIFY & CONTINUE" : "SEND OTP"),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.line)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("OR", style: eyebrowFont())),
                  Expanded(child: Divider(color: AppColors.line)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _socialLogin("google"),
                      icon: const Icon(Icons.g_mobiledata, size: 22),
                      label: const Text("Google"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _socialLogin("apple"),
                      icon: const Icon(Icons.apple, size: 18),
                      label: const Text("Apple"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go("/"),
                  child: Text("Continue as Guest", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
