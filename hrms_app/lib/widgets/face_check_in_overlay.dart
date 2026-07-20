import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum _FaceStage { scanning, verifying, success }

/// Full-screen face check-in/out flow. SIMULATED for this phase — see
/// the Phase 3 plan's Global Constraints for why real `local_auth`
/// biometrics aren't wired in yet. Always "succeeds" after a short
/// timed sequence standing in for a real prompt.
class FaceCheckInOverlay extends StatefulWidget {
  final bool clockingIn;

  const FaceCheckInOverlay({super.key, required this.clockingIn});

  @override
  State<FaceCheckInOverlay> createState() => _FaceCheckInOverlayState();
}

class _FaceCheckInOverlayState extends State<FaceCheckInOverlay> {
  _FaceStage _stage = _FaceStage.scanning;

  @override
  void initState() {
    super.initState();
    _runSimulatedFlow();
  }

  Future<void> _runSimulatedFlow() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _stage = _FaceStage.verifying);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _stage = _FaceStage.success);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final verb = widget.clockingIn ? 'in' : 'out';
    final statusText = switch (_stage) {
      _FaceStage.scanning => 'Align your face within the frame',
      _FaceStage.verifying => 'Verifying your face…',
      _FaceStage.success => 'Identity verified',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Face Check-$verb',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Verify your identity to clock $verb',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 230,
                    height: 288,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _stage == _FaceStage.success
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : const Color(0xFF243247),
                      border: Border.all(
                        color: _stage == _FaceStage.success ? AppColors.primary : Colors.white24,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _stage == _FaceStage.scanning
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            _stage == _FaceStage.success
                                ? Icons.check_circle
                                : Icons.face_retouching_natural,
                            color: Colors.white,
                            size: 48,
                          ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: _stage == _FaceStage.success ? 15 : 13,
                      fontWeight: _stage == _FaceStage.success ? FontWeight.w700 : FontWeight.w400,
                      color: _stage == _FaceStage.success ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
