import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/offline_service.dart';
import 'article_detail_screen.dart';
import '../widgets/article_card.dart';

class OfflineArticlesScreen extends StatefulWidget {
  const OfflineArticlesScreen({Key? key}) : super(key: key);

  @override
  State<OfflineArticlesScreen> createState() => _OfflineArticlesScreenState();
}

class _OfflineArticlesScreenState extends State<OfflineArticlesScreen> {
  List<Article> _offlineArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineArticles();
  }

  Future<void> _loadOfflineArticles() async {
    setState(() => _isLoading = true);
    final articles = await OfflineService.getOfflineArticles();
    setState(() {
      _offlineArticles = articles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Reading'),
        actions: [
          if (_offlineArticles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All'),
                    content: const Text('Remove all offline articles?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await OfflineService.clearOfflineArticles();
                  _loadOfflineArticles();
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_offlineArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Offline Articles',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Save articles for offline reading',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.download_done, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                '${_offlineArticles.length} articles saved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _offlineArticles.length,
            itemBuilder: (context, index) {
              final article = _offlineArticles[index];
              return ArticleCard(
                article: article,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(article: article),
                    ),
                  );
                  _loadOfflineArticles();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
