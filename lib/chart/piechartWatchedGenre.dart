import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWatchedGenre extends StatefulWidget {
  PieChartWatchedGenre({super.key, required this.movies});
  List movies;

  @override
  State<StatefulWidget> createState() => PieChartWatchedGenreState();
}

class PieChartWatchedGenreState extends State<PieChartWatchedGenre> {
  int touchedIndex = -1;

  // Color palette matching your theme
  final List<Color> sectionColors = [
    const Color(0xFFC62828), // Primary Red
    const Color(0xFFFFA726), // Amber
    const Color(0xFFD32F2F), // Light Red
    const Color(0xFFFFB74D), // Light Amber
    const Color(0xFFE53935), // Bright Red
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.3,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "No data available",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 0,
          sections: showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    // Calculate total comments
    int totalComments = widget.movies.fold(
      0,
      (sum, movie) => sum + (movie['genre_count'] as int),
    );

    // Handle case where there are no comments
    if (totalComments == 0) {
      totalComments = widget.movies.length;
    }

    return List.generate(widget.movies.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final movie = widget.movies[i];
      final commentCount = movie['genre_count'] as int;
      final percentage = totalComments > 0
          ? ((commentCount / totalComments) * 100).toStringAsFixed(1)
          : (100 / widget.movies.length).toStringAsFixed(1);

      // Get color from palette, cycle if more movies than colors
      final color = sectionColors[i % sectionColors.length];

      return PieChartSectionData(
        color: color,
        value: commentCount > 0 ? commentCount.toDouble() : 1.0,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          movie['genre_title'],
          commentCount: commentCount,
          size: widgetSize,
          borderColor: color,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.title, {
    required this.commentCount,
    required this.size,
    required this.borderColor,
  });

  final String title;
  final int commentCount;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    // Truncate title if too long
    String displayTitle = title.length > 8
        ? '${title.substring(0, 8)}...'
        : title;

    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$commentCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
