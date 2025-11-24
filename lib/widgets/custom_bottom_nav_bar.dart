import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).bottomNavigationBarTheme;
    final items = [
      _buildNavItem(context,
          icon: Icons.home, label: "Home", index: 0, theme: theme),
      _buildNavItem(context,
          icon: Icons.book, label: "Consultations", index: 1, theme: theme),
      const SizedBox(width: 40),
      _buildNavItem(context,
          icon: Icons.chat_bubble_outline,
          label: "Messages",
          index: 3,
          theme: theme),
      _buildNavItem(context,
          icon: Icons.history, label: "History", index: 4, theme: theme),
    ];

    return SizedBox(
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items,
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  color: theme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.center_focus_strong,
                  size: 32,
                  color: currentIndex == 2
                      ? theme.selectedItemColor
                      : theme.unselectedItemColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required IconData icon,
      required String label,
      required int index,
      required BottomNavigationBarThemeData theme}) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? theme.selectedItemColor : theme.unselectedItemColor;

    final labelStyle =
        (isSelected ? theme.selectedLabelStyle : theme.unselectedLabelStyle)
                ?.copyWith(color: color) ??
            TextStyle(color: color, fontSize: 12);

    Widget child;
    if (isSelected) {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      child = Center(
        child: Icon(icon, color: color),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
