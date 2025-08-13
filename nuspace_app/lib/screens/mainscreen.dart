import 'package:flutter/material.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/screens/activities/activityscreen.dart';
import 'package:nuspace_app/screens/rso/homescreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Key to access HomeScreen state
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ActivityScreenState> _activityKey =
      GlobalKey<ActivityScreenState>();
  // Screens are nullable so we can lazy load them
  final List<Widget?> _screens = [null, null, null];

  @override
  void initState() {
    super.initState();
    // Load the first screen immediately
    _screens[0] = HomeScreen(key: _homeKey);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      //if tapped the same tab again
      if (index == 0 && _homeKey.currentState != null) {
        _homeKey.currentState!.refreshData();
      }
      if (index == 1 && _activityKey.currentState != null) {
        _activityKey.currentState!.refreshData();
      }
    } else {
      setState(() {
        _selectedIndex = index;

        // Lazy load the screen when first accessed
        if (_screens[index] == null) {
          _screens[index] = _buildScreen(index);
        }
      });
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(key: _homeKey);
      case 1:
        return ActivityScreen(key: _activityKey);
      case 2:
        return const Placeholder();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _screens.length,
          (i) => _screens[i] ?? const SizedBox(), //Placeholder until loaded
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: nuBlue,
        backgroundColor: whitetheme,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Activity",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
