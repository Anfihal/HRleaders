import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';

enum _GameStatus { ready, running, gameOver }

class CandidateFlagGame extends StatefulWidget {
  const CandidateFlagGame({super.key});

  @override
  State<CandidateFlagGame> createState() => _CandidateFlagGameState();
}

class _CandidateFlagGameState extends State<CandidateFlagGame>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _obstacle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addListener(_onGameTick);
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  final FocusNode _focusNode = FocusNode();
  _GameStatus _status = _GameStatus.ready;
  double _lastProgress = 0;
  int _score = 0;
  bool _resumeWhenActive = false;
  bool _obstacleScored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_resumeWhenActive && _status == _GameStatus.running) {
        _resumeWhenActive = false;
        _obstacle.repeat();
        if (_jump.value > 0 && _jump.value < 1) {
          _continueJump();
        }
      }
      return;
    }
    if (_status == _GameStatus.running && _obstacle.isAnimating) {
      _resumeWhenActive = true;
      _obstacle.stop();
      _jump.stop();
    }
  }

  void _start() {
    _focusNode.requestFocus();
    setState(() {
      _status = _GameStatus.running;
      _score = 0;
      _lastProgress = 0;
      _obstacleScored = false;
      _resumeWhenActive = false;
    });
    _jump.reset();
    _obstacle
      ..reset()
      ..repeat();
  }

  void _jumpNow() {
    _focusNode.requestFocus();
    if (_status == _GameStatus.ready || _status == _GameStatus.gameOver) {
      _start();
      return;
    }
    if (!_jump.isAnimating) {
      _jump.reset();
      _continueJump();
    }
  }

  void _continueJump() {
    _jump.forward().then((_) {
      if (mounted && _status == _GameStatus.running) _jump.reverse();
    });
  }

  void _onGameTick() {
    if (_status != _GameStatus.running) return;
    final progress = _obstacle.value;
    final completedLap = _lastProgress > .85 && progress < .15;
    if (completedLap) _obstacleScored = false;
    _lastProgress = progress;

    final flagX = 1.08 - progress * 1.25;
    if (flagX >= .14 && flagX <= .25 && _jump.value < .2) {
      _obstacle.stop();
      _jump.stop();
      setState(() {
        _status = _GameStatus.gameOver;
        _resumeWhenActive = false;
      });
    } else if (flagX < .14 && !_obstacleScored) {
      _obstacleScored = true;
      setState(() => _score++);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      _jumpNow();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _obstacle
      ..removeListener(_onGameTick)
      ..dispose();
    _jump.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = s.Theme.of(context).colorScheme;
    final instruction = switch (_status) {
      _GameStatus.ready => context.l.gameInstructions,
      _GameStatus.running => context.l.gameJumpHelp,
      _GameStatus.gameOver => context.l.gameOver,
    };
    return Semantics(
      container: true,
      label: instruction,
      child: s.Card(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(m.Icons.sports_esports, size: 20),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    context.l.candidateGameTitle,
                    style: AppTypography.heading(context, size: 16),
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  label: '${context.l.gameScore}: $_score',
                  child: ExcludeSemantics(
                    child: Text('${context.l.gameScore}: $_score'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              instruction,
              style: _status == _GameStatus.gameOver
                  ? TextStyle(color: colors.destructive)
                  : null,
            ),
            const SizedBox(height: AppSpacing.small),
            Focus(
              focusNode: _focusNode,
              onKeyEvent: _onKeyEvent,
              child: Semantics(
                button: true,
                label: instruction,
                onTap: _jumpNow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _jumpNow,
                  child: SizedBox(
                    height: 108,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_obstacle, _jump]),
                      builder: (context, _) => CustomPaint(
                        painter: _FlagGamePainter(
                          obstacleProgress: _status == _GameStatus.running
                              ? _obstacle.value
                              : 0,
                          jumpProgress: _jump.value,
                          status: _status,
                          background: colors.muted.withValues(alpha: .22),
                          ground: colors.border,
                          candidate: AppColors.brand,
                          flag: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            AppButton(
              label: switch (_status) {
                _GameStatus.ready => context.l.gameStart,
                _GameStatus.running => context.l.gameJump,
                _GameStatus.gameOver => context.l.gameRestart,
              },
              icon: switch (_status) {
                _GameStatus.ready => m.Icons.play_arrow,
                _GameStatus.running => m.Icons.arrow_upward,
                _GameStatus.gameOver => m.Icons.replay,
              },
              secondary: _status == _GameStatus.running,
              onPressed: _status == _GameStatus.running ? _jumpNow : _start,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagGamePainter extends CustomPainter {
  const _FlagGamePainter({
    required this.obstacleProgress,
    required this.jumpProgress,
    required this.status,
    required this.background,
    required this.ground,
    required this.candidate,
    required this.flag,
  });

  final double obstacleProgress;
  final double jumpProgress;
  final _GameStatus status;
  final Color background;
  final Color ground;
  final Color candidate;
  final Color flag;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(AppRadii.card)),
      Paint()..color = background,
    );
    final groundY = size.height * .82;
    canvas.drawLine(
      Offset(size.width * .04, groundY),
      Offset(size.width * .96, groundY),
      Paint()
        ..color = ground
        ..strokeWidth = 2,
    );

    final jumpHeight =
        4 * jumpProgress * (1 - jumpProgress) * size.height * .42;
    _drawCandidate(
      canvas,
      Offset(size.width * .19, groundY - jumpHeight),
      size.height * .25,
      candidate,
    );

    if (status == _GameStatus.running || status == _GameStatus.gameOver) {
      final progress = status == _GameStatus.running ? obstacleProgress : .70;
      final flagX = size.width * (1.08 - progress * 1.25);
      _drawFlag(canvas, flagX, groundY, size.height * .68, flag);
    } else {
      _drawFlag(canvas, size.width * .77, groundY, size.height * .68, flag);
    }
  }

  void _drawCandidate(Canvas canvas, Offset foot, double scale, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(foot.translate(0, -scale * 1.55), scale * .28, paint);
    canvas.drawLine(
      foot.translate(0, -scale * 1.22),
      foot.translate(0, -scale * .56),
      paint..strokeWidth = scale * .36,
    );
    canvas.drawLine(
      foot.translate(0, -scale * 1.05),
      foot.translate(scale * .48, -scale * .76),
      paint..strokeWidth = scale * .18,
    );
    canvas.drawLine(
      foot.translate(0, -scale * 1.04),
      foot.translate(-scale * .40, -scale * .72),
      paint,
    );
    canvas.drawLine(
      foot.translate(0, -scale * .58),
      foot.translate(-scale * .30, 0),
      paint..strokeWidth = scale * .20,
    );
    canvas.drawLine(
      foot.translate(0, -scale * .58),
      foot.translate(scale * .32, 0),
      paint,
    );
  }

  void _drawFlag(
    Canvas canvas,
    double x,
    double groundY,
    double height,
    Color color,
  ) {
    final pole = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, groundY), Offset(x, groundY - height), pole);
    final cloth = Path()
      ..moveTo(x + 1, groundY - height + 2)
      ..lineTo(x + height * .48, groundY - height + height * .18)
      ..lineTo(x + 1, groundY - height + height * .34)
      ..close();
    canvas.drawPath(cloth, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlagGamePainter oldDelegate) =>
      oldDelegate.obstacleProgress != obstacleProgress ||
      oldDelegate.jumpProgress != jumpProgress ||
      oldDelegate.status != status ||
      oldDelegate.background != background ||
      oldDelegate.ground != ground ||
      oldDelegate.candidate != candidate ||
      oldDelegate.flag != flag;
}
