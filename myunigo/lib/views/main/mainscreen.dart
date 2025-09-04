import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myunigo/models/item.dart';
import 'package:myunigo/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Item> itemList = <Item>[];
  int numofpage = 1;
  int curpage = 1;
  int numofresult = 0;
  late double screenWidth, screenHeight;
  var color;
  String status = "Searching...";
  bool isLoading = false;

  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    loadItems("all");
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Market Place"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade900, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => loadItems("all")),
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: showSearchDialog),
        ],
      ),
      body: RefreshIndicator(
        key: refreshKey,
        color: Colors.amber.shade900,
        onRefresh: () async => loadItems("all"),
        child: itemList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status == "Searching..." ? Icons.search : Icons.search_off,
                      size: 80,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Try adjusting your search or check back later.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (isLoading)
                    LinearProgressIndicator(
                      value: curpage / numofpage,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.amber.shade900,
                      minHeight: 4,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    child: Text(
                      "Number of Result: $numofresult of $numofpage page/s",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: itemList.length,
                      itemBuilder: (context, index) {
                        final item = itemList[index];
                        final imageUrl =
                            "${MyConfig.myurl}unigo/assets/images/items/item-${item.itemId}.png";
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: InkWell(
                            splashColor: Colors.purple.shade200,
                            onTap: () => showItemDetails(item, user),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      imageUrl,
                                      width: screenWidth * 0.2,
                                      height: screenHeight * 0.14,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 80),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          truncateString(item.itemName ?? '', 15),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.purple.shade600),
                                        ),
                                        Row(
                                          children: [
                                            Text("Price/Qty: RM ${item.itemPrice}"),
                                            const SizedBox(width: 5),
                                            const Text("|",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red)),
                                            const SizedBox(width: 5),
                                            Text("${item.itemQty}"),
                                          ],
                                        ),
                                        Text("Delivery: ${item.itemDelivery}"),
                                        Text("Uni: ${(item.userUniversity ?? "N/A").toUpperCase()}"),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.red),
                                    onPressed: () => addtoFavDialog(item),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: screenHeight * 0.05,
                    child: ListView.builder(
                      itemCount: numofpage,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        color = (curpage - 1) == index
                            ? Colors.purple.shade600
                            : Colors.black;
                        return TextButton(
                          onPressed: () {
                            curpage = index + 1;
                            loadItems("all");
                          },
                          child: Text("${index + 1}",
                              style: TextStyle(color: color, fontSize: 18)),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (user?.userId == "0" || user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please login to add items.")),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewItemScreen(user: user!),
              ),
            );
            loadItems("all");
          }
        },
        child: const Icon(Icons.add),
      ),
      drawer: user == null ? null : MyDrawer(user: user),
    );
  }

  String truncateString(String str, int length) {
    return (str.length > length) ? "${str.substring(0, length)}..." : str;
  }

  void loadItems(String query) {
    setState(() => isLoading = true);
    http
        .get(Uri.parse("${MyConfig.myurl}unigo/php/load_items.php?search=$query&pageno=$curpage"))
        .then((response) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          itemList = List<Item>.from(data['data'].map((item) => Item.fromJson(item)));
          numofpage = int.tryParse(data['numofpage'].toString()) ?? 1;
          numofresult = int.tryParse(data['numberofresult'].toString()) ?? 0;
        } else {
          itemList.clear();
          status = "No item found";
        }
      }
      isLoading = false;
      setState(() {});
    });
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "-";
    try {
      final dateTime = DateTime.parse(rawDate);
      return DateFormat("dd/MM/yyyy").format(dateTime);
    } catch (_) {
      return rawDate;
    }
  }

  // KEEP EXISTING METHODS like:
  // showItemDetails(item, user)
  // _launchDialer, _launchWhatsApp
  // _showMessagePopup
  // _sendMessage
  // showMessageSentPopup
  // addtoFavDialog, addtoFav
  // showSearchDialog

  // (No changes needed for those unless you want to migrate them to a provider too)
}
