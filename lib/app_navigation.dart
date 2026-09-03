import 'package:flutter/material.dart';

class AppScreen extends StatefulWidget {
  final List<Widget> pages;
  final List<String> titles;
  final List<BottomNavigationBarItem> navBarItems;
  final List<Widget> actions;

  const AppScreen({super.key,
    required this.pages,
    required this.titles,
    required this.navBarItems,
    required this.actions});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen>{
  int _selectedPageIndex = 0;

  void _changePage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titles[_selectedPageIndex]),
        centerTitle: true,
        actions: widget.actions,
      ),
      key: widget.key,
      body: widget.pages[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: widget.navBarItems,
        currentIndex: _selectedPageIndex,
        onTap: _changePage,
      ),
    );
  }

  @override
  void dispose(){
    super.dispose();
  }
}