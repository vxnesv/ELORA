import 'package:material_ui/material_ui.dart';

import 'core/data/elora_store.dart';
import 'core/presentation/tema_elora.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/assistente/presentation/assistente_screen.dart';
import 'features/cuidado/presentation/cuidado_screen.dart';
import 'features/ambiente/presentation/ambiente_screen.dart';
import 'features/inicio/presentation/inicio_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/protecao/presentation/protecao_screen.dart';
import 'features/relatorios/presentation/relatorios_screen.dart';
import 'features/trabalho/presentation/trabalho_screen.dart';

class EloraApp extends StatelessWidget {
  const EloraApp({super.key, required this.store});

  final EloraStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => MaterialApp(
      title: 'ELORA',
      debugShowCheckedModeBanner: false,
      theme: TemaElora.light,
      darkTheme: TemaElora.dark,
      themeMode: switch (store.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(store.textoAmpliado ? 1.16 : 1),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(store: store),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final EloraStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    final pages = [
      InicioScreen(
        store: widget.store,
        onNavigate: (index) => setState(() => selectedIndex = index),
        onAssistente: () => _open(AssistenteScreen(store: widget.store)),
        onTrabalho: () => _open(TrabalhoScreen(store: widget.store)),
        onAmbiente: () => _open(const AmbienteScreen()),
      ),
      CuidadoScreen(store: widget.store),
      ProtecaoScreen(store: widget.store),
      ProfileScreen(store: widget.store),
      RelatoriosScreen(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      floatingActionButton: selectedIndex == 0
          ? null
          : FloatingActionButton.small(
              tooltip: 'Conversar com a ELORA',
              backgroundColor: colors.accent,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => _open(AssistenteScreen(store: widget.store)),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        backgroundColor: colors.surface,
        indicatorColor: colors.accentSoft,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Cuidado',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Proteção',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}
