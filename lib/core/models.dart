/// Data models mirroring Backend's `packages/contracts/src/index.ts` and the
/// platform DTOs in `Backend/src/platform/platform.dto.ts`.

/// 'prime-capital' | 'php-invest'
typedef InvestmentProduct = String;

const String kProductPrimeCapital = 'prime-capital';
const String kProductPhpInvest = 'php-invest';

class Balance {
  Balance({
    required this.id,
    required this.name,
    required this.amount,
    required this.monthlyChange,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double amount;
  final double monthlyChange;
  final String updatedAt;

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        monthlyChange: (json['monthlyChange'] as num?)?.toDouble() ?? 0,
        updatedAt: json['updatedAt'] as String? ?? '',
      );
}

/// 'new-build' | 'resale'
class PropertyListing {
  PropertyListing({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.price,
    required this.rooms,
    required this.area,
    required this.status,
    required this.createdAt,
    required this.views,
  });

  final String id;
  final String title;
  final String type;
  final String location;
  final double price;
  final int rooms;
  final double area;
  final String status;
  final String createdAt;
  final int views;

  bool get isNewBuild => type == 'new-build';

  factory PropertyListing.fromJson(Map<String, dynamic> json) => PropertyListing(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'new-build',
        location: json['location'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        rooms: (json['rooms'] as num?)?.toInt() ?? 0,
        area: (json['area'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'active',
        createdAt: json['createdAt'] as String? ?? '',
        views: (json['views'] as num?)?.toInt() ?? 0,
      );
}

class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.phpInvest,
    required this.primeCapital,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final double phpInvest;
  final double primeCapital;
  final String? photoUrl;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        phpInvest: (json['phpInvest'] as num?)?.toDouble() ?? 0,
        primeCapital: (json['primeCapital'] as num?)?.toDouble() ?? 0,
        photoUrl: json['photoUrl'] as String?,
      );
}

/// 'income' | 'expense'
class FinanceEntry {
  FinanceEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.note,
    this.date,
  });

  final String id;
  final String type;
  final String category;
  final double amount;
  final String? note;
  final String? date;

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'expense',
        category: json['category'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String?,
        date: json['date'] as String?,
      );
}

class NotificationButton {
  NotificationButton({required this.label, required this.url});
  final String label;
  final String url;

  factory NotificationButton.fromJson(Map<String, dynamic> json) => NotificationButton(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

/// Shared shape for banners / videos / notifications ("ContentItem" in the
/// Webapp/backend).
class ContentItem {
  ContentItem({
    required this.id,
    required this.title,
    this.description,
    this.url,
    this.imageUrl,
    this.videoUrl,
    this.buttons = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? url;
  final String? imageUrl;
  final String? videoUrl;
  final List<NotificationButton> buttons;

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        url: json['url'] as String?,
        imageUrl: json['imageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        buttons: (json['buttons'] as List<dynamic>?)
                ?.map((item) => NotificationButton.fromJson(item as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
