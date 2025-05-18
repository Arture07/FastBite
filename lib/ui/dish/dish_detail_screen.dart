import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/review.dart'; // <<< IMPORTAR REVIEW MODEL
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/_core/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/ui/_core/auth_provider.dart';

class DishDetailScreen extends StatefulWidget { // <<< ALTERADO PARA STATEFULWIDGET
  final Dish dish;
  final String restaurantId;

  const DishDetailScreen({
    super.key,
    required this.dish,
    required this.restaurantId,
  });

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> { // <<< CLASSE STATE CRIADA
  List<Review> _dishReviews = [];
  bool _isLoadingReviews = false;
  final TextEditingController _dishCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDishReviews();
  }

  @override
  void didUpdateWidget(covariant DishDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dish.id != oldWidget.dish.id || widget.restaurantId != oldWidget.restaurantId) {
      _loadDishReviews();
    }
  }
  
  @override
  void dispose() {
    _dishCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadDishReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await context.read<RestaurantData>().getDishReviews(widget.restaurantId, widget.dish.id);
      if (mounted) {
        setState(() {
          _dishReviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar avaliações do prato: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _showDishRatingReviewDialog(BuildContext context, Dish currentDish, String currentRestaurantId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantDataProvider = Provider.of<RestaurantData>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Você precisa estar logado para avaliar pratos.")),
      );
      return;
    }
    final String userId = authProvider.currentUser!.id;
    final String userName = authProvider.currentUser!.name;
    double userDishRating = 3.0;
    _dishCommentController.clear();

    // Opcional: Buscar avaliação/comentário anterior do utilizador para este prato
    // try {
    //   final existingReview = await restaurantDataProvider.getDishReviews(currentRestaurantId, currentDish.id, limit: 100)
    //       .then((reviews) => reviews.firstWhere((r) => r.userId == userId, orElse: () => Review(id: '', userId: '', userName: '', rating: 0, timestamp: DateTime.now())));
    //   if (existingReview.id.isNotEmpty && existingReview.rating > 0) {
    //     userDishRating = existingReview.rating;
    //     _dishCommentController.text = existingReview.comment ?? '';
    //   }
    // } catch (e) {
    //   debugPrint("Nenhuma avaliação anterior encontrada para o utilizador $userId no prato ${currentDish.id}");
    // }


    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        double currentDialogRating = userDishRating;
        return AlertDialog(
          title: Text('Avaliar "${currentDish.name}"'),
          content: StatefulBuilder(
            builder: (context, setDialogState){
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Sua nota para este prato:'),
                    const SizedBox(height: 10),
                    Center(
                      child: RatingBar.builder(
                        initialRating: currentDialogRating,
                        minRating: 1,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {
                          currentDialogRating = rating;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Seu comentário (opcional):'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dishCommentController,
                      decoration: const InputDecoration(
                        hintText: "Descreva sua experiência...",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              );
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () async {
                if (currentDialogRating > 0) {
                  try {
                    await restaurantDataProvider.submitDishReview(
                          restaurantId: currentRestaurantId,
                          dishId: currentDish.id,
                          userId: userId,
                          userName: userName,
                          rating: currentDialogRating,
                          comment: _dishCommentController.text.trim().isNotEmpty ? _dishCommentController.text.trim() : null,
                        );
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avaliação do prato enviada!')),
                    );
                    _loadDishReviews(); // Recarrega reviews do prato
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao avaliar prato: ${e.toString().replaceFirst("Exception: ", "")}')),
                    );
                  }
                } else {
                   ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Por favor, selecione uma nota em estrelas.')),
                    );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    // Usa widget.dish para o prato inicial, mas currentDisplayDish para o prato atualizado do provider
    final bool isFavorite = favoritesProvider.isDishFavorite(widget.dish.id);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.compact(locale: 'pt_BR');

    // Ouve o RestaurantData para obter a versão mais atualizada do prato
    final Dish currentDisplayDish = context.select<RestaurantData, Dish>(
      (data) {
        try {
          final restaurant = data.listRestaurant.firstWhere((r) => r.id == widget.restaurantId);
          return restaurant.dishes.firstWhere((d) => d.id == widget.dish.id);
        } catch (e) {
          debugPrint("DishDetailScreen: Prato ${widget.dish.id} não encontrado no provider, usando dados iniciais. Erro: $e");
          return widget.dish; 
        }
      }
    );

    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: currentDisplayDish.name,
        customActions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : null),
            tooltip: isFavorite ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos',
            onPressed: () => context.read<FavoritesProvider>().toggleDishFavorite(currentDisplayDish.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/${currentDisplayDish.imagePath}',
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container( /* ... */ ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentDisplayDish.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row( // Linha para avaliação do PRATO
                    children: [
                      if (currentDisplayDish.ratingCount > 0) ...[
                        RatingBarIndicator(
                          rating: currentDisplayDish.averageRating,
                          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 20.0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentDisplayDish.averageRating.toStringAsFixed(1)} (${numberFormat.format(currentDisplayDish.ratingCount)} aval.)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ] else ...[
                        Text('Sem avaliações ainda.', style: theme.textTheme.bodySmall)
                      ],
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Avaliar Prato'),
                        onPressed: () {
                           _showDishRatingReviewDialog(context, currentDisplayDish, widget.restaurantId);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormat.format(currentDisplayDish.price / 100.0),
                    style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text("Descrição", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(currentDisplayDish.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  const SizedBox(height: 16),
                  if (currentDisplayDish.categories.isNotEmpty) ...[ /* ... Categorias ... */ ],
                  const SizedBox(height: 24),

                  // <<< NOVA SEÇÃO PARA EXIBIR REVIEWS DO PRATO >>>
                  Text("Avaliações do Prato", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _isLoadingReviews
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                    : _dishReviews.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text("Nenhuma avaliação para este prato ainda."))
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _dishReviews.length,
                            itemBuilder: (context, index) {
                              final review = _dishReviews[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row( /* ... Nome, Estrelas, Data da Review ... */ ),
                                      if (review.comment != null && review.comment!.isNotEmpty) ...[
                                        const SizedBox(height: 8.0),
                                        Text(review.comment!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.justify,),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [ BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, -2)) ],
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text("Adicionar à Sacola"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          onPressed: () {
            context.read<BagProvider>().addAllDishes([currentDisplayDish], widget.restaurantId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${currentDisplayDish.name} adicionado à sacola!'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
}
