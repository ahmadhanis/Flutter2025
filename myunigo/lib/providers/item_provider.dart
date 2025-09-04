import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myunigo/core/constants/my_config.dart';
import 'package:myunigo/models/item.dart';

import 'package:url_launcher/url_launcher_string.dart';


class ItemProvider with ChangeNotifier {
  void launchDialer(String phone) {
    launchUrlString('tel://$phone');
  }

  void launchWhatsApp(String phone) {
    launchUrlString(
        'https://wa.me/$phone?text=Hello%20I%20am%20interested%20in%20your%20item.');
  }

  void showMessagePopup({
    required BuildContext context,
    required String receiverId,
    required String senderId,
    required String itemId,
    required String itemName,
  }) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Message"),
        content: TextField(
          controller: messageController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Enter your message",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                sendMessage(
                  context: context,
                  senderId: senderId,
                  receiverId: receiverId,
                  content: messageController.text.trim(),
                  productId: itemId,
                  productName: itemName,
                );
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Message cannot be empty."),
                ));
              }
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  Future<void> sendMessage({
    required BuildContext context,
    required String senderId,
    required String receiverId,
    required String content,
    required String productId,
    required String productName,
  }) async {
    final response = await http.post(
      Uri.parse("${MyConfig.myurl}unigo/php/send_message.php"),
      body: {
        "sender_id": senderId,
        "receiver_id": receiverId,
        "message_content": content,
        "product_id": productId,
        "product_name": productName,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        showMessageSentPopup(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: ${jsonResponse['message']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message.")),
      );
    }
  }

  void showMessageSentPopup(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: MediaQuery.of(context).size.width * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade600,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Center(
              child: Text("Message sent", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), overlayEntry.remove);
  }

  void showAddToFavDialog(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add to Favorites"),
        content: const Text("Add this item to your favorites?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              addToFav(context, item);
              Navigator.of(context).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> addToFav(BuildContext context, Item item) async {
    final db = await DBHelper.instance.database;
    final existing = await db.query(
      'tbl_items',
      where: 'item_id = ? AND user_id = ?',
      whereArgs: [item.itemId, item.userId],
    );

    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item already in favorites.")),
      );
      return;
    }

    await db.insert('tbl_items', item.toJson());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item added to favorites.")),
    );
  }

  void showSearchDialog(BuildContext context, void Function(String) onSearch) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Search Items"),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(labelText: "Enter item name or keyword"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final searchTerm = searchController.text.trim();
              if (searchTerm.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Please enter a search term."),
                ));
              } else {
                onSearch(searchTerm);
                Navigator.of(context).pop();
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }
}
