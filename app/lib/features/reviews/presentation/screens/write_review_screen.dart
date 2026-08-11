import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/reviews_provider.dart";
import "../../../../core/network/api_result.dart";
import "../../../../core/theme/app_theme.dart";

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String productId;
  const WriteReviewScreen({super.key, required this.productId});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  double _rating = 5;
  bool _submitting = false;
  String? _error;
  final _controller = TextEditingController();

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = "Share a few words about the product");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(reviewsRepositoryProvider);
    final result = await repo.create(productId: widget.productId, rating: _rating, comment: _controller.text.trim());
    setState(() => _submitting = false);
    switch (result) {
      case ApiSuccess():
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted — thank you!")));
        }
      case ApiFailure(message: final msg):
        setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Write a Review")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Rating", style: displayFont(fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _rating = (i + 1).toDouble()),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Share your experience with this product...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                errorText: _error,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("SUBMIT REVIEW"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
