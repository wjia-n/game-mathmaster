import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/chalk_art.dart';
import '../theme/chalk_themes.dart';

/// Math Master PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final MathAudio audio;
  final MathSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ChalkThemeDef get _t => ChalkThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Chalk.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _IosGoldStarScreen(store: widget.store);
    }
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return ChalkBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Math Master PRO', style: Chalk.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                                    _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
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
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.


// ---------------------------------------------------------------------------
class _TipsCard extends StatelessWidget {
  final ChalkThemeDef theme;
  final StoreService store;
  final MathAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return BoardCard(
      theme: theme,
      child: Column(
        children: [
          Text('Tip the Maker', style: Chalk.display(20, theme: theme)),
          const SizedBox(height: 8),
          Text(
            'Math Master is free forever. A small tip keeps new games coming!',
            style: Chalk.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Chalk.body(13,
                  theme: theme, color: theme.chalkSoft),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: Chalk.body(13,
                    theme: theme, color: theme.chalkSoft))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  ChalkChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// iOS-only Gold Star screen: exactly one button, plus a badge once owned.
/// The game stays fully unlocked; the star is cosmetic only.
/// Android keeps the original screen below, byte-identical.
class _IosGoldStarScreen extends StatelessWidget {
  final StoreService store;
  const _IosGoldStarScreen({required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gold Star'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text(
                  'This game is fully unlocked.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: store.goldStarOwned,
                  builder: (_, owned, _) => Text(
                    owned
                        ? '⭐ Gold Star earned — thank you!'
                        : 'Get a Gold Star to show your support!',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                if (!store.storeReady)
                  Text(store.error ?? 'Available after store setup.',
                      textAlign: TextAlign.center)
                else if (store.starProduct == null)
                  const Text('Gold Star coming soon.',
                      textAlign: TextAlign.center)
                else
                  ValueListenableBuilder<bool>(
                    valueListenable: store.goldStarOwned,
                    builder: (_, owned, _) => owned
                        ? const Text('⭐', style: TextStyle(fontSize: 48))
                        : ElevatedButton(
                            onPressed: () =>
                                store.buyStar(store.starProduct!),
                            child: Text(
                                '⭐ Gold Star ${store.starProduct!.price}'),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
