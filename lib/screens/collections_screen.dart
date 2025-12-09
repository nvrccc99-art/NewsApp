import 'package:flutter/material.dart';
import '../services/collections_service.dart';
import '../services/bookmark_service.dart';
import '../models/article.dart';
import 'article_detail_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({Key? key}) : super(key: key);

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<String> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final cols = await CollectionsService.getCollections();
    setState(() {
      _collections = cols;
      _isLoading = false;
    });
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koleksi Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nama koleksi (misal: Tech, Sports)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await CollectionsService.createCollection(result);
      _loadCollections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Koleksi "$result" dibuat')),
        );
      }
    }
  }

  Future<void> _renameCollection(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Koleksi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nama baru',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && result != oldName) {
      await CollectionsService.renameCollection(oldName, result);
      _loadCollections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama koleksi diubah')),
        );
      }
    }
  }

  Future<void> _deleteCollection(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Koleksi'),
        content: Text('Hapus koleksi "$name"? Bookmark tidak akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await CollectionsService.deleteCollection(name);
      _loadCollections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koleksi dihapus')),
        );
      }
    }
  }

  Future<void> _manageItems(String collection) async {
    final items = await CollectionsService.getItems(collection);
    final allBookmarks = await BookmarkService.getBookmarks();
    
    if (!mounted) return;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CollectionItemsScreen(
          collection: collection,
          items: items,
          allBookmarks: allBookmarks,
        ),
      ),
    );
    _loadCollections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Bookmark'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada koleksi',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buat koleksi untuk mengatur bookmark kamu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final name = _collections[index];
                    return FutureBuilder<List<Article>>(
                      future: CollectionsService.getItems(name),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF6B35),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text('$count artikel'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'manage',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Kelola Item'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.drive_file_rename_outline),
                                    SizedBox(width: 8),
                                    Text('Ubah Nama'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'manage') _manageItems(name);
                              if (value == 'rename') _renameCollection(name);
                              if (value == 'delete') _deleteCollection(name);
                            },
                          ),
                          onTap: () => _manageItems(name),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCollection,
        icon: const Icon(Icons.add),
        label: const Text('Buat Koleksi'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}

class _CollectionItemsScreen extends StatefulWidget {
  final String collection;
  final List<Article> items;
  final List<Article> allBookmarks;

  const _CollectionItemsScreen({
    required this.collection,
    required this.items,
    required this.allBookmarks,
  });

  @override
  State<_CollectionItemsScreen> createState() => _CollectionItemsScreenState();
}

class _CollectionItemsScreenState extends State<_CollectionItemsScreen> {
  late List<Article> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Future<void> _addBookmark() async {
    final available = widget.allBookmarks
        .where((b) => !_items.any((i) => i.url == b.url))
        .toList();
    
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua bookmark sudah ada di koleksi ini')),
      );
      return;
    }
    
    final selected = await showDialog<Article>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Bookmark'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (context, index) {
              final article = available[index];
              return ListTile(
                title: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(article.source?.name ?? ''),
                onTap: () => Navigator.pop(context, article),
              );
            },
          ),
        ),
      ),
    );
    
    if (selected != null) {
      await CollectionsService.addItem(widget.collection, selected);
      setState(() => _items.add(selected));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark ditambahkan')),
        );
      }
    }
  }

  Future<void> _removeItem(Article article) async {
    await CollectionsService.removeItem(widget.collection, article);
    setState(() => _items.removeWhere((a) => a.url == article.url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dihapus dari koleksi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection),
      ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Koleksi kosong',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan bookmark ke koleksi ini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final article = _items[index];
                return ListTile(
                  leading: article.urlToImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.urlToImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.article),
                        ),
                  title: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(article.source?.name ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeItem(article),
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addBookmark,
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add),
      ),
    );
  }
}
