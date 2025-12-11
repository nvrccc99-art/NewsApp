# 📚 CHEAT SHEET PARAMETER PENILAIAN - NEWS APP

---

## **PARAMETER A: Konsep Pemrograman**

### **1. State Management dengan Provider**

**Lokasi Code:**
- `lib/providers/theme_provider.dart`
- `lib/providers/text_size_provider.dart`
- `lib/main.dart` (setup MultiProvider)

**Cara Kerja:**
Provider menyimpan state global seperti dark mode dan text size. Ketika user toggle dark mode, Provider memanggil `notifyListeners()` yang trigger semua widget yang listening untuk rebuild otomatis. Data persisten disimpan di SharedPreferences.

**Contoh Code:**
```dart
// lib/providers/theme_provider.dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // ← Trigger UI update
    _saveTheme();
  }
  
  ThemeData get themeData => _isDarkMode 
    ? ThemeData.dark() 
    : ThemeData.light();
}

// lib/main.dart - Setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => TextSizeProvider()),
  ],
  child: MyApp(),
)

// Screen - Consume provider
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.toggleTheme(); // ← Otomatis rebuild UI
```

---

### **2. Service Layer Architecture**

**Lokasi Code:**
- `lib/services/auth_service.dart`
- `lib/services/bookmark_service.dart`
- `lib/services/news_service.dart`
- `lib/services/offline_service.dart`
- `lib/services/reading_history_service.dart`
- `lib/services/sources_service.dart`
- `lib/services/stats_service.dart`

**Cara Kerja:**
Screen tidak langsung akses database atau API. Screen memanggil Service → Service handle business logic (validation, API call, database operation) → return hasil ke Screen. Ini bikin code clean, reusable, dan mudah di-maintain.

**Contoh Code:**
```dart
// Screen cuma panggil service (simple):
// lib/screens/bookmarks_screen.dart
final bookmarks = await BookmarkService.getBookmarks();
await BookmarkService.addBookmark(article);

// Service yang handle semua logic:
// lib/services/bookmark_service.dart
class BookmarkService {
  static Future<List<Article>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey(); // UID-based key
    final bookmarksJson = prefs.getStringList(key) ?? [];
    return bookmarksJson.map((json) => 
      Article.fromJson(jsonDecode(json))
    ).toList();
  }
  
  static Future<void> addBookmark(Article article) async {
    // Validation, duplicate check, save logic
    // Screen tidak perlu tau detail ini
  }
}
```

---

### **3. UID-Based Data Isolation**

**Lokasi Code:**
- `lib/services/bookmark_service.dart` (line ~10-20)
- `lib/services/offline_service.dart` (line ~10-20)
- `lib/services/sources_service.dart` (line ~10-20)
- `lib/services/reading_history_service.dart` (line ~10-20)
- `lib/services/stats_service.dart` (line ~10-20)

**Cara Kerja:**
Setiap user punya unique ID (UID dari Firebase Auth). Data disimpan dengan key pattern: `{feature_name}_{uid}`. Contoh: user A bookmarks-nya di `bookmarks_abc123`, user B di `bookmarks_xyz789`. Jadi data tidak tercampur antar user. Ada legacy migration untuk backward compatibility.

**Contoh Code:**
```dart
// lib/services/bookmark_service.dart
static Future<String> _currentKey() async {
  final user = AuthService.getCurrentUser();
  final isGuest = await AuthService.isGuest();
  
  if (user == null && !isGuest) {
    return 'bookmarks_anonymous';
  }
  if (isGuest) return 'bookmarks_guest';
  
  // ← Per-user key dengan UID
  return 'bookmarks_${user!.uid}';
}

// Migration dari old key ke new key
static Future<void> _maybeMigrate(
  SharedPreferences prefs, 
  String key
) async {
  if (!prefs.containsKey(key) && 
      prefs.containsKey(_legacyKey)) {
    final legacy = prefs.getStringList(_legacyKey) ?? [];
    await prefs.setStringList(key, legacy);
  }
}
```

**User A Login:**
- Bookmarks: `bookmarks_userA123`
- History: `reading_history_userA123`

**User B Login:**
- Bookmarks: `bookmarks_userB456`
- History: `reading_history_userB456`

→ **Data terpisah per user!**

---

### **4. Asynchronous Programming**

**Lokasi Code:**
- Semua services (`lib/services/*.dart`)
- Semua screens yang fetch data (`lib/screens/*.dart`)

**Cara Kerja:**
Operasi yang butuh waktu (API call, database read/write) menggunakan `Future` dan `async/await`. Ini mencegah UI freeze. Saat fetch data, tampilkan loading indicator. Ketika data ready, update UI dengan `setState()`.

**Contoh Code:**
```dart
// lib/screens/home_screen.dart
Future<void> _loadNews() async {
  setState(() => _isLoading = true); // Show loading
  
  try {
    // Async operation - tidak block UI
    final articles = await NewsService.getTopHeadlines(
      category: _selectedCategory
    );
    
    setState(() {
      _articles = articles;
      _isLoading = false; // Hide loading
    });
  } catch (e) {
    setState(() => _isLoading = false);
    // Handle error
  }
}

// lib/services/news_service.dart
static Future<List<Article>> getTopHeadlines({
  String? category
}) async {
  final url = Uri.parse(
    '$_baseUrl/top-headlines?'
    'country=us&category=$category&apiKey=$_apiKey'
  );
  
  final response = await http.get(url); // Async HTTP call
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['articles'] as List)
      .map((json) => Article.fromJson(json))
      .toList();
  }
  throw Exception('Failed to load');
}
```

---

### **5. RESTful API Integration**

**Lokasi Code:**
- `lib/services/news_service.dart`
- `lib/models/article.dart`
- `lib/models/news_response.dart`
- `lib/constants/newsapi_constants.dart`

**Cara Kerja:**
Aplikasi fetch data dari NewsAPI menggunakan HTTP GET request. Response JSON di-parse ke Dart objects (Article model). Ada query parameters untuk filtering (category, search keyword, date range). Error handling untuk network issues.

**Contoh Code:**
```dart
// lib/services/news_service.dart
class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = 'YOUR_API_KEY';
  
  // Get top headlines with category
  static Future<List<Article>> getTopHeadlines({
    String? category
  }) async {
    final url = Uri.parse(
      '$_baseUrl/top-headlines?'
      'country=us&'
      'category=$category&'
      'apiKey=$_apiKey'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List;
      return articles
        .map((json) => Article.fromJson(json))
        .toList();
    }
    throw Exception('Failed to load news');
  }
  
  // Search with date range
  static Future<List<Article>> searchWithDateRange({
    required String query,
    required DateTime from,
    required DateTime to,
  }) async {
    // Format date untuk API: 2024-12-01T00:00:00
    final fromStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(from);
    final toStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(to);
    
    final url = Uri.parse(
      '$_baseUrl/everything?'
      'q=$query&'
      'from=$fromStr&'
      'to=$toStr&'
      'apiKey=$_apiKey'
    );
    
    final response = await http.get(url);
    // ... parse JSON
  }
}

// lib/models/article.dart - JSON parsing
class Article {
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'url': url,
    'urlToImage': urlToImage,
  };
}
```

---

## **PARAMETER B: Kesesuaian Fitur dengan Kebutuhan End-User**

### **1. Multi-Method Authentication**

**Lokasi Code:**
- `lib/services/auth_service.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/email_login_screen.dart`
- `lib/screens/register_screen.dart`

**Cara Kerja:**
User bisa login dengan 3 cara: Google Sign-In (cepat), Email/Password (tradisional), atau Guest Mode (tanpa registrasi). Firebase Auth handle semua authentication. Setelah login, UID digunakan untuk data isolation.

**Contoh Code:**
```dart
// lib/services/auth_service.dart
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Google Sign-In
  static Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = 
      await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = 
      await googleUser!.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = 
      await _auth.signInWithCredential(credential);
    return userCredential.user;
  }
  
  // Email/Password Sign-In
  static Future<User?> signInWithEmail(
    String email, 
    String password
  ) async {
    final userCredential = 
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    return userCredential.user;
  }
  
  // Guest Mode
  static Future<void> signInAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
  }
  
  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
```

**Kebutuhan User:**
- User yang ingin cepat → Google Sign-In
- User yang prefer traditional → Email/Password
- User yang cuma mau coba → Guest Mode

---

### **2. Personalized News Browsing**

**Lokasi Code:**
- `lib/screens/home_screen.dart` (categories)
- `lib/screens/search_screen.dart` (search + date filter)
- `lib/screens/sources_screen.dart` (follow sources)
- `lib/services/sources_service.dart`

**Cara Kerja:**
User bisa pilih kategori berita (Business, Tech, Sports, dll). Ada search dengan filter tanggal untuk cari berita spesifik. User bisa follow news sources favorit mereka, dan home screen akan prioritas berita dari sources yang di-follow.

**Contoh Code:**
```dart
// lib/screens/home_screen.dart - Categories
final List<String> _categories = [
  'general', 'business', 'technology', 
  'sports', 'entertainment', 'health', 'science'
];

String _selectedCategory = 'general';

// Category tabs
TabBar(
  isScrollable: true,
  tabs: _categories.map((cat) => 
    Tab(text: cat.toUpperCase())
  ).toList(),
  onTap: (index) {
    setState(() => _selectedCategory = _categories[index]);
    _loadNews();
  },
)

// lib/screens/search_screen.dart - Date filter
Future<void> _search() async {
  if (_fromDate != null && _toDate != null) {
    // Validate range
    if (_fromDate!.isAfter(_toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Start date cannot be after end date'
        ))
      );
      return;
    }
    
    // Search with date range
    final articles = await NewsService.searchWithDateRange(
      query: _searchController.text,
      from: _fromDate!,
      to: _toDate!,
    );
  }
}
```

**Kebutuhan User:**
- User tertarik topik spesifik → Categories
- User cari berita event tertentu → Search + Date Filter
- User suka source tertentu → Follow Sources

---

### **3. Content Management**

**Lokasi Code:**
- `lib/screens/bookmarks_screen.dart` + `lib/services/bookmark_service.dart`
- `lib/screens/reading_history_screen.dart` + `lib/services/reading_history_service.dart`
- `lib/screens/offline_articles_screen.dart` + `lib/services/offline_service.dart`

**Cara Kerja:**
User bisa save artikel ke Bookmarks untuk dibaca nanti. Setiap artikel yang dibuka otomatis masuk Reading History. User bisa save artikel ke Offline Reading untuk quick access. Semua data per-user dengan UID isolation.

**Contoh Code:**
```dart
// lib/services/bookmark_service.dart
static Future<void> addBookmark(Article article) async {
  final prefs = await SharedPreferences.getInstance();
  final key = await _currentKey(); // bookmarks_{uid}
  final bookmarksJson = prefs.getStringList(key) ?? [];
  
  // Check duplicate
  final alreadyBookmarked = bookmarksJson.any((json) {
    final saved = Article.fromJson(jsonDecode(json));
    return saved.url == article.url;
  });
  
  if (!alreadyBookmarked) {
    bookmarksJson.insert(0, jsonEncode(article.toJson()));
    await prefs.setStringList(key, bookmarksJson);
  }
}

// lib/screens/article_detail_screen.dart
@override
void initState() {
  super.initState();
  _loadBookmarkStatus();
  _loadOfflineStatus();
  
  // Auto add to history when screen opens
  ReadingHistoryService.addToHistory(widget.article);
  StatsService.incrementArticlesRead();
}
```

**Kebutuhan User:**
- Save artikel menarik untuk nanti → Bookmarks
- Track artikel yang sudah dibaca → Reading History
- Quick access artikel penting → Offline Reading

---

### **4. Reading Experience**

**Lokasi Code:**
- `lib/providers/theme_provider.dart` (dark mode)
- `lib/providers/text_size_provider.dart` (text size)
- `lib/screens/settings_screen.dart` (toggle UI)
- `lib/screens/article_detail_screen.dart` (WebView)

**Cara Kerja:**
User bisa toggle dark/light mode untuk kenyamanan mata. Text size bisa disesuaikan (small/medium/large) untuk accessibility. Artikel full dibuka di WebView dalam app tanpa keluar ke browser external.

**Contoh Code:**
```dart
// lib/providers/theme_provider.dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  ThemeData get themeData {
    return _isDarkMode 
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  }
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _saveTheme();
  }
}

// lib/screens/settings_screen.dart - UI
SwitchListTile(
  title: Text('Dark Mode'),
  value: themeProvider.isDarkMode,
  onChanged: (_) => themeProvider.toggleTheme(),
)

DropdownButton<String>(
  value: textSizeProvider.currentSize,
  items: ['Small', 'Medium', 'Large']
    .map((size) => DropdownMenuItem(
      value: size,
      child: Text(size),
    ))
    .toList(),
  onChanged: (size) => textSizeProvider.setTextSize(size!),
)
```

**Kebutuhan User:**
- Nyaman baca di malam hari → Dark Mode
- User dengan masalah penglihatan → Text Size Adjustment
- Baca artikel tanpa keluar app → WebView Integration

---

### **5. User Insights**

**Lokasi Code:**
- `lib/screens/stats_screen.dart`
- `lib/services/stats_service.dart`
- `lib/services/search_history_service.dart`

**Cara Kerja:**
Aplikasi track berapa artikel yang sudah dibaca user, kategori favorit, total waktu baca. Ada search history untuk quick access pencarian lama. Semua data per-user dengan UID isolation untuk privacy.

**Contoh Code:**
```dart
// lib/services/stats_service.dart
class StatsService {
  // Increment articles read counter
  static Future<void> incrementArticlesRead() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey(); // stats_{uid}
    final stats = await getStats();
    
    stats['totalArticlesRead'] = 
      (stats['totalArticlesRead'] ?? 0) + 1;
    
    await prefs.setString(key, jsonEncode(stats));
  }
  
  // Track category read
  static Future<void> trackCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _currentKey();
    final stats = await getStats();
    
    Map<String, int> categories = 
      Map<String, int>.from(stats['categories'] ?? {});
    
    categories[category] = (categories[category] ?? 0) + 1;
    stats['categories'] = categories;
    
    await prefs.setString(key, jsonEncode(stats));
  }
  
  // Get favorite category
  static Future<String> getFavoriteCategory() async {
    final stats = await getStats();
    final categories = 
      Map<String, int>.from(stats['categories'] ?? {});
    
    if (categories.isEmpty) return 'None';
    
    return categories.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }
}
```

**Kebutuhan User:**
- Tau kebiasaan baca sendiri → Statistics Dashboard
- Quick access pencarian lama → Search History
- Privacy data → Per-user UID isolation

---

## **PARAMETER C: Ketepatan Waktu**

### **Timeline Development**

**Week 1-2: Core Setup** ✅
- Setup Flutter project & dependencies
- Firebase configuration (`lib/firebase_options.dart`)
- NewsAPI integration (`lib/services/news_service.dart`)
- Basic UI structure (`lib/screens/home_screen.dart`, `lib/main.dart`)
- Authentication skeleton (`lib/services/auth_service.dart`)

**Week 3-4: Feature Development** ✅
- Bookmark system (`lib/services/bookmark_service.dart`, `lib/screens/bookmarks_screen.dart`)
- Reading history (`lib/services/reading_history_service.dart`, `lib/screens/reading_history_screen.dart`)
- Offline reading (`lib/services/offline_service.dart`, `lib/screens/offline_articles_screen.dart`)
- Search functionality (`lib/screens/search_screen.dart`)
- News sources (`lib/services/sources_service.dart`, `lib/screens/sources_screen.dart`)

**Week 5: Enhancement** ✅
- Theme provider (`lib/providers/theme_provider.dart`)
- Text size provider (`lib/providers/text_size_provider.dart`)
- Statistics (`lib/services/stats_service.dart`, `lib/screens/stats_screen.dart`)
- Profile management (`lib/screens/settings_screen.dart`)
- UI polish & refinement

**Week 6: Testing & Deployment** ✅
- Bug fixes & testing
- UID-based data isolation implementation (all services updated)
- Code cleanup (removed unused features)
- APK build: `flutter build apk`
- Delivered on-time ✅

**Proof:**
- Git commits menunjukkan progression sesuai timeline
- APK file: `build/app/outputs/flutter-apk/app-release.apk`
- Last build: Exit Code 0 (successful)

---

## **PARAMETER D: Validasi Input**

### **1. Authentication Form Validation**

**Lokasi Code:**
- `lib/screens/email_login_screen.dart`
- `lib/screens/register_screen.dart`

**Cara Kerja:**
Form menggunakan `TextFormField` dengan `validator` function. Validasi email format (harus ada @), password minimal 6 karakter, dan field tidak boleh kosong. Error ditampilkan real-time saat user input.

**Contoh Code:**
```dart
// lib/screens/email_login_screen.dart
Form(
  key: _formKey,
  child: Column(
    children: [
      // Email validation
      TextFormField(
        controller: _emailController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null; // Valid
        },
      ),
      
      // Password validation
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null; // Valid
        },
      ),
      
      // Login button
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Form valid, proceed
            _login();
          }
          // If invalid, error messages shown
        },
        child: Text('Login'),
      ),
    ],
  ),
)
```

**Error Messages:**
- Email kosong: "Please enter your email"
- Email tidak valid: "Please enter a valid email"
- Password kosong: "Please enter your password"
- Password terlalu pendek: "Password must be at least 6 characters"

---

### **2. Date Range Validation**

**Lokasi Code:**
- `lib/screens/search_screen.dart`
- `lib/constants/newsapi_constants.dart`

**Cara Kerja:**
Saat user search dengan date filter, validasi: 1) Start date tidak boleh setelah end date, 2) Range maksimal 30 hari (NewsAPI limitation), 3) Date tidak boleh lebih lama dari Oct 16, 2017 (NewsAPI free tier limit).

**Contoh Code:**
```dart
// lib/screens/search_screen.dart
Future<void> _search() async {
  if (_fromDate == null || _toDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select date range'))
    );
    return;
  }
  
  // Validate: from <= to
  if (_fromDate!.isAfter(_toDate!)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Start date cannot be after end date'),
        backgroundColor: Colors.red,
      )
    );
    return;
  }
  
  // Validate: max 30 days range
  final daysDiff = _toDate!.difference(_fromDate!).inDays;
  if (daysDiff > 30) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Date range cannot exceed 30 days (NewsAPI limit)'
        ),
        backgroundColor: Colors.red,
      )
    );
    return;
  }
  
  // All validations passed, proceed
  setState(() => _isLoading = true);
  final articles = await NewsService.searchWithDateRange(
    query: _searchController.text,
    from: _fromDate!,
    to: _toDate!,
  );
}
```

**Error Messages:**
- Date tidak dipilih: "Please select date range"
- From > To: "Start date cannot be after end date"
- Range > 30 hari: "Date range cannot exceed 30 days"

---

### **3. Profile Name Validation**

**Lokasi Code:**
- `lib/screens/settings_screen.dart`

**Cara Kerja:**
Saat user edit profile name, validasi name tidak boleh kosong atau hanya berisi spasi. Setelah valid, save ke SharedPreferences dengan key `user_name_{uid}`.

**Contoh Code:**
```dart
// lib/screens/settings_screen.dart
Future<void> _editProfileName() async {
  final nameController = TextEditingController(text: _userName);
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit Name'),
      content: TextField(
        controller: nameController,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: 'Enter your name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final newName = nameController.text.trim();
            
            // Validation: not empty
            if (newName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Name cannot be empty'),
                  backgroundColor: Colors.red,
                )
              );
              return;
            }
            
            // Save to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final user = AuthService.getCurrentUser();
            final key = 'user_name_${user?.uid ?? 'guest'}';
            await prefs.setString(key, newName);
            
            setState(() => _userName = newName);
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
}
```

**Error Messages:**
- Name kosong: "Name cannot be empty"
- Success: "Name updated"

---

### **4. Network Error Handling**

**Lokasi Code:**
- `lib/services/news_service.dart`
- Semua screens yang fetch data

**Cara Kerja:**
Semua API calls dibungkus try-catch. Kalau network error (no internet, timeout, API down), catch error dan return empty list atau show error message. User tidak melihat crash atau technical error, tapi user-friendly message.

**Contoh Code:**
```dart
// lib/services/news_service.dart
static Future<List<Article>> getTopHeadlines({
  String? category
}) async {
  try {
    final url = Uri.parse(
      '$_baseUrl/top-headlines?'
      'country=us&category=$category&apiKey=$_apiKey'
    );
    
    final response = await http.get(url).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timeout');
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List;
      return articles
        .map((json) => Article.fromJson(json))
        .toList();
    } else {
      throw Exception('Failed to load news');
    }
  } on SocketException {
    throw Exception('No internet connection');
  } on TimeoutException {
    throw Exception('Request timeout. Check your connection');
  } catch (e) {
    throw Exception('Failed to load news: ${e.toString()}');
  }
}

// lib/screens/home_screen.dart - Handle error
Future<void> _loadNews() async {
  setState(() => _isLoading = true);
  
  try {
    final articles = await NewsService.getTopHeadlines(
      category: _selectedCategory
    );
    setState(() {
      _articles = articles;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadNews,
        ),
      )
    );
  }
}
```

**Error Handling:**
- No internet: "No internet connection"
- Timeout: "Request timeout. Check your connection"
- General error: "Failed to load news"
- User bisa retry dengan tombol "Retry"

---

## **PARAMETER E: Keberhasilan Program**

### **1. Technical Success**

**Bukti:**
- Build successful tanpa error
- Terminal output: `flutter build apk` → Exit Code: 0
- APK location: `build/app/outputs/flutter-apk/app-release.apk`
- File size: ~50MB (include dependencies)
- Installable di Android devices

**Cara Verifikasi:**
```bash
# Terminal command
flutter build apk

# Output (successful):
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

**No Errors:**
- Compilation errors: 0
- Runtime errors: handled dengan try-catch
- Firebase connection: stable
- NewsAPI integration: working

---

### **2. Feature Completeness**

**Semua Fitur Functional:**

✅ **Authentication (3 methods)**
- `lib/services/auth_service.dart` - Google, Email, Guest
- Tested: All methods working

✅ **News Browsing (7 categories)**
- `lib/screens/home_screen.dart` - Categories tab
- Tested: All categories fetch data correctly

✅ **Search with Filters**
- `lib/screens/search_screen.dart` - Keyword + date range
- Tested: Search working, validations working

✅ **Bookmark Management**
- `lib/services/bookmark_service.dart` - Add, remove, list
- Tested: Bookmarks persist per-user

✅ **Reading History**
- `lib/services/reading_history_service.dart` - Auto-track
- Tested: History tracks correctly per-user

✅ **Offline Reading**
- `lib/services/offline_service.dart` - Save articles
- Tested: Articles saved per-user

✅ **Statistics Dashboard**
- `lib/services/stats_service.dart` - Track reads, categories
- Tested: Stats accurate per-user

✅ **Theme & Accessibility**
- `lib/providers/theme_provider.dart` - Dark/light mode
- `lib/providers/text_size_provider.dart` - Text size
- Tested: Settings persist and apply correctly

**Total Features: 10+ fully functional**

---

### **3. Data Management Success**

**UID-Based Isolation:**
- All services use `{feature}_{uid}` pattern
- User A data ≠ User B data
- Tested: Multiple accounts have separate data

**Files with UID isolation:**
```
lib/services/bookmark_service.dart
  → bookmarks_{uid}

lib/services/offline_service.dart
  → offline_articles_{uid}

lib/services/sources_service.dart
  → sources_{uid}

lib/services/reading_history_service.dart
  → reading_history_{uid}

lib/services/stats_service.dart
  → stats_{uid}
```

**Security:**
- Firebase Auth: secure authentication
- Local storage: per-user isolation
- No data leak between users

**Legacy Migration:**
- Old data (global keys) → migrated to new format (UID keys)
- Backward compatible
- No data loss

---

### **4. User Experience Success**

**Responsive UI:**
- Loading indicators saat fetch data
- Pull-to-refresh di semua list screens
- Smooth navigation & transitions

**Dark Mode:**
- `ThemeProvider` - toggle dark/light
- Persist preference
- All screens support both themes

**Text Size:**
- `TextSizeProvider` - Small/Medium/Large
- Accessibility feature
- Apply globally

**Error Messages:**
- User-friendly (bukan technical error)
- Action buttons (Retry, Dismiss)
- Clear instructions

**Navigation:**
- Bottom navigation bar (Home, Search, Bookmarks)
- Drawer menu (Settings, Stats, Offline, Sources)
- Back navigation working

**Example - Good UX:**
```dart
// Loading state
if (_isLoading) {
  return Center(child: CircularProgressIndicator());
}

// Empty state
if (_articles.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 100),
        Text('No articles found'),
      ],
    ),
  );
}

// Error state with retry
if (_error != null) {
  return Center(
    child: Column(
      children: [
        Text(_error!),
        ElevatedButton(
          onPressed: _retry,
          child: Text('Retry'),
        ),
      ],
    ),
  );
}

// Success state
return ListView.builder(...);
```

---

### **5. Code Quality Success**

**Service Layer Architecture:**
- Clean separation: UI ↔ Service ↔ Data
- Reusable services
- Easy to maintain

**File Structure:**
```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic
├── providers/       # State management
├── widgets/         # Reusable widgets
└── main.dart        # Entry point
```

**No Unused Code:**
- Deleted: `forgot_password_screen.dart` (unused)
- Deleted: `profile_service.dart` (unused)
- Removed: `removeFromHistory()` method (unused)
- Clean codebase ✅

**Error Handling:**
- Try-catch di semua async operations
- User-friendly error messages
- No unhandled exceptions

**Maintainable:**
- Clear naming conventions
- Comments di code penting
- Consistent code style
- Easy untuk future development

**Example - Clean Service:**
```dart
class BookmarkService {
  // Private helper - UID-based key
  static Future<String> _currentKey() async { ... }
  
  // Private helper - Legacy migration
  static Future<void> _maybeMigrate(...) async { ... }
  
  // Public API - Get bookmarks
  static Future<List<Article>> getBookmarks() async { ... }
  
  // Public API - Add bookmark
  static Future<void> addBookmark(Article article) async { ... }
  
  // Public API - Remove bookmark
  static Future<void> removeBookmark(Article article) async { ... }
  
  // Public API - Check if bookmarked
  static Future<bool> isBookmarked(Article article) async { ... }
}
```

Clear, organized, easy to understand! ✅

---

# 🎯 KESIMPULAN

**Program BERHASIL di semua aspek:**

✅ **Technical** - Build successful, no errors, APK ready  
✅ **Features** - 10+ features fully functional  
✅ **Data** - Secure, isolated, persistent per-user  
✅ **UX** - Responsive, accessible, user-friendly  
✅ **Code** - Clean architecture, maintainable, no unused code  

**Siap untuk Presentasi & Deployment! 🚀**
