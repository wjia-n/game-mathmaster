import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/chalk_art.dart';
import 'theme/chalk_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = MathSettings();
  await settings.load();
  final audio = MathAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(MathMasterApp(settings: settings, audio: audio));
}

class MathMasterApp extends StatefulWidget {
  final MathSettings settings;
  final MathAudio audio;
  const MathMasterApp({super.key, required this.settings, required this.audio});

  @override
  State<MathMasterApp> createState() => _MathMasterAppState();
}

class _MathMasterAppState extends State<MathMasterApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = ChalkThemes.byId(
          widget.settings.themeId,
          custom: widget.settings.customTheme,
        );
        return ChalkBackdrop(
          theme: theme,
          child: MaterialApp(
            title: 'Math Master',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.transparent,
              colorScheme: ColorScheme.dark(
                primary: theme.accent,
                surface: theme.board,
                onSurface: theme.chalk,
              ),
            ),
            home: SplashScreen(
                audio: widget.audio, settings: widget.settings),
          ),
        );
      },
    );
  }
}
