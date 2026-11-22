import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../domain/gelato_calculator.dart';
import 'gelato_strings.dart';

const String gelatoModule = 'artisanal_gelato';

/// Ingredients of the catalog; tests override it.
final FutureProvider<List<GelatoIngredient>> gelatoIngredientsProvider =
    FutureProvider<List<GelatoIngredient>>((Ref ref) async {
      final Response<dynamic> r = await ref.watch(dioProvider).get<dynamic>('/gelato/ingredients');
      final dynamic data = (r.data as Map<dynamic, dynamic>)['data'];
      return <GelatoIngredient>[
        for (final dynamic i in data as List<dynamic>)
          GelatoIngredient.fromJson(Map<String, dynamic>.from(i as Map<dynamic, dynamic>)),
      ];
    });

/// The allergen book of the main showcase; tests override it.
final FutureProvider<Map<String, dynamic>?> gelatoBookProvider =
    FutureProvider<Map<String, dynamic>?>((Ref ref) async {
      try {
        final Response<dynamic> r = await ref.watch(dioProvider).get<dynamic>('/gelato/showcase/main/book');
        return Map<String, dynamic>.from((r.data as Map<dynamic, dynamic>)['data'] as Map<dynamic, dynamic>);
      } on DioException {
        return null;
      }
    });

/// Shop-floor companion: quick POD / PAC / overrun / cost calculator, guided weighing station and the showcase allergen book.
class GelatoHomePage extends ConsumerWidget {
  const GelatoHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String locale = Localizations.localeOf(context).languageCode;
    String s(GL key) => gelatoLabel(locale, key);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s(GL.title)),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: s(GL.tabCalculator)),
              Tab(text: s(GL.tabWeighing)),
              Tab(text: s(GL.tabShowcase)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[GelatoCalculatorTab(), GelatoWeighingTab(), GelatoShowcaseTab()],
        ),
      ),
    );
  }
}

/// Lines picked by the operator, shared by the calculator and the weighing station.
class GelatoLinesController extends Notifier<List<GelatoLine>> {
  @override
  List<GelatoLine> build() => const <GelatoLine>[];

  void set(List<GelatoLine> lines) => state = lines;
}

final NotifierProvider<GelatoLinesController, List<GelatoLine>> gelatoLinesProvider =
    NotifierProvider<GelatoLinesController, List<GelatoLine>>(GelatoLinesController.new);

class GelatoCalculatorTab extends ConsumerStatefulWidget {
  const GelatoCalculatorTab({super.key});

  @override
  ConsumerState<GelatoCalculatorTab> createState() => _GelatoCalculatorTabState();
}

class _GelatoCalculatorTabState extends ConsumerState<GelatoCalculatorTab> {
  double _overrun = 30;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;
    String s(GL key) => gelatoLabel(locale, key);
    final AsyncValue<List<GelatoIngredient>> catalog = ref.watch(gelatoIngredientsProvider);
    final List<GelatoLine> lines = ref.watch(gelatoLinesProvider);
    GelatoMetrics? metrics;
    if (lines.isNotEmpty && lines.fold<double>(0, (double a, GelatoLine l) => a + l.grams) > 0) {
      metrics = const GelatoCalculator().analyze(lines, overrunPercent: _overrun);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (int i = 0; i < lines.length; i++)
          ListTile(
            title: Text(lines[i].ingredient.label(locale)),
            trailing: SizedBox(
              width: 96,
              child: TextFormField(
                key: ValueKey<String>('gelato-grams-$i'),
                initialValue: lines[i].grams.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: s(GL.grams)),
                onChanged: (String v) {
                  final double grams = double.tryParse(v) ?? 0;
                  ref.read(gelatoLinesProvider.notifier).set(<GelatoLine>[
                    for (int j = 0; j < lines.length; j++) j == i ? GelatoLine(lines[j].ingredient, grams) : lines[j],
                  ]);
                },
              ),
            ),
          ),
        catalog.when(
          data: (List<GelatoIngredient> items) => DropdownButton<GelatoIngredient>(
            isExpanded: true,
            hint: Text(s(GL.addIngredient)),
            items: <DropdownMenuItem<GelatoIngredient>>[
              for (final GelatoIngredient i in items)
                DropdownMenuItem<GelatoIngredient>(value: i, child: Text(i.label(locale))),
            ],
            onChanged: (GelatoIngredient? picked) {
              if (picked == null) return;
              ref.read(gelatoLinesProvider.notifier).set(<GelatoLine>[...lines, GelatoLine(picked, 100)]);
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (Object e, StackTrace st) => Text(s(GL.loadError)),
        ),
        Slider(
          value: _overrun,
          max: 120,
          divisions: 120,
          label: '${_overrun.round()} %',
          onChanged: (double v) => setState(() => _overrun = v),
        ),
        Text('${s(GL.overrun)}: ${_overrun.round()}'),
        if (metrics != null) ...<Widget>[
          if (metrics.lactoseRisk)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(s(GL.lactoseRisk))),
            ),
          _row(s(GL.pod), metrics.pod),
          _row(s(GL.pac), metrics.pac),
          _row(s(GL.fat), metrics.totalFat),
          _row(s(GL.slng), metrics.slng),
          _row(s(GL.solids), metrics.totalSolids),
          _row(s(GL.costPerKg), metrics.costPerKg),
          _row(s(GL.costPerLitre), metrics.costPerLitreGelato),
          _row(s(GL.costPerPortion), metrics.costPerPortion),
        ],
      ],
    );
  }

  Widget _row(String label, double value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

/// Guided weighing station: the target weights of the recipe scaled to the batch, one ingredient at a time, with the weight
/// read from the scale typed in manually.
class GelatoWeighingTab extends ConsumerStatefulWidget {
  const GelatoWeighingTab({super.key});

  @override
  ConsumerState<GelatoWeighingTab> createState() => _GelatoWeighingTabState();
}

class _GelatoWeighingTabState extends ConsumerState<GelatoWeighingTab> {
  double _batch = 3500;
  int _step = 0;
  final TextEditingController _scale = TextEditingController();

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).languageCode;
    String s(GL key) => gelatoLabel(locale, key);
    final List<GelatoLine> lines = ref.watch(gelatoLinesProvider);
    if (lines.isEmpty) {
      return Center(child: Text(s(GL.addIngredient)));
    }
    final List<double> targets = const GelatoCalculator().scale(lines, _batch);
    if (_step >= lines.length) {
      return Center(child: Text(s(GL.weighingDone), style: Theme.of(context).textTheme.headlineSmall));
    }
    final double entered = double.tryParse(_scale.text) ?? 0;
    final double delta = entered - targets[_step];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextFormField(
          initialValue: _batch.toStringAsFixed(0),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s(GL.batchWeight)),
          onChanged: (String v) => setState(() => _batch = double.tryParse(v) ?? _batch),
        ),
        const SizedBox(height: 16),
        Text(lines[_step].ingredient.label(locale), style: Theme.of(context).textTheme.titleLarge),
        Text('${s(GL.weighingTarget)}: ${targets[_step].toStringAsFixed(1)} g'),
        TextField(
          controller: _scale,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s(GL.weighingScale)),
          onChanged: (_) => setState(() {}),
        ),
        Text('Δ ${delta.toStringAsFixed(1)} g', style: TextStyle(color: delta.abs() <= targets[_step] * 0.01 ? Colors.green : Colors.orange)),
        FilledButton(
          onPressed: () => setState(() {
            _step++;
            _scale.clear();
          }),
          child: Text(s(GL.weighingNext)),
        ),
      ],
    );
  }
}

/// Quick view of the published allergen book in the language of the device.
class GelatoShowcaseTab extends ConsumerWidget {
  const GelatoShowcaseTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String locale = Localizations.localeOf(context).languageCode;
    String s(GL key) => gelatoLabel(locale, key);
    final AsyncValue<Map<String, dynamic>?> book = ref.watch(gelatoBookProvider);
    return book.when(
      data: (Map<String, dynamic>? data) {
        final Map<dynamic, dynamic>? books = data?['books'] as Map<dynamic, dynamic>?;
        final Map<dynamic, dynamic>? mine = (books?[locale] ?? books?['en']) as Map<dynamic, dynamic>?;
        final List<dynamic> slots = (mine?['slots'] as List<dynamic>?) ?? const <dynamic>[];
        if (slots.isEmpty) return Center(child: Text(s(GL.showcaseEmpty)));
        return ListView(
          children: <Widget>[
            for (final dynamic slot in slots)
              _SlotTile(slot: Map<String, dynamic>.from(slot as Map<dynamic, dynamic>), strings: s),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace st) => Center(child: Text(s(GL.loadError))),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.strings});

  final Map<String, dynamic> slot;
  final String Function(GL) strings;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> ingredients = (slot['ingredients'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> allergens = (slot['allergens'] as List<dynamic>?) ?? const <dynamic>[];
    final List<String> badges = <String>[
      if (slot['gluten_free'] == true) strings(GL.glutenFree),
      if (slot['lactose_free'] == true) strings(GL.lactoseFree),
      if (slot['vegan'] == true) strings(GL.vegan),
      if (slot['defrosted'] == true) strings(GL.defrosted),
    ];
    return ExpansionTile(
      title: Text('${slot['slot_number']} · ${slot['name']}'),
      subtitle: Text(badges.join(' · ')),
      children: <Widget>[
        ListTile(
          title: Text(<String>[for (final dynamic i in ingredients) '${(i as Map<dynamic, dynamic>)['name']}'].join(', ')),
        ),
        if (allergens.isNotEmpty)
          ListTile(
            title: Text(strings(GL.allergens)),
            subtitle: Text(<String>[for (final dynamic a in allergens) '${(a as Map<dynamic, dynamic>)['name']}'].join(', ')),
          ),
      ],
    );
  }
}
