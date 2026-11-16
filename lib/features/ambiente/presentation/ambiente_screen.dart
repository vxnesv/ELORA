import 'package:material_ui/material_ui.dart';

import '../../../core/presentation/tema_elora.dart';
import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/abrir_externo.dart';
import '../../protecao/presentation/protecao_screen.dart';

class AmbienteScreen extends StatelessWidget {
  const AmbienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meu ambiente')),
      body: ColunaConteudo(
        children: [
          const CabecalhoPagina(
            icon: Icons.eco_outlined,
            title: 'Meu ambiente',
            subtitle: 'Entenda fatores externos e prepare-se com calma.',
          ),
          const AvisoDiscreto(
            icon: Icons.science_outlined,
            text:
                'A integração climática ainda não fornece alertas oficiais. Consulte sempre a Defesa Civil da sua região.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.heroStart, colors.heroEnd],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Contexto ambiental',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Prepare-se para calor e chuvas intensas',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acompanhe fontes oficiais antes de tomar decisões.',
                  style: TextStyle(color: Color(0xFFFFE5D4), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const CabecalhoSecao(title: 'O que você pode fazer'),
          ItemAcao(
            icon: Icons.wb_sunny_outlined,
            title: 'Entender o calor intenso',
            subtitle: 'Cuidados educativos e fonte do Ministério da Saúde.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GuiaScreen(guide: guides[0]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ItemAcao(
            icon: Icons.water_outlined,
            title: 'Preparar-se para enchentes',
            subtitle: 'Orientações para evitar áreas alagadas.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GuiaScreen(guide: guides[1]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CabecalhoSecao(title: 'Alertas oficiais'),
          CartaoElora(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cadastre seu CEP na Defesa Civil',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'A Defesa Civil Nacional informa que é possível receber avisos por SMS enviando o CEP para 40199. Confira as instruções e a disponibilidade nos canais oficiais.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => abrirLinkExterno(
                    context,
                    'https://www.gov.br/mdr/pt-br/assuntos/protecao-e-defesa-civil/alertas-de-desastres-1',
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Abrir Defesa Civil Nacional'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
