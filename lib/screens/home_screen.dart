import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../services/sources_service.dart';
import 'article_detail_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';
import 'reading_history_screen.dart';
import 'offline_articles_screen.dart';
import 'stats_screen.dart';
import 'search_screen.dart';
import '../widgets/article_card.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCategory = 'For You';
  int _selectedIndex = 0;
  String _userName = 'User';

  final List<String> _categories = [
    'For You',
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name);
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<Article> articles;
      
      if (_selectedCategory == 'For You') {
        // Load personalized feed from followed sources
        final followedSources = await SourcesService.getFollowedSources();
        
        if (followedSources.isEmpty) {
          // If no sources followed, set articles to empty (will show empty state)
          articles = [];
        } else {
          // Fetch articles from each followed source and combine
          articles = [];
          for (String sourceId in followedSources) {
            try {
              final sourceArticles = await _newsService.getNewsBySource(sourceId);
              articles.addAll(sourceArticles);
            } catch (e) {
              // Continue even if one source fails
              print('Error loading from source $sourceId: $e');
            }
          }
          
          // Sort by published date (newest first)
          articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          
          // Limit to 50 most recent articles
          if (articles.length > 50) {
            articles = articles.sublist(0, 50);
          }
        }
      } else if (_selectedCategory == 'general') {
        articles = await _newsService.getTopHeadlines();
      } else {
        articles = await _newsService.getNewsByCategory(_selectedCategory);
      }
      
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookmarksScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'News Today',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_articles.length} articles • ${_selectedCategory.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'sources') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SourcesScreen()),
                );
              } else if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReadingHistoryScreen()),
                );
              } else if (value == 'offline') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfflineArticlesScreen()),
                );
              } else if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sources',
                child: Row(
                  children: [
                    Icon(Icons.source),
                    SizedBox(width: 8),
                    Text('News Sources'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Reading History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'offline',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download),
                    SizedBox(width: 8),
                    Text('Offline Reading'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Reading Statistics'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: _selectedCategory == 'For You'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SourcesScreen()),
                ).then((_) => _loadNews()); // Reload after managing sources
              },
              icon: const Icon(Icons.rss_feed),
              label: const Text('Manage Sources'),
              backgroundColor: const Color(0xFFFF6B35),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadNews();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isDark
                              ? Colors.grey[500]
                              : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: isSelected ? _getCategoryLabel(category).length * 8.0 : 0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'business':
        return Icons.business_center_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'technology':
        return Icons.computer_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'For You':
        return 'For You';
      case 'general':
        return 'Trending';
      case 'business':
        return 'Business';
      case 'entertainment':
        return 'Entertainment';
      case 'health':
        return 'Health';
      case 'science':
        return 'Science';
      case 'sports':
        return 'Sports';
      case 'technology':
        return 'Technology';
      default:
        return category;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading news',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      // Show special message for "For You" tab when no sources are followed
      if (_selectedCategory == 'For You') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rss_feed,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No Personalized Feed Yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Follow news sources to see personalized articles here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SourcesScreen()),
                    ).then((_) => _loadNews()); // Reload when coming back
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Follow Sources'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return const Center(
        child: Text('No articles found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return ArticleCard(
            article: article,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailScreen(article: article),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
