import 'dart:io';

import 'package:flutter/material.dart';
import 'package:movie_log/chart/barchart.dart';
import 'package:movie_log/chart/piechartMostComment.dart';
import 'package:movie_log/chart/piechartWatchedGenre.dart';
import 'package:movie_log/helper/db_helper.dart';
import 'package:movie_log/screens/addmoviescreen.dart';
import 'package:movie_log/screens/moviedetailscreen.dart';
import 'package:movie_log/util/format.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int chartRefreshKey = 0;
  String sortValue = 'Last Added';
  String pieChartValue = 'Most Comment';
  PageController controller = PageController(viewportFraction: 0.75);
  late Future watchList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    watchList = DbHelper.fetchMovies();
  }

  void loadWatchList() async {
    watchList = DbHelper.fetchMovies(); //fetch nya ung last update
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),

        title: Image.asset('assets/images/mainlogo.png', width: 150),
        actions: [
          //dto ka mag aadd ng movie
          IconButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            onPressed: () async {
              //mag aantay ka ng result,
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Addmoviescreen()),
              );
              //ngayon after mo ma pop sa addmovie screen, naka return na siya ng value, value nya is true
              if (result == true) {
                setState(() {
                  //itong chart refresh key is para sa mga chart para mag load sila
                  chartRefreshKey++;
                });
                //meron din dto ung load watch list
                loadWatchList();
              }
            },

            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 32),

          // Top 5 Highest Rate Section
          _buildSectionHeader("Top 5 Highest Rated Movies", Icons.star),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
            child: BarChartSample3(key: ValueKey(chartRefreshKey)),
          ),

          const SizedBox(height: 40),

          // Pie Chart Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader("Statistics", Icons.analytics),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: pieChartValue,
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFFFA726),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: const [
                    DropdownMenuItem(
                      value: 'Most Comment',
                      child: Text('Most Comment'),
                    ),
                    DropdownMenuItem(
                      value: 'Most Watched Genre',
                      child: Text('Most Watched Genre'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => pieChartValue = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: FutureBuilder(
                    future: pieChartValue == 'Most Comment'
                        ? DbHelper.fetchMovieWithMostComment()
                        : DbHelper.fetchMostWatchedGenre(),
                    builder: (context, asyncSnapshot) {
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        );
                      }
                      if (!asyncSnapshot.hasData ||
                          asyncSnapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "No recorded movie yet.",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      List movies = asyncSnapshot.data!;
                      return pieChartValue == 'Most Comment'
                          ? piechartMostComment(movies: movies)
                          : PieChartWatchedGenre(movies: movies);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      FutureBuilder(
                        future: DbHelper.fetchMovieCount(),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.redAccent,
                              ),
                            );
                          }
                          if (!asyncSnapshot.hasData ||
                              asyncSnapshot.data! == 0) {
                            return _buildStatCard("0", "Total Movies");
                          }
                          int count = asyncSnapshot.data!;
                          return _buildStatCard("$count", "Total Movies");
                        },
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: DbHelper.fetchFaveMovieCount(),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.redAccent,
                              ),
                            );
                          }
                          if (!asyncSnapshot.hasData ||
                              asyncSnapshot.data! == 0) {
                            return _buildStatCard("0", "Favorite Movies");
                          }
                          int count = asyncSnapshot.data!;
                          return _buildStatCard("$count", "Favorite Movies");
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Watch List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Watch List",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: sortValue,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Color(0xFFC62828)),
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: const [
                    DropdownMenuItem(
                      value: 'Last Added',
                      child: Text('Last Added'),
                    ),
                    DropdownMenuItem(value: 'Genre', child: Text('Genre')),
                    DropdownMenuItem(
                      value: 'Favorite',
                      child: Text('Favorite'),
                    ),
                    DropdownMenuItem(value: 'Rate', child: Text('Rate')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortValue = value!;
                      if (sortValue == 'Last Added') {
                        watchList = DbHelper.fetchMovies();
                      } else if (sortValue == 'Genre') {
                        watchList = DbHelper.fetchMoviesByGenre();
                      } else if (sortValue == 'Favorite') {
                        watchList = DbHelper.fetchFavoriteMovies();
                      } else if (sortValue == 'Rate') {
                        watchList = DbHelper.fetchMoviesByRate();
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Movie List Placeholder
          SizedBox(
            height: 400,
            child: FutureBuilder(
              future: watchList,
              builder: (context, ss) {
                if (ss.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xFFC62828)),
                  );
                }
                if (!ss.hasData || ss.data!.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFC62828),
                          const Color(0xFFD32F2F),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No Movies in Your List",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Add your first movie to get started",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                List movies = ss.data!;

                print("HERE ARE THE MOVIES $movies");
                return PageView.builder(
                  controller: controller,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        double value = 1.0;
                        if (controller.position.haveDimensions) {
                          value = controller.page! - index;
                          value = (1 - (value.abs() * 0.3)).clamp(0.85, 1.0);
                        }
                        return Center(
                          child: Transform.scale(scale: value, child: child),
                        );
                      },
                      child: _buildMovieCard(movies[index]),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFA726),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Map movie) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Moviedetailscreen(id: movie['id']),
          ),
        );

        if (result) {
          setState(() {
            chartRefreshKey++;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Movie Poster Image
              Positioned.fill(
                child: Image.file(File(movie['image']), fit: BoxFit.cover),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Movie Info at Bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        movie['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Genre
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          titleCase(movie['genre']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rating and Additional Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFA726),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFA726),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ((movie['avg_rate']) as num).toStringAsFixed(
                                    1,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFFFA726),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  " / 5",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildIconButton(Icons.info_outline, () {
                            // Handle view details
                            _showMovieDetails(movie);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _showMovieDetails(Map movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                movie['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Genre
              Text(
                movie['genre'],
                style: TextStyle(
                  color: const Color(0xFFC62828),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Rating
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFA726), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${((movie['avg_rate']) as num).toStringAsFixed(1)} / 5.0",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Comment
              const Text(
                "Comment",
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie['messages'] ?? 'No comment available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
