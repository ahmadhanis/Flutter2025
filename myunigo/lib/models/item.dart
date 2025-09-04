class Item {
  final String itemId;
  final String userId;
  final String itemName;
  final String itemDesc;
  final String itemStatus;
  final String itemQty;
  final String itemPrice;
  final String itemDelivery;
  final String itemDate;
  final String userName;
  final String userPhone;
  final String userUniversity;

  Item({
    required this.itemId,
    required this.userId,
    required this.itemName,
    required this.itemDesc,
    required this.itemStatus,
    required this.itemQty,
    required this.itemPrice,
    required this.itemDelivery,
    required this.itemDate,
    required this.userName,
    required this.userPhone,
    required this.userUniversity,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['item_id'] ?? '',
      userId: json['user_id'] ?? '',
      itemName: json['item_name'] ?? '',
      itemDesc: json['item_desc'] ?? '',
      itemStatus: json['item_status'] ?? '',
      itemQty: json['item_qty'] ?? '',
      itemPrice: json['item_price'] ?? '',
      itemDelivery: json['item_delivery'] ?? '',
      itemDate: json['item_date'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userUniversity: json['user_university'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'user_id': userId,
      'item_name': itemName,
      'item_desc': itemDesc,
      'item_status': itemStatus,
      'item_qty': itemQty,
      'item_price': itemPrice,
      'item_delivery': itemDelivery,
      'item_date': itemDate,
      'user_name': userName,
      'user_phone': userPhone,
      'user_university': userUniversity,
    };
  }
}
