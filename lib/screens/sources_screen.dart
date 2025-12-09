import 'package:flutter/material.dart';
import '../models/news_source.dart';
import '../services/news_service.dart';
import '../services/sources_service.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({Key? key}) : super(key: key);

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final NewsService _newsService = NewsService();
  List<NewsSource> _sources = [];
  List<String> _followedSources = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'business',
    'entertainment',
    'general',
    'health',
    'science',
    'sports',
    'technology',
  ];

  @override
  void initState() {
    super.initState();
    _loadSources();
    _loadFollowedSources();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sources = await _newsService.getSources(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      setState(() {
        _sources = sources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFollowedSources() async {
    final followed = await SourcesService.getFollowedSources();
    setState(() => _followedSources = followed);
  }

  Future<void> _toggleFollow(NewsSource source) async {
    if (source.id == null) return;
    
    final isFollowing = _followedSources.contains(source.id);
    
    if (isFollowing) {
      await SourcesService.unfollowSource(source.id!);
      setState(() => _followedSources.remove(source.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unfollowed ${source.name}')),
        );
      }
    } else {
      await SourcesService.followSource(source.id!);
      setState(() => _followedSources.add(source.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Following ${source.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Sources'),
        actions: [
          if (_followedSources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  label: Text('${_followedSources.length} Following'),
                  backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category || 
                           (_selectedCategory == null && category == 'All');
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category == 'All' ? null : category;
                  });
                  _loadSources();
                }
              },
              selectedColor: const Color(0xFFFF6B35),
              backgroundColor: Colors.grey[200],
            ),
          );
        },
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
            Text('Error loading sources'),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSources,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sources.isEmpty) {
      return const Center(child: Text('No sources found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _sources.length,
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isFollowing = source.id != null && _followedSources.contains(source.id);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isFollowing ? const Color(0xFFFF6B35) : Colors.grey[300],
              child: Icon(
                Icons.article,
                color: isFollowing ? Colors.white : Colors.grey[600],
              ),
            ),
            title: Text(
              source.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (source.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    source.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        source.category.toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${source.country.toUpperCase()} • ${source.language.toUpperCase()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _toggleFollow(source),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[300] : const Color(0xFFFF6B35),
                foregroundColor: isFollowing ? Colors.black87 : Colors.white,
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
