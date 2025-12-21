import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:movie_log/helper/db_helper.dart';

class _BarChart extends StatefulWidget {
  _BarChart({required this.movies});
  List movies;
  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  @override
  Widget build(BuildContext context) {
    print("set state from barchar");
    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData,
        borderData: borderData,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
    enabled: false,
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: 8,
      getTooltipItem:
          (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.toStringAsFixed(1),
              const TextStyle(
                color: Color(0xFFFFA726), // Amber accent
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
    ),
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    // Get the movie title safely
    int index = value.toInt();
    String text = '';
    if (index >= 0 && index < widget.movies.length) {
      String fullTitle = widget.movies[index]['title'];
      // Truncate long titles
      text = fullTitle.length > 10
          ? '${fullTitle.substring(0, 10)}...'
          : fullTitle;
    }

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: getTitles,
      ),
    ),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  FlBorderData get borderData => FlBorderData(show: false);

  LinearGradient get _barsGradient => const LinearGradient(
    colors: [
      Color(0xFFC62828), // Primary Red
      Color(0xFFFFA726), // Amber Accent
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  int counter = 0;

  List<BarChartGroupData> get barGroups => widget.movies.map((e) {
    return BarChartGroupData(
      x: counter++,
      barRods: [
        BarChartRodData(
          toY: (e['avg_rate'] as num).toDouble(),
          gradient: _barsGradient,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }).toList();
}

class BarChartSample3 extends StatefulWidget {
  const BarChartSample3({super.key});

  @override
  State<StatefulWidget> createState() => BarChartSample3State();
}

class BarChartSample3State extends State<BarChartSample3> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DbHelper.fetchHighestRatedMovies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFFC62828), // Primary Red
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AspectRatio(
            aspectRatio: 1.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No movies rated yet",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add and rate movies to see statistics",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        List movies = snapshot.data!;
        return AspectRatio(aspectRatio: 1.6, child: _BarChart(movies: movies));
      },
    );
  }
}
