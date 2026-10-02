import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'about_screen.dart';
import 'editor_screen.dart';
import 'link_screen.dart';
import 'run_screen.dart';
import 'stage_screen.dart';
import 'widgets.dart';

class BoothShell extends StatefulWidget {
  const BoothShell({super.key});

  @override
  State<BoothShell> createState() => _BoothShellState();
}

class _BoothShellState extends State<BoothShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final Ticker _ticker;
  final _focus = FocusNode();

  static const _pages = [
    RunScreen(),
    StageScreen(),
    EditorScreen(),
    LinkScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      context.getInheritedWidgetOfExactType<ShowScope>()?.notifier?.onFrame();
    })..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _typing {
    final node = FocusManager.instance.primaryFocus;
    final current = node?.context;
    if (current == null) return false;
    if (current.widget is EditableText) return true;
    if (current.findAncestorStateOfType<EditableTextState>() != null) {
      return true;
    }
    if (current.findAncestorWidgetOfExactType<ButtonStyleButton>() != null) {
      return true;
    }
    return false;
  }

  void _go() {
    if (_typing) return;
    ShowScope.of(context).go();
  }

  void _hold() {
    if (_typing) return;
    ShowScope.of(context).toggleHold();
  }

  void _skip() {
    if (_typing) return;
    ShowScope.of(context).skip();
  }

  void _back() {
    if (_typing) return;
    ShowScope.of(context).back();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final body = Column(
      children: [
        ProductHeader(now: controller.clock()),
        const Divider(height: 1, color: boothLine),
        Expanded(
          child: IndexedStack(index: _index, children: _pages),
        ),
      ],
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _go,
        const SingleActivator(LogicalKeyboardKey.enter): _go,
        const SingleActivator(LogicalKeyboardKey.keyG): _go,
        const SingleActivator(LogicalKeyboardKey.keyH): _hold,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _skip,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        labelType: NavigationRailLabelType.all,
                        destinations: _destinations,
                      ),
                      const VerticalDivider(width: 1, color: boothLine),
                      Expanded(child: body),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: body),
                      NavigationBar(
                        selectedIndex: _index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        destinations: _bar,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

const _destinations = [
  NavigationRailDestination(
    icon: Icon(Icons.timer_outlined),
    selectedIcon: Icon(Icons.timer),
    label: Text('Run'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.view_agenda_outlined),
    selectedIcon: Icon(Icons.view_agenda),
    label: Text('Stage'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.edit_outlined),
    selectedIcon: Icon(Icons.edit),
    label: Text('Edit'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.sensors_outlined),
    selectedIcon: Icon(Icons.sensors),
    label: Text('Link'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.info_outline),
    selectedIcon: Icon(Icons.info),
    label: Text('About'),
  ),
];

const _bar = [
  NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Run'),
  NavigationDestination(icon: Icon(Icons.view_agenda_outlined), label: 'Stage'),
  NavigationDestination(icon: Icon(Icons.edit_outlined), label: 'Edit'),
  NavigationDestination(icon: Icon(Icons.sensors_outlined), label: 'Link'),
  NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
];
