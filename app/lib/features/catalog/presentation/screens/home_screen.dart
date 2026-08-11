import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/catalog_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/product_card.dart";
import "../../../../core/widgets/shimmer_loader.dart";
import "../../../../core/widgets/error_view.dart";
import "../../../../core/widgets/marquee_ticker.dart";
import "../../../wishlist/presentation/providers/wishlist_provider.dart";
import "../../../notifications/presentation/providers/notifications_provider.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _navSolid = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final solid = _scrollController.offset > 40;
      if (solid != _navSolid) setState(() => _navSolid = solid);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.paper,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: AnimatedContainer(
          duration: AppDurations.medium,
          color: _navSolid ? AppColors.paper.withOpacity(0.96) : Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(onPressed: () => context.push("/search"), icon: const Icon(Icons.search, color: AppColors.ink)),
                  Expanded(
                    child: Center(
                      child: Text("SEVENTH", style: displayFont(fontSize: 20, letterSpacing: 1.2)),
                    ),
                  ),
                  _NotificationBell(onTap: () => context.push("/notifications")),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productsProvider(null)),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context),
              const MarqueeTicker(text: "NEW DROP — VOL. 07     FREE SHIPPING OVER RS 5000     LIMITED RUN"),
              _buildSpotlight(context),
              _buildYouMayLike(context, productsAsync),
              _buildEditorialBand(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.push("/search");
          if (i == 2) context.push("/cart");
          if (i == 3) context.push("/wishlist");
          if (i == 4) context.push("/profile");
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 520,
          width: double.infinity,
          child: Image.network(
            "https://picsum.photos/seed/sw-hero-mobile/900/1200",
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 520,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC15130F)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("VOLUME 07 — CLOUD SERIES", style: eyebrowFont(color: AppColors.paper)),
              const SizedBox(height: 10),
              Text("Worn In\nSilence", style: displayFont(fontSize: 46, color: AppColors.paper)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  color: AppColors.paper,
                  child: Text("SHOP THE DROP", style: eyebrowFont(color: AppColors.ink)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FEATURED — 01 / HOODIE", style: eyebrowFont()),
          const SizedBox(height: 8),
          Text("V2 Hoodie\nin Cloud", style: displayFont(fontSize: 34)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push("/product/p1"),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.network("https://picsum.photos/seed/sw-p1-a/900/1100", fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Rs 8,900", style: displayFont(fontSize: 22)),
              const SizedBox(width: 10),
              Text("Rs 11,200", style: bodyFont(fontSize: 13, color: AppColors.inkSoft).copyWith(decoration: TextDecoration.lineThrough)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Double-lined hood, dropped shoulder seam, brushed interior fleece.",
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push("/product/p1"),
                  child: const Text("SHOP THIS LOOK"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYouMayLike(BuildContext context, AsyncValue productsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SELECTED FOR YOU", style: eyebrowFont()),
          const SizedBox(height: 8),
          Text("You May\nLike It", style: displayFont(fontSize: 30)),
          const SizedBox(height: 20),
          productsAsync.when(
            loading: () => const SizedBox(height: 320, child: ShimmerGrid(itemCount: 4)),
            error: (err, _) => SizedBox(
              height: 220,
              child: ErrorView(message: "Could not load products", onRetry: () => ref.invalidate(productsProvider(null))),
            ),
            data: (products) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length > 4 ? 4 : products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final wishlist = ref.watch(wishlistProvider);
                return ProductCard(
                  product: p,
                  tag: p.badge,
                  isWishlisted: wishlist.ids.contains(p.id),
                  onTap: () => context.push("/product/${p.id}"),
                  onToggleWishlist: () => ref.read(wishlistProvider.notifier).toggle(p.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialBand(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 56),
      color: AppColors.woodDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network("https://picsum.photos/seed/sw-editorial-mobile/900/700", fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.15), colorBlendMode: BlendMode.darken),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("THE ARCHIVE", style: eyebrowFont(color: AppColors.olive)),
                const SizedBox(height: 10),
                Text("Built From\nThe Ground Up", style: displayFont(fontSize: 30, color: AppColors.paper)),
                const SizedBox(height: 14),
                Text(
                  "Seven seasons in, still cut and sewn in small batches. No overproduction, no filler drops.",
                  style: bodyFont(fontSize: 13, color: const Color(0xFFCFC7B8)),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.paper, side: const BorderSide(color: AppColors.paper)),
                  onPressed: () => context.push("/profile"),
                  child: const Text("READ THE STORY"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        label: Text("$unread"),
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.rust,
        child: const Icon(Icons.notifications_none, color: AppColors.ink),
      ),
    );
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AnimatedBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      animationDuration: AppDurations.medium,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Home"),
        NavigationDestination(icon: Icon(Icons.search), label: "Search"),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: "Bag"),
        NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: "Wishlist"),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
