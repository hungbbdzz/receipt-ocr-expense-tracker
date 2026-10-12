import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/charts_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/scan_flow.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
    create: (_) => ExpenseProvider()..load(),
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  static const _seed = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ExpenseProvider, ThemeMode>((p) => p.themeMode);
    return MaterialApp(
      title: 'Receipt Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: _seed),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: _seed,
          brightness: Brightness.dark),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Chi tiêu' : 'Thống kê'),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => context.read<ExpenseProvider>().toggleTheme(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [ExpenseListScreen(), ChartsScreen()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScanFlow.start(context),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Quét hóa đơn'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Danh sách'),
          NavigationDestination(icon: Icon(Icons.donut_large), label: 'Biểu đồ'),
        ],
      ),
    );
  }
}
