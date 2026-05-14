import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // obrigatório antes do SystemChrome

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation
        .portraitDown, // opcional: permite retrato de cabeça pra baixo
  ]);

  runApp(const JurosCompostosApp());
}

class JurosCompostosApp extends StatelessWidget {
  const JurosCompostosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juros Compostos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5A0),
          brightness: Brightness.dark,
          primary: const Color(0xFF00E5A0),
          surface: const Color(0xFF0D1117),
          onSurface: Colors.white,
        ),
        fontFamily: 'monospace',
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const CalculadoraPage(),
    );
  }
}

// ── Modelo de resultado ──────────────────────────────────────────────────────

class ResultadoCalculo {
  final double valorFinal;
  final double totalInvestido;
  final double totalJuros;
  final List<PontoGrafico> historico;

  ResultadoCalculo({
    required this.valorFinal,
    required this.totalInvestido,
    required this.totalJuros,
    required this.historico,
  });
}

class PontoGrafico {
  final int periodo;
  final double valorAcumulado;
  final double totalInvestido;

  PontoGrafico(this.periodo, this.valorAcumulado, this.totalInvestido);
}

// ── Funções de cálculo ───────────────────────────────────────────────────────

ResultadoCalculo calcular({
  required double valorInicial,
  required double valorMensal,
  required double taxa,
  required int periodoMeses,
}) {
  final List<PontoGrafico> historico = [];
  double saldo = valorInicial;
  double totalInvestido = valorInicial;

  historico.add(PontoGrafico(0, saldo, totalInvestido));

  for (int mes = 1; mes <= periodoMeses; mes++) {
    saldo = saldo * (1 + taxa) + valorMensal;
    totalInvestido += valorMensal;
    historico.add(PontoGrafico(mes, saldo, totalInvestido));
  }

  return ResultadoCalculo(
    valorFinal: saldo,
    totalInvestido: totalInvestido,
    totalJuros: saldo - totalInvestido,
    historico: historico,
  );
}

// ── Formatação ───────────────────────────────────────────────────────────────

String formatarMoeda(double valor) {
  if (valor >= 1e9) {
    return 'R\$ ${(valor / 1e9).toFixedWithComma()} bi';
  } else if (valor >= 1e6) {
    return 'R\$ ${(valor / 1e6).toFixedWithComma()} mi';
  }
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0];
  final decimal = partes[1];
  final buffer = StringBuffer();
  int count = 0;
  for (int i = inteiro.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
    count++;
  }
  final resultado = buffer.toString().split('').reversed.join('');
  return 'R\$ $resultado,$decimal';
}

// ── Página principal ─────────────────────────────────────────────────────────

class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({super.key});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _valorInicialCtrl = TextEditingController();
  final _valorMensalCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _periodoCtrl = TextEditingController();

  bool _taxaAnual = false;
  bool _periodoAnos = false;

  ResultadoCalculo? _resultado;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _verde = Color(0xFF00E5A0);
  static const _azul = Color(0xFF3B82F6);
  static const _laranja = Color(0xFFFF6B35);
  static const _superficie = Color(0xFF161B22);
  static const _bordas = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _valorInicialCtrl.dispose();
    _valorMensalCtrl.dispose();
    _taxaCtrl.dispose();
    _periodoCtrl.dispose();
    super.dispose();
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final valorInicial = _parseMoeda(_valorInicialCtrl.text);
    final valorMensal = _parseMoeda(_valorMensalCtrl.text);
    double taxa = double.parse(_taxaCtrl.text.replaceAll(',', '.')) / 100;
    int periodo = int.parse(_periodoCtrl.text);

    if (_taxaAnual) {
      taxa = pow(1 + taxa, 1 / 12).toDouble() - 1;
    }
    if (_periodoAnos) {
      periodo = periodo * 12;
    }

    setState(() {
      _resultado = calcular(
        valorInicial: valorInicial,
        valorMensal: valorMensal,
        taxa: taxa,
        periodoMeses: periodo,
      );
    });

    _animCtrl.forward(from: 0);
  }

  double _parseMoeda(String text) {
    final limpo = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF0D1117),
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _verde.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _verde.withOpacity(0.4)),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: _verde,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Juros Compostos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('APORTES'),
                              const SizedBox(height: 14),
                              _buildCampoMoeda(
                                controller: _valorInicialCtrl,
                                label: 'Valor Inicial',
                                hint: '0,00',
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildCampoMoeda(
                                controller: _valorMensalCtrl,
                                label: 'Aporte Mensal',
                                hint: '0,00',
                                icon: Icons.add_circle_outline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('TAXA & PERÍODO'),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCampoNumerico(
                                      controller: _taxaCtrl,
                                      label: 'Taxa de Juros',
                                      hint: '0,00',
                                      suffix: '%',
                                      icon: Icons.percent,
                                      decimal: true,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildToggle(
                                    opcoes: const ['Mês', 'Ano'],
                                    selecionado: _taxaAnual ? 1 : 0,
                                    onChanged: (i) =>
                                        setState(() => _taxaAnual = i == 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCampoNumerico(
                                      controller: _periodoCtrl,
                                      label: 'Período',
                                      hint: '0',
                                      suffix: _periodoAnos ? 'anos' : 'meses',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildToggle(
                                    opcoes: const ['Meses', 'Anos'],
                                    selecionado: _periodoAnos ? 1 : 0,
                                    onChanged: (i) =>
                                        setState(() => _periodoAnos = i == 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _calcular,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _verde,
                              foregroundColor: const Color(0xFF0D1117),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'CALCULAR',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_resultado != null) ...[
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildResultados(_resultado!),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildGrafico(_resultado!),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildEvolucaoTabela(_resultado!),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets de entrada ───────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bordas),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white.withOpacity(0.35),
      ),
    );
  }

  Widget _buildCampoMoeda({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        prefix: 'R\$ ',
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo obrigatório';
        return null;
      },
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[\d.,]') : RegExp(r'\d'),
        ),
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffix: suffix,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Obrigatório';
        final n = double.tryParse(v.replaceAll(',', '.'));
        if (n == null || n <= 0) return 'Valor inválido';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      suffixText: suffix,
      prefixIcon: Icon(icon, size: 18, color: Colors.white38),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
      suffixStyle: TextStyle(
        color: _verde.withOpacity(0.8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _bordas),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _bordas),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _verde, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _laranja.withOpacity(0.7)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _laranja),
      ),
      errorStyle: const TextStyle(fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildToggle({
    required List<String> opcoes,
    required int selecionado,
    required void Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordas),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(opcoes.length, (i) {
          final ativo = i == selecionado;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: ativo ? _verde.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: ativo
                    ? Border.all(color: _verde.withOpacity(0.5))
                    : null,
              ),
              child: Text(
                opcoes[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                  color: ativo ? _verde : Colors.white38,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Widgets de resultado ─────────────────────────────────────────────────

  Widget _buildResultados(ResultadoCalculo r) {
    final pct = r.totalInvestido > 0
        ? (r.totalJuros / r.totalInvestido * 100)
        : 0.0;

    return Column(
      children: [
        // Card principal — valor final
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_verde.withOpacity(0.12), _azul.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _verde.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VALOR FINAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _verde.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatarMoeda(r.valorFinal),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${pct.toFixedWithComma(1)}% sobre o total investido',
                style: TextStyle(
                  fontSize: 12,
                  color: _verde,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCardMetrica(
                label: 'Total Investido',
                valor: formatarMoeda(r.totalInvestido),
                cor: _azul,
                icone: Icons.savings_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCardMetrica(
                label: 'Rendimento',
                valor: formatarMoeda(r.totalJuros),
                cor: _verde,
                icone: Icons.auto_graph,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Barra de proporção
        _buildCardProporcao(r),
      ],
    );
  }

  Widget _buildCardMetrica({
    required String label,
    required String valor,
    required Color cor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordas),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 14, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardProporcao(ResultadoCalculo r) {
    final propInvestido = r.totalInvestido / r.valorFinal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordas),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPOSIÇÃO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return Row(
                    children: [
                      Container(
                        width: constraints.maxWidth * propInvestido,
                        color: _azul,
                      ),
                      Expanded(child: Container(color: _verde)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendaItem(
                _azul,
                'Investido',
                '${(propInvestido * 100).toFixedWithComma(1)}%',
              ),
              _legendaItem(
                _verde,
                'Rendimento',
                '${((1 - propInvestido) * 100).toFixedWithComma(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendaItem(Color cor, String label, String valor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
        const SizedBox(width: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Gráfico simples ──────────────────────────────────────────────────────

  Widget _buildGrafico(ResultadoCalculo r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bordas),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EVOLUÇÃO PATRIMONIAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _GraficoPainter(
                historico: r.historico,
                corTotal: _verde,
                corInvestido: _azul,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendaItem(_verde, 'Patrimônio', ''),
              const SizedBox(width: 20),
              _legendaItem(_azul, 'Investido', ''),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabela de evolução ───────────────────────────────────────────────────

  Widget _buildEvolucaoTabela(ResultadoCalculo r) {
    // Mostrar marcos: início, 25%, 50%, 75%, fim + anos inteiros se curto
    final total = r.historico.length - 1;
    final pontos = <PontoGrafico>[];

    if (total <= 24) {
      pontos.addAll(r.historico);
    } else {
      // Mostrar a cada 12 meses
      for (int i = 0; i <= total; i += 12) {
        pontos.add(r.historico[i]);
      }
      if (pontos.last.periodo != total) {
        pontos.add(r.historico[total]);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bordas),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'TABELA DE EVOLUÇÃO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
          // Cabeçalho
          Container(
            color: Colors.white.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _thCell('Período', flex: 2),
                _thCell('Investido', flex: 3),
                _thCell('Rendimento', flex: 3),
                _thCell('Total', flex: 3),
              ],
            ),
          ),
          ...pontos.map((p) {
            final juros = p.valorAcumulado - p.totalInvestido;
            final isLast = p == pontos.last;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isLast
                        ? Colors.transparent
                        : _bordas.withOpacity(0.5),
                  ),
                ),
                color: isLast ? _verde.withOpacity(0.06) : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatPeriodo(p.periodo),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLast ? _verde : Colors.white54,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatCurto(p.totalInvestido),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLast
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatCurto(juros),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLast ? _verde : _verde.withOpacity(0.6),
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatCurto(p.valorAcumulado),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLast ? Colors.white : Colors.white70,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _thCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  String _formatPeriodo(int meses) {
    if (meses == 0) return 'Início';
    if (meses % 12 == 0) return '${meses ~/ 12}a';
    return '${meses}m';
  }

  String _formatCurto(double v) {
    if (v >= 1e9) {
      // return 'R\$
      return '${(v / 1e9).toFixedWithComma(1)} bi';
    }
    if (v >= 1e6) {
      return '${(v / 1e6).toFixedWithComma(1)} mi';
    }
    if (v >= 1e3) {
      return '${(v / 1e3).toFixedWithComma(1)} k';
    }
    return v.toFixedWithComma(0);
  }
}

// ── Painter do gráfico ───────────────────────────────────────────────────────

class _GraficoPainter extends CustomPainter {
  final List<PontoGrafico> historico;
  final Color corTotal;
  final Color corInvestido;

  _GraficoPainter({
    required this.historico,
    required this.corTotal,
    required this.corInvestido,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (historico.isEmpty) return;

    final maxVal = historico.last.valorAcumulado;
    final n = historico.length;

    double xOf(int i) => size.width * i / (n - 1);
    double yOf(double v) => size.height - (size.height * v / maxVal);

    // Fill total
    final fillTotal = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [corTotal.withOpacity(0.25), corTotal.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathFill = Path();
    pathFill.moveTo(0, size.height);
    for (int i = 0; i < n; i++) {
      pathFill.lineTo(xOf(i), yOf(historico[i].valorAcumulado));
    }
    pathFill.lineTo(size.width, size.height);
    pathFill.close();
    canvas.drawPath(pathFill, fillTotal);

    // Fill investido
    final fillInv = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [corInvestido.withOpacity(0.2), corInvestido.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathInv = Path();
    pathInv.moveTo(0, size.height);
    for (int i = 0; i < n; i++) {
      pathInv.lineTo(xOf(i), yOf(historico[i].totalInvestido));
    }
    pathInv.lineTo(size.width, size.height);
    pathInv.close();
    canvas.drawPath(pathInv, fillInv);

    // Linha total
    final lineTotal = Paint()
      ..color = corTotal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathLineTotal = Path();
    pathLineTotal.moveTo(xOf(0), yOf(historico[0].valorAcumulado));
    for (int i = 1; i < n; i++) {
      pathLineTotal.lineTo(xOf(i), yOf(historico[i].valorAcumulado));
    }
    canvas.drawPath(pathLineTotal, lineTotal);

    // Linha investido
    final lineInv = Paint()
      ..color = corInvestido
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pathLineInv = Path();
    pathLineInv.moveTo(xOf(0), yOf(historico[0].totalInvestido));
    for (int i = 1; i < n; i++) {
      pathLineInv.lineTo(xOf(i), yOf(historico[i].totalInvestido));
    }
    canvas.drawPath(pathLineInv, lineInv);

    // Ponto final
    canvas.drawCircle(
      Offset(xOf(n - 1), yOf(historico.last.valorAcumulado)),
      4,
      Paint()..color = corTotal,
    );
    canvas.drawCircle(
      Offset(xOf(n - 1), yOf(historico.last.valorAcumulado)),
      6,
      Paint()
        ..color = corTotal.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GraficoPainter old) => true;
}

extension DoubleExtension on double {
  String toFixedWithComma([int decimals = 2]) {
    return toStringAsFixed(decimals).replaceAll('.', ',');
  }
}
