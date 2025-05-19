// lib/ui/dish/dish_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/review.dart';
import 'package:myapp/services/error_handler.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/_core/widgets/appbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DishDetailScreen extends StatefulWidget {
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

class _DishDetailScreenState extends State<DishDetailScreen> {
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
        ErrorHandler.handleGenericError(context, e, operation: "carregar avaliações do prato");
      }
    }
  }

  Future<void> _showDishRatingReviewDialog(BuildContext screenContext, Dish currentDish) async {
    final authProvider = Provider.of<AuthProvider>(screenContext, listen: false);
    final restaurantDataProvider = Provider.of<RestaurantData>(screenContext, listen: false);

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      if (!screenContext.mounted) return;
      ErrorHandler.handleGenericError(screenContext, "Você precisa estar logado para avaliar pratos.");
      return;
    }
    final String userId = authProvider.currentUser!.id;
    final String userName = authProvider.currentUser!.name;
    final String? userImagePath = authProvider.currentUser!.userImagePath;
    double userDishRating = 3.0; 
    _dishCommentController.clear();

    final navigator = Navigator.of(screenContext); 
    final scaffoldMessenger = ScaffoldMessenger.of(screenContext);

    return showDialog<void>(
      context: screenContext, 
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
              onPressed: () {
                // Usa o navigator do diálogo para fechar o diálogo
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            ),
            ElevatedButton(
              child: const Text('Enviar'),
              onPressed: () async {
                if (currentDialogRating >= 1) { 
                  bool success = false;
                  String? errorMessage; // Alterado para String?
                  try {
                    await restaurantDataProvider.submitDishReview(
                          restaurantId: widget.restaurantId, 
                          dishId: currentDish.id,
                          userId: userId,
                          userName: userName,
                          userImagePath: userImagePath,
                          rating: currentDialogRating,
                          comment: _dishCommentController.text.trim().isNotEmpty 
                                   ? _dishCommentController.text.trim() 
                                   : null, 
                        );
                    success = true;
                  } catch (e) {
                    errorMessage = e.toString().replaceFirst("Exception: ", "");
                  }

                  // Fecha o diálogo usando o contexto do diálogo, se ainda estiver montado
                  if (dialogContext.mounted) {
                     Navigator.of(dialogContext).pop();
                  }

                  // Mostra SnackBar usando o contexto da tela principal (screenContext), se montado
                  if (screenContext.mounted) {
                    if (success) {
                       scaffoldMessenger.showSnackBar(
                         const SnackBar(content: Text('Avaliação do prato enviada!'), backgroundColor: Colors.green),
                       );
                       _loadDishReviews(); 
                    } else {
                        ErrorHandler.handleGenericError(screenContext, errorMessage ?? "Erro ao enviar avaliação do prato.");
                    }
                  }
                } else {
                   if (dialogContext.mounted) { 
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Por favor, selecione uma nota em estrelas.')),
                      );
                   }
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
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.compact(locale: 'pt_BR');

    // <<< USA context.watch para reatividade >>>
    final restaurantData = context.watch<RestaurantData>();
    Dish currentDisplayDish;
    try {
      final restaurant = restaurantData.listRestaurant.firstWhere((r) => r.id == widget.restaurantId);
      currentDisplayDish = restaurant.dishes.firstWhere((d) => d.id == widget.dish.id);
    } catch (e) {
      // Se não encontrar (ex: lista ainda a carregar ou ID inválido), usa o prato original passado para o widget
      currentDisplayDish = widget.dish; 
      debugPrint("DishDetailScreen: Prato ${widget.dish.id} não encontrado no provider, usando dados iniciais do widget. Erro: $e");
    }
    final bool isFavorite = favoritesProvider.isDishFavorite(currentDisplayDish.id);


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
            // Imagem do Prato
            Image.asset(
              'assets/${currentDisplayDish.imagePath}',
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                 width: double.infinity,
                 height: MediaQuery.of(context).size.height * 0.3,
                 color: Colors.grey[800],
                 child: Center(child: Icon(Icons.fastfood_outlined, color: Colors.grey[600], size: 60)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentDisplayDish.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
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
                           _showDishRatingReviewDialog(context, currentDisplayDish);
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
                  if (currentDisplayDish.categories.isNotEmpty) ...[
                     Text("Categorias", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8.0,
                       runSpacing: 4.0,
                       children: currentDisplayDish.categories.map((category) => Chip(label: Text(category))).toList(),
                     ),
                  ],
                  const SizedBox(height: 24),

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
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: theme.colorScheme.secondaryContainer,
                                            backgroundImage: review.userImagePath != null && review.userImagePath!.startsWith('http')
                                                ? CachedNetworkImageProvider(review.userImagePath!)
                                                : null,
                                            child: (review.userImagePath == null || review.userImagePath!.isEmpty || !review.userImagePath!.startsWith('http'))
                                                ? Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "?", style: TextStyle(color: theme.colorScheme.onSecondaryContainer))
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(review.userName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                                RatingBarIndicator(
                                                  rating: review.rating,
                                                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                                  itemCount: 5,
                                                  itemSize: 16.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(DateFormat('dd/MM/yy').format(review.timestamp), style: theme.textTheme.bodySmall),
                                        ],
                                      ),
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
          boxShadow: [ BoxShadow(color: Colors.black.withAlpha((255 * 0.1).round()), blurRadius: 4, offset: const Offset(0, -2)) ],
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
            context.read<BagProvider>().addAllDishes([currentDisplayDish], widget.restaurantId); // <<< USA widget.restaurantId
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