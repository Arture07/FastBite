// lib/ui/restaurant/restaurant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/model/review.dart'; // Para exibir reviews
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/_core/widgets/appbar.dart';
import 'package:myapp/ui/home/widgets/vertical_dish_list_item.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RestaurantScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantScreen({super.key, required this.restaurant});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<Review> _restaurantReviews = [];
  bool _isLoadingReviews = false;
  // <<< CONTROLADOR PARA O COMENTÁRIO DO RESTAURANTE >>>
  final TextEditingController _restaurantCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurantReviews();
  }

  @override
  void didUpdateWidget(covariant RestaurantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restaurant.id != oldWidget.restaurant.id) {
      _loadRestaurantReviews();
    }
  }
  
  @override
  void dispose() {
    _restaurantCommentController.dispose(); // <<< FAZER DISPOSE DO CONTROLLER
    super.dispose();
  }

  Future<void> _loadRestaurantReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await context.read<RestaurantData>().getRestaurantReviews(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _restaurantReviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar avaliações: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext screenContext, Restaurant currentRestaurant) async {
    final authProvider = Provider.of<AuthProvider>(screenContext, listen: false);
    final restaurantDataProvider = Provider.of<RestaurantData>(screenContext, listen: false);

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      if (!screenContext.mounted) return;
      ScaffoldMessenger.of(screenContext).showSnackBar(
        const SnackBar(content: Text("Você precisa estar logado para avaliar.")),
      );
      return;
    }
    final String userId = authProvider.currentUser!.id;
    // <<< OBTÉM O NOME DO UTILIZADOR CORRETAMENTE >>>
    final String userName = authProvider.currentUser!.name; 
    double userRating = 3.0; 
    _restaurantCommentController.clear();

    // Opcional: Buscar avaliação/comentário anterior do utilizador
    // ...

    // Captura Navigator e ScaffoldMessenger ANTES do await para o showDialog
    final navigator = Navigator.of(screenContext); // Usa o context da tela
    final scaffoldMessenger = ScaffoldMessenger.of(screenContext);

    return showDialog<void>(
      context: screenContext,
      builder: (BuildContext dialogContext) { // Contexto específico do diálogo
        double currentDialogRating = userRating;
        
        return AlertDialog(
          title: Text('Avaliar ${currentRestaurant.name}'),
          content: StatefulBuilder( 
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Sua nota (1-5 estrelas):'),
                    const SizedBox(height: 10),
                    Center(
                      child: RatingBar.builder(
                        initialRating: currentDialogRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
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
                      // <<< USA O CONTROLLER CORRETO >>>
                      controller: _restaurantCommentController, 
                      decoration: const InputDecoration(
                        hintText: "Escreva seu comentário aqui...",
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
                if (currentDialogRating >= 1) { // Permite avaliação a partir de 1 estrela
                  bool success = false;
                  String errorMessage = 'Erro desconhecido.';
                  try {
                    await restaurantDataProvider.submitRestaurantReview(
                          restaurantId: currentRestaurant.id,
                          userId: userId,
                          userName: userName, // Passa o nome do utilizador
                          rating: currentDialogRating,
                          // <<< USA O CONTROLLER CORRETO >>>
                          comment: _restaurantCommentController.text.trim(),
                        );
                    success = true;
                  } catch (e) {
                    errorMessage = e.toString().replaceFirst("Exception: ", "");
                  }

                  // Usa os capturados ANTES do await
                  if (success) {
                    if (navigator.canPop()) navigator.pop(dialogContext); // Fecha o diálogo
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Avaliação enviada! Obrigado.')),
                    );
                    _loadRestaurantReviews(); 
                  } else {
                     if (navigator.canPop()) navigator.pop(dialogContext);
                     scaffoldMessenger.showSnackBar(
                       SnackBar(content: Text('Erro ao enviar avaliação: $errorMessage')),
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
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.compact(locale: 'pt_BR');

    final restaurantData = context.watch<RestaurantData>();
    Restaurant currentRestaurantDisplay;
    try {
      currentRestaurantDisplay = restaurantData.listRestaurant.firstWhere((r) => r.id == widget.restaurant.id);
    } catch (e) {
      currentRestaurantDisplay = widget.restaurant;
      debugPrint("RestaurantScreen: Fallback para widget.restaurant. Erro: $e");
    }
    final bool isRestaurantFavorite = favoritesProvider.isRestaurantFavorite(currentRestaurantDisplay.id);

    return Scaffold(
      appBar: getAppBar(
        context: context,
        title: currentRestaurantDisplay.name,
        customActions: [
          IconButton(
            icon: Icon(isRestaurantFavorite ? Icons.favorite : Icons.favorite_border, color: isRestaurantFavorite ? Colors.redAccent : null),
            tooltip: isRestaurantFavorite ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos',
            onPressed: () => context.read<FavoritesProvider>().toggleRestaurantFavorite(currentRestaurantDisplay.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.28,
              constraints: const BoxConstraints(maxHeight: 220), // Altura máxima
              child: Image.asset(
                  'assets/${currentRestaurantDisplay.imagePath}',
                   fit: BoxFit.cover,
                   errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: Center(child: Icon(Icons.storefront, color: Colors.grey[600], size: 50)),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentRestaurantDisplay.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: currentRestaurantDisplay.stars,
                        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 22.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentRestaurantDisplay.stars.toStringAsFixed(1)} (${numberFormat.format(currentRestaurantDisplay.ratingCount)} aval.)',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_outlined, size: 18),
                        label: const Text('Avaliar'),
                        onPressed: () {
                           _showRatingDialog(context, currentRestaurantDisplay);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(currentRestaurantDisplay.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Text("Cardápio", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16.0),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: currentRestaurantDisplay.dishes.length,
                    itemBuilder: (context, index) {
                      Dish dish = currentRestaurantDisplay.dishes[index];
                      return VerticalDishListItem(dish: dish, restaurantId: currentRestaurantDisplay.id);
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 16.0),
                  ),
                  const SizedBox(height: 24),
                  Text("Avaliações dos Clientes", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _isLoadingReviews
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                    : _restaurantReviews.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text("Nenhuma avaliação ainda. Seja o primeiro!"))
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _restaurantReviews.length,
                            itemBuilder: (context, index) {
                              final review = _restaurantReviews[index];
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
                                          CircleAvatar(backgroundColor: theme.colorScheme.secondaryContainer, child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : "?", style: TextStyle(color: theme.colorScheme.onSecondaryContainer))),
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
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
