import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/elora_store.dart';
import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/dialogo_texto.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});

  final EloraStore store;

  Future<void> _editName(BuildContext context) async {
    final value = await mostrarDialogoTexto(
      context,
      title: 'Nome de exibição',
      label: 'Como podemos chamar você?',
      initialValue: store.name == 'Visitante' ? '' : store.name,
      maxLength: 32,
    );
    if (value != null && value.trim().isNotEmpty) {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(value.trim());
      store.definirNome(value);
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar dados locais?'),
        content: const Text(
          'Isso remove registros, metas, checklist, anotações e preferências deste dispositivo. A ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar dados'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.apagarDados();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return ColunaConteudo(
      children: [
        const CabecalhoPagina(
          icon: Icons.person_outline_rounded,
          title: 'Perfil e preferências',
          subtitle: 'Ajuste sua experiência na ELORA.',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.heroStart, colors.heroEnd],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const LogoCircular(size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'Conta ELORA',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFE9D9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar nome',
                onPressed: () => _editName(context),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Aparência'),
        CartaoElora(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tema', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('Sistema')),
                  ButtonSegment(value: 'light', label: Text('Claro')),
                  ButtonSegment(value: 'dark', label: Text('Escuro')),
                ],
                selected: {store.theme},
                onSelectionChanged: (value) => store.definirTema(value.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Texto maior'),
                subtitle: const Text('Amplia textos em todas as telas.'),
                value: store.textoAmpliado,
                onChanged: store.definirTextoAmpliado,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CabecalhoSecao(title: 'Conta e dados'),
        const AvisoDiscreto(
          icon: Icons.lock_outline_rounded,
          text:
              'Sua conta é autenticada pelo Firebase. A ELORA não realiza diagnóstico e você permanece no controle das informações registradas.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _clear(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Apagar dados locais'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: FirebaseAuth.instance.signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
        ),
      ],
    );
  }
}
