import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/stats_service.dart';
import '../services/rating_service.dart';
import '../services/offline_service.dart';
import '../services/reading_history_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isBookmarked = false;
  bool _isSavedOffline = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    // Log reading event for statistics (use source name as category fallback)
    final category = widget.article.source?.name ?? 'general';
    StatsService.logRead(url: widget.article.url, category: category);
    _checkOfflineStatus();
    _addToHistory();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await BookmarkService.isBookmarked(widget.article);
    setState(() => _isBookmarked = isBookmarked);
  }

  Future<void> _checkOfflineStatus() async {
    final isSaved = await OfflineService.isSavedOffline(widget.article);
    setState(() => _isSavedOffline = isSaved);
  }

  Future<void> _addToHistory() async {
    await ReadingHistoryService.addToHistory(widget.article);
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await BookmarkService.removeBookmark(widget.article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from bookmarks')),
        );
      }
    } else {
      await BookmarkService.addBookmark(widget.article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to bookmarks')),
        );
      }
    }
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _toggleLike(bool like) async {
    await RatingService.setLike(widget.article.url, like);
    final msg = like ? 'Liked this article' : 'Disliked this article';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    setState(() {});
  }

  Future<void> _setStars(int stars) async {
    await RatingService.setRating(widget.article.url, stars);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating saved')));
    }
    setState(() {});
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(widget.article.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareArticle() {
    Share.share('${widget.article.title}\n\nRead more: ${widget.article.url}');
  }

  Future<void> _toggleOffline() async {
    if (_isSavedOffline) {
      await OfflineService.removeOfflineArticle(widget.article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from offline reading')),
        );
      }
    } else {
      await OfflineService.saveForOffline(widget.article);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for offline reading')),
        );
      }
    }
    setState(() => _isSavedOffline = !_isSavedOffline);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Icon(
                  _isSavedOffline ? Icons.download_done : Icons.download,
                  color: Colors.white,
                ),
                onPressed: _toggleOffline,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareArticle,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.article.urlToImage != null && widget.article.urlToImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.article.urlToImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade300,
                                Colors.blue.shade600,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.article,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'News Article',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade300,
                            Colors.blue.shade600,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.article,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'News Article',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and Date
                  Row(
                    children: [
                      if (widget.article.source != null) ...[
                        Chip(
                          label: Text(
                            widget.article.source!.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[100],
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          dateFormat.format(widget.article.publishedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    widget.article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Author
                  if (widget.article.author != null) ...[
                    Text(
                      'By ${widget.article.author}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (widget.article.description != null) ...[
                    Text(
                      widget.article.description!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Content
                  if (widget.article.content != null) ...[
                    Text(
                      widget.article.content!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Read Full Article Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchURL,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Read Full Article'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
