import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, this.api});

  final ProductApi? api;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late final ProductApi _api;
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ProductApi();
    _productsFuture = _api.fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    final request = _api.fetchProducts();
    setState(() => _productsFuture = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder presents the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Memuat produk Gaia...'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final products = snapshot.data ?? [];
        final query = _query.toLowerCase();
        final filtered = products.where((product) {
          return product.title.toLowerCase().contains(query) ||
              product.categoryName.toLowerCase().contains(query);
        }).toList();

        return RefreshIndicator(
          onRefresh: _retry,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temukan preloved pilihan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Fashion yang lebih baik untuk bumi.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari produk atau kategori',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Produk tidak ditemukan.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 700 ? 3 : 2;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _ProductCard(product: filtered[index]),
                          childCount: filtered.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.64,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailPage(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _ProductImage(url: product.imageUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _rupiah(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _ProductImage(url: product.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.categoryName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _rupiah(product.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Divider(height: 32),
                Text('Kondisi: ${_conditionLabel(product.condition)}'),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description.isEmpty
                      ? 'Belum ada deskripsi.'
                      : product.description,
                ),
                const SizedBox(height: 20),
                Text('Dijual oleh ${product.sellerName}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.checkroom_outlined, size: 56),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Produk belum bisa dimuat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
}

String _rupiah(int value) {
  final digits = value.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp$grouped';
}

String _conditionLabel(String value) => switch (value) {
      'excellent' => 'Sangat baik',
      'good' => 'Baik',
      'signs_of_wear' => 'Ada tanda pemakaian',
      _ => value,
    };
