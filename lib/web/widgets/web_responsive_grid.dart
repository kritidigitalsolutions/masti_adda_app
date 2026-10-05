import 'package:flutter/material.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';

class WebResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const WebResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 18.0,
    this.runSpacing = 24.0,
    this.childAspectRatio = 0.68,
  });

  @override
  Widget build(BuildContext context) {
    final columns = WebResponsive.gridColumnCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
