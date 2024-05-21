import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'splash_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(NewsApp());
}

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Haber Pusulası',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String _searchQuery = '';
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _bookmarkedItems = [];
  List<dynamic> _allNews = [];

  Future<void> _fetchAllNews() async {
    final response = await http.get(
      Uri.parse('https://newsapi.org/v2/everything?q=news&apiKey=3f7823e9b03f4bc5bc6a8ecdb388ff02'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _allNews = data['articles'];
      });
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _searchResults = _allNews
          .where((item) => item['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['description'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['content'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAllNews();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPage(
            performSearch: _performSearch,
            searchResults: _searchResults,
            searchQuery: _searchQuery,
            toggleBookmark: _toggleBookmark,
            bookmarkedItems: _bookmarkedItems,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookmarksPage(
            bookmarkedItems: _bookmarkedItems,
            onBookmarkToggle: _toggleBookmark,
          ),
        ),
      );
    }
  }

  void _toggleBookmark(Map<String, dynamic> item) {
    setState(() {
      if (_bookmarkedItems.contains(item)) {
        _bookmarkedItems.remove(item);
      } else {
        _bookmarkedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Haber Pusulası',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Her zaman en doğru, en güncel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Son Gündemdeki Haberler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ..._allNews.asMap().entries.map((entry) {
                final index = entry.key;
                final news = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: NewsItem(
                        date: news['publishedAt'] ?? '',
                        description: news['description'] ?? '',
                        imageUrl: news['urlToImage'] ?? '',
                        news: news,
                        onBookmarkToggle: _toggleBookmark,
                        isBookmarked: _bookmarkedItems.any((item) =>
                        item['description'] == news['description']),
                      ),
                    ),
                    if (index != _allNews.length - 1) Divider(),
                  ],
                );
              }).toList(),
              if (_searchResults.isNotEmpty) ...[
                const SectionTitle(title: 'Search Results'),
                ..._searchResults.map((result) => SearchResultItem(
                  result: result,
                  query: _searchQuery,
                  onBookmarkToggle: _toggleBookmark,
                  isBookmarked: _bookmarkedItems.contains(result),
                )).toList(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Arama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Kaydedilenler',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news['title'] ?? 'Haber Detayı'),
        backgroundColor: Colors.grey[50],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news['urlToImage'] != null && news['urlToImage'].isNotEmpty)
                Image.network(news['urlToImage']),
              SizedBox(height: 8),
              Text(
                news['title'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                news['publishedAt'] ?? '',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                news['content'] ?? news['description'] ?? 'İçerik bulunamadı.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              if (news['url'] != null && news['url'].isNotEmpty)
                TextButton(
                  onPressed: () {

                    _launchURL(news['url']);
                  },
                  child: Text(
                    'Haberin devamı için tıklayın',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class NewsItem extends StatelessWidget {
  final String date;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> news;
  final Function(Map<String, dynamic>) onBookmarkToggle;
  final bool isBookmarked;

  const NewsItem({
    Key? key,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.news,
    required this.onBookmarkToggle,
    required this.isBookmarked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(news: news),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.black : null,
              ),
              onPressed: () => onBookmarkToggle(news),
            ),
          ],
        ),
      ),
    );
  }
}


class SearchResultItem extends StatelessWidget {
  final Map<String, dynamic> result;
  final String query;
  final Function(Map<String, dynamic>) onBookmarkToggle;
  final bool isBookmarked;

  const SearchResultItem({
    Key? key,
    required this.result,
    required this.query,
    required this.onBookmarkToggle,
    required this.isBookmarked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(news: result),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            if (result['urlToImage'] != null && result['urlToImage'].isNotEmpty)
              Image.network(
                result['urlToImage'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['title'] ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    result['description'] ?? '',
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                onBookmarkToggle(result);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarksPage extends StatelessWidget {
  final List<Map<String, dynamic>> bookmarkedItems;
  final Function(Map<String, dynamic>) onBookmarkToggle;

  const BookmarksPage({
    Key? key,
    required this.bookmarkedItems,
    required this.onBookmarkToggle,
  }) : super(key: key);

  void _removeBookmark(BuildContext context, Map<String, dynamic> item) {
    onBookmarkToggle(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Haber kaldırıldı'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Geri al',
          textColor: Colors.white,
          onPressed: () {

            onBookmarkToggle(item);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilenler'),
        backgroundColor: Colors.grey[50],
      ),
      body: ListView.builder(
        itemCount: bookmarkedItems.length,
        itemBuilder: (context, index) {
          final item = bookmarkedItems[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: ListTile(
              title: Text(
                item['description'],
                style: TextStyle(fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeBookmark(context, item),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final Function(String) performSearch;
  final List<dynamic> searchResults;
  final String searchQuery;
  final Function(Map<String, dynamic>) toggleBookmark;
  final List<Map<String, dynamic>> bookmarkedItems;

  const SearchPage({
    Key? key,
    required this.performSearch,
    required this.searchResults,
    required this.searchQuery,
    required this.toggleBookmark,
    required this.bookmarkedItems,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
        _searchController.text = _recognizedText;
      });

      widget.performSearch(_recognizedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    _searchController.text = widget.searchQuery;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Arama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: widget.performSearch,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => widget.performSearch(_searchController.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image for Text Recognition'),
            ),
            const SizedBox(height: 16),
            if (widget.searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: widget.searchResults.length,
                  itemBuilder: (context, index) {
                    final result = widget.searchResults[index];
                    return SearchResultItem(
                      result: result,
                      query: widget.searchQuery,
                      onBookmarkToggle: widget.toggleBookmark,
                      isBookmarked: widget.bookmarkedItems.contains(result),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
