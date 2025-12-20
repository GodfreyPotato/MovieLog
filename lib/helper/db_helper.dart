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
    $colTitle VARCHAR(255),
    $colImgPath TEXT,
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
      IFNULL(AVG(c.rate), 0) AS avg_rate
    FROM movie m
    LEFT JOIN comment c ON c.movie_id = m.id
    JOIN genre g ON m.genre_id = g.id
    GROUP BY m.id, m.title, m.image
    ORDER BY avg_rate DESC
  ''');
  }

  //add new movie, selected specify in genre
  static Future<void> insertMovie(Map movie) async {
    //need sa movie: genre, title, img, message,rate
    try {
      var db = await openDB();

      //insert the genre first and then get the id
      int genreId = await db.insert(table2, {colGenreTitle: movie['genre']});
      //since meron na id, pwede na sa colFKGenre
      int movieId = await db.insert(table, {
        colTitle: movie['title'],
        colImgPath: movie['img'],
        colFKGenre: genreId,
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
}
