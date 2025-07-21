import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/detail_task_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/connection_checker.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> searchResults = []; // Simpan hasil pencarian
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fokuskan keyboard saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    // Tambahkan listener untuk menangani input teks
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSearchResults(_searchController.text);
    });
  }

  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final results = await ApiService.handleTask(
        method: 'GET',
        boardId: 0,
        search: query,
      );

      setState(() {
        searchResults = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      log("Error fetching search results: $e");
      setState(() {
        searchResults.clear();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionChecker(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search task...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
        body: Column(
          children: [
            if (isLoading) LinearProgressIndicator(),
            Expanded(
              child: searchResults.isEmpty
                  ? Center(child: Text("No tasks found"))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final task = searchResults[index];
                        if (task['can_access'] == true){
                          return ListTile(
                            title: Text(task["title"] ?? "No Title",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              task["description"] is bool
                                  ? (task["description"]
                                      ? "Has Description"
                                      : "No Description")
                                  : (task["description"] ?? "No Description"),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailTaskScreen(
                                    boardId: task['board_id'],
                                    taskId: task['id'],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return null;
                      },
                    ),
            ),
          ],
        ),
      )
    );
  }
}
