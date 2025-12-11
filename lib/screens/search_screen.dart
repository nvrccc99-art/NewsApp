import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/newsapi_constants.dart';
import '../services/search_history_service.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import 'article_detail_screen.dart';
import '../widgets/article_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  List<Article> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // NewsAPI only supports from 2017-10-16
    final earliestDate = DateTime.parse(earliestNewsApiDate);
    if ((_fromDate != null && _fromDate!.isBefore(earliestDate)) ||
        (_toDate != null && _toDate!.isBefore(earliestDate))) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isLoading = false;
      });
      return;
    }

    // Save to search history
    await SearchHistoryService.addQuery(query.trim());

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
    });

    try {
      final results = _fromDate != null || _toDate != null
          ? await _newsService.searchWithDateRange(
              query: query,
              from: _fromDate,
              to: _toDate,
            )
          : await _newsService.searchNews(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      final errStr = e.toString();
      // Tangkap error 426 dari NewsAPI (range not valid)
      if (errStr.contains('426')) {
        setState(() {
          _searchResults = [];
          _errorMessage = '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = errStr.replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Load recent queries (no await in build; this is a simple future builder below)
    final futureHistory = SearchHistoryService.getHistory();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search News'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search for news...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Recent Search Chips
          FutureBuilder<List<Map<String, dynamic>>>(
            future: futureHistory,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final items = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        ...items.take(10).map((e) {
                          final q = e['q'] as String;
                          return InputChip(
                            label: Text(q),
                            onPressed: () {
                              _searchController.text = q;
                              _performSearch(q);
                            },
                            onDeleted: () async {
                              await SearchHistoryService.remove(q);
                              setState(() {});
                            },
                          );
                        }).toList(),
                        ActionChip(
                          label: const Text('Clear history'),
                          onPressed: () async {
                            await SearchHistoryService.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Date Range Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _fromDate ?? now,
                        firstDate: oneMonthAgo,
                        lastDate: now,
                      );
                      if (date != null) {
                        setState(() => _fromDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _fromDate != null
                          ? 'From: ${DateFormat('MMM d, y').format(_fromDate!)}'
                          : 'From Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _toDate ?? now,
                        firstDate: oneMonthAgo,
                        lastDate: now,
                      );
                      if (date != null) {
                        setState(() => _toDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _toDate != null
                          ? 'To: ${DateFormat('MMM d, y').format(_toDate!)}'
                          : 'To Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (_fromDate != null || _toDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for news articles',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords and press search',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
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
    );
  }
}
