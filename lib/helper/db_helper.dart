import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  //DB here
  static const dbName = "MovieLog.db";
  static const dbVer = 1;

  //Movie Table
  static const table = "movie";
  static const colTitle = "title";
  static const colImgPath = 'image';
  static const colFKGenre = 'genre_id';
  static const colIsFave = 'is_fave';
  static const colDate = 'dateCreated';

  //Genre Table
  static const table2 = 'genre';
  static const colGenreTitle = "genre_title";

  //Comment Table
  static const table3 = 'comment';
  static const colMovieRate = 'rate';
  static const colMovieComment = 'message';
  static const colFKMovie = 'movie_id';

  static Future<Database> openDB() async {
    var createTableMovie =
        '''CREATE TABLE IF NOT EXISTS  $table(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    $colFKGenre INTEGER,
    $colIsFave INTEGER NOT NULL DEFAULT 0,
    $colTitle VARCHAR(255),
    $colImgPath TEXT,
    $colDate TEXT,
    FOREIGN KEY ($colFKGenre) REFERENCES $table2(id) ON DELETE CASCADE ON UPDATE NO ACTION
    )''';

    var createTableGenre =
        '''CREATE TABLE IF NOT EXISTS  $table2(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    $colGenreTitle VARCHAR(255) UNIQUE NOT NULL
    )''';

    var createTableComment =
        '''CREATE TABLE IF NOT EXISTS  $table3(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    $colFKMovie INTEGER,
    $colMovieComment TEXT,
    $colMovieRate REAL,
    FOREIGN KEY ($colFKMovie) REFERENCES $table(id) ON DELETE CASCADE ON UPDATE NO ACTION
    )''';

    //getting path
    var path = join(await getDatabasesPath(), dbName);

    //opening the db with table creations
    var db = openDatabase(
      path,
      version: dbVer,
      onCreate: (db, version) {
        db.execute(createTableGenre);
        db.execute(createTableMovie);
        db.execute(createTableComment);
        print('Database created');
      },
      // in order to enforce foreign keys
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion >= newVersion) {
          return;
        }
        db.execute("DROP TABLE IF EXISTS $table");
        db.execute("DROP TABLE IF EXISTS $table2");
        db.execute("DROP TABLE IF EXISTS $table3");
        db.execute(createTableGenre);
        db.execute(createTableMovie);
        db.execute(createTableComment);
        print("db recreated!");
      },
    );
    return db;
  }

  //fetch highest rated movies
  static Future<List> fetchHighestRatedMovies() async {
    Database db = await openDB();

    return await db.rawQuery('''
  SELECT
    m.id,
    m.$colTitle AS title,
    m.$colImgPath AS image,
    g.$colGenreTitle AS genre,
    IFNULL(AVG(c.$colMovieRate), 0) AS avg_rate
  FROM $table m
  JOIN $table2 g ON g.id = m.$colFKGenre
  LEFT JOIN $table3 c ON c.$colFKMovie = m.id
  GROUP BY m.id
  ORDER BY avg_rate DESC
  LIMIT 5
''');
  }

  //fetch movie count
  static Future<int> fetchMovieCount() async {
    Database db = await openDB();
    List movies = await db.rawQuery('''
  SELECT COUNT(*) as movie_count from $table
''');

    return movies[0]['movie_count'];
  }

  //fetch favorite movies count
  static Future<int> fetchFaveMovieCount() async {
    Database db = await openDB();
    List movies = await db.rawQuery('''
  SELECT COUNT(*) as movie_count 
  FROM movie
  WHERE is_fave = 1
''');
    print('fave count here ${movies[0]['movie_count']}');
    return movies[0]['movie_count'];
  }

  //fetch genres
  static Future<List<Map>> fetchGenres() async {
    var db = await openDB();
    return await db.query(table2);
  }

  //fetch movies
  static Future<List<Map>> fetchMovies() async {
    var db = await openDB();
    return await db.rawQuery('''
    SELECT 
      m.id,
      m.title,
      m.image,
      g.genre_title as genre,
      GROUP_CONCAT(c.message, ' | ') AS messages,
      IFNULL(AVG(c.rate), 0) AS avg_rate
    FROM movie m
    LEFT JOIN comment c ON c.movie_id = m.id
    JOIN genre g ON m.genre_id = g.id
    GROUP BY m.id, m.title, m.image
    ORDER BY $colDate DESC
  ''');
  }

  //fetch movie by genre
  static Future<List<Map>> fetchMoviesByGenre() async {
    var db = await openDB();
    return await db.rawQuery('''
    SELECT 
      m.id,
      m.title,
      m.image,
      g.genre_title AS genre,
      GROUP_CONCAT(c.message, ' | ') AS messages,
      IFNULL(AVG(c.rate), 0) AS avg_rate
    FROM movie m
    LEFT JOIN comment c ON c.movie_id = m.id
    JOIN genre g ON m.genre_id = g.id
    GROUP BY m.id, m.title, m.image, g.genre_title
    ORDER BY g.genre_title ASC
  ''');
  }

  //fetch favorite movies
  static Future<List<Map>> fetchFavoriteMovies() async {
    var db = await openDB();
    return await db.rawQuery('''
    SELECT 
      m.id,
      m.title,
      m.image,
      g.genre_title AS genre,
      GROUP_CONCAT(c.message, ' | ') AS messages,
      IFNULL(AVG(c.rate), 0) AS avg_rate
    FROM movie m
    LEFT JOIN comment c ON c.movie_id = m.id
    JOIN genre g ON m.genre_id = g.id
    WHERE m.is_fave == 1
    GROUP BY m.id, m.title, m.image, g.genre_title
    ORDER BY m.title ASC
  ''');
  }

  // Fetch movies sorted by average rate
  static Future<List<Map>> fetchMoviesByRate() async {
    var db = await openDB();
    return await db.rawQuery('''
    SELECT 
      m.id,
      m.title,
      m.image,
      g.genre_title AS genre,
      GROUP_CONCAT(c.message, ' | ') AS messages,
      IFNULL(AVG(c.rate), 0) AS avg_rate
    FROM movie m
    LEFT JOIN comment c ON c.movie_id = m.id
    JOIN genre g ON m.genre_id = g.id
    GROUP BY m.id, m.title, m.image, g.genre_title
    ORDER BY avg_rate DESC
  ''');
  }

  //fetch movie title with comment count
  static Future<List> fetchMovieWithMostComment() async {
    Database db = await openDB();
    return await db.rawQuery('''
  SELECT
    m.id,
    m.$colTitle AS title,
    COUNT(c.id) AS comment_count
  FROM $table m
  LEFT JOIN $table3 c ON c.$colFKMovie = m.id
  GROUP BY m.id
  ORDER BY comment_count DESC
  LIMIT 4
''');
  }

  static Future<List> fetchMostWatchedGenre() async {
    Database db = await openDB();

    return await db.rawQuery('''
    SELECT 
      g.$colGenreTitle AS genre_title,
      COUNT(m.id) AS genre_count
    FROM $table AS m
    JOIN $table2 AS g ON m.$colFKGenre = g.id
    GROUP BY g.id
    ORDER BY genre_count DESC
    LIMIT 4
  ''');
  }

  //add new movie, selected specify in genre
  static Future<int?> insertMovie(Map movie) async {
    //need sa movie: genre, title, img, message,rate
    try {
      var db = await openDB();//open database

      //insert the genre first and then get the id
      int genreId = await db.insert(table2, {colGenreTitle: movie['genre']});//create new genre row, 
      //since meron na id, pwede na sa colFKGenre
      int movieId = await db.insert(table, { //pasok nalng ung genreId sa movie, 
        colTitle: movie['title'],//title
        colImgPath: movie['img'],//movie image path
        colFKGenre: genreId,//dto, need ang genreId kasi ung movie na table ay may genre na foreign key
        colIsFave: 0,//ilagay lng na zero as default kasi 0 means hindi mo siya gusto/favorite
        colDate: DateTime.now().toIso8601String(),//gagawa ka ng date na string 
      });
    //after create movie, meron ka na movie id para un ung ilalagay mo sa comment table kasi ung comment table ay may foreign key ng movie
      //then mag add ng msg with rate sa comment table
      await db.insert(table3, {
        colMovieComment: movie['message'],
        colMovieRate: movie['rate'],
        colFKMovie: movieId,
      });
      print('movie inserted');
      return 1;
    } catch (e) {
      print('error on create movie $e');
      return null;
    }
  }

  static Future<void> insertMovieGenreSpecified(Map movie) async {
    try {
      var db = await openDB();
      //since meron na id sa movie, pwede na sa colFKGenre
      int movieId = await db.insert(table, {
        colTitle: movie['title'],
        colImgPath: movie['img'],
        colFKGenre: movie['genreId'],
        colIsFave: 0,
        colDate: DateTime.now().toIso8601String(),
      });

      //then mag add ng msg with rate sa comment table
      await db.insert(table3, {
        colMovieComment: movie['message'],
        colMovieRate: movie['rate'],
        colFKMovie: movieId,
      });
      print('movie inserted');
    } catch (e) {
      print('error on create movie $e');
    }
  }

  //fetches the title, image, genre and avg_rate
  static Future<Map?> fetchMovieDetail(int id) async {
    try {
      Database db = await openDB();
      final result = await db.rawQuery(
        '''
    SELECT
      m.id,
      m.$colTitle AS title,
      m.$colImgPath AS image,
      g.$colGenreTitle AS genre,
      m.$colDate AS dateCreated,
      m.$colIsFave as is_fave,
      IFNULL(AVG(c.$colMovieRate), 0) AS avg_rate
    FROM $table m
    JOIN $table2 g ON g.id = m.$colFKGenre
    LEFT JOIN $table3 c ON c.$colFKMovie = m.id
    WHERE m.id = ?
    GROUP BY m.id
    LIMIT 1
  ''',
        [id],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('error on fetch movie');
    }
  }

  static Future<List?> fetchMovieComments(int id) async {
    try {
      Database db = await openDB();
      return await db.query(table3, where: '$colFKMovie = ?', whereArgs: [id]);
    } catch (e) {
      print('error on fetch movie comments');
    }
  }

  static Future<void> updateComment(Map comment) async {
    Database db = await openDB();
    await db.update(
      table3,
      {'message': comment['message'], 'rate': comment['rate']},
      where: 'id = ?',
      whereArgs: [comment['id']],
    );
  }

  static Future<void> addComment(int id, Map comment) async {
    try {
      Database db = await openDB();
      await db.insert(table3, {
        colFKMovie: id,
        'message': comment['message'],
        'rate': comment['rate'],
      });
    } catch (e) {
      print('error on add comment $e');
    }
  }

  static Future<void> deleteComment(int id) async {
    try {
      Database db = await openDB();
      await db.delete(table3, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('error on delete comment $e');
    }
  }

  //add/remove favorite
  static Future<void> isFave(int id, int isFave) async {
    try {
      Database db = await openDB();
      if (isFave == 1) {
        await db.update(
          table,
          {'is_fave': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.update(
          table,
          {'is_fave': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print('error on is fave $e');
    }
  }
}
