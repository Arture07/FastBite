// lib/ui/help/help_screen.dart
import 'package:flutter/material.dart';
// Importar se for usar url_launcher para links/email/telefone
// import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Helper para construir um item de FAQ expansível
  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Card( // Agrupa pergunta e resposta visualmente
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0.5, // Sombra sutil
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile( // Widget expansível
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)), // Pergunta em negrito
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0), // Padding interno da resposta
        expandedAlignment: Alignment.topLeft, // Alinha resposta à esquerda
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        // Ícone personalizado para expandir/recolher (opcional)
        // trailing: Icon(Icons.expand_more),
        // initiallyExpanded: false, // Começa fechado por padrão
        children: [
          // Resposta
          Text(answer, style: TextStyle(color: Colors.grey[300], height: 1.4)), // Cor mais clara e espaçamento
        ],
      ),
    );
  }

  // --- Funções para abrir links (requer pacote url_launcher) ---
  // Future<void> _launchUrl(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  //     // Tratar erro se não conseguir abrir
  //     debugPrint("Não foi possível abrir $url");
  //   }
  // }
  // Future<void> _launchEmail(String email) async {
  //   final Uri emailLaunchUri = Uri( scheme: 'mailto', path: email, query: 'subject=Ajuda App Foodcourt');
  //   if (!await launchUrl(emailLaunchUri)) { debugPrint("Não foi possível abrir email"); }
  // }
  // Future<void> _launchPhone(String phone) async {
  //    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phone);
  //    if (!await launchUrl(phoneLaunchUri)) { debugPrint("Não foi possível ligar"); }
  // }
  // --- Fim Funções de Links ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajuda & Suporte"),
        elevation: 1.0,
      ),
      // Usar ListView para conteúdo potencialmente longo
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Padding geral
        children: [
          // --- Seção FAQ ---
          Text(
            "Perguntas Frequentes (FAQ)",
            // Estilo de título de seção
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16), // Espaçamento
          // Itens do FAQ usando o helper
          _buildFaqItem(
            context,
            question: "Como faço um pedido?",
            answer: "Navegue pelos restaurantes ou busque por pratos na tela inicial. Ao visualizar o cardápio de um restaurante, toque no botão '+' ao lado do prato desejado para adicioná-lo à sacola. Quando terminar, toque no ícone da sacola no canto superior direito. Na tela da Sacola, confira os itens, selecione ou adicione seu endereço de entrega e forma de pagamento. Por fim, clique em 'Confirmar Pedido'."
          ),
          _buildFaqItem(
            context,
            question: "Como vejo o status do meu pedido?",
            answer: "Após fazer login, abra o menu lateral (ícone no canto superior esquerdo) e toque em 'Meus Pedidos'. Você verá a lista de seus pedidos anteriores e o status atual de cada um (Pendente, Em Preparo, Entregue, Cancelado)."
          ),
           _buildFaqItem(
            context,
            question: "Como gerencio meus endereços e cartões?",
            answer: "Abra o menu lateral e selecione 'Meus Endereços' ou 'Formas de Pagamento'. Nessas telas, você pode visualizar os dados salvos, adicionar novos itens usando o botão '+ Adicionar', editar um item existente tocando no ícone de lápis (✏️) ou remover um item arrastando-o para a esquerda."
          ),
           _buildFaqItem(
            context,
            question: "Como favoritar/desfavoritar?",
            answer: "Na lista de restaurantes ou de pratos, toque no ícone de coração (♡). Ele ficará preenchido (❤️) indicando que o item foi favoritado. Toque novamente para desfavoritar. Para ver todos os seus favoritos, acesse 'Meus Favoritos' no menu lateral."
          ),
          // Adicione mais perguntas e respostas aqui...

          const Divider(height: 40, thickness: 1), // Divisor mais proeminente

          // --- Seção Contato ---
          Text(
            "Entre em Contato",
             style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Item para Email
          ListTile(
             leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
             title: const Text("Email de Suporte"),
             subtitle: const Text("suporte@foodcourtapp.com.br"), // <<< SUBSTITUIR pelo seu email real
             onTap: () {
                debugPrint("TODO: Abrir cliente de email");
                // _launchEmail('suporte@foodcourtapp.com.br'); // Descomentar se usar url_launcher
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Abrir email (TODO)")));
             },
             contentPadding: EdgeInsets.zero, // Remove padding padrão
          ),
          // Item para Telefone
           ListTile(
             leading: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.primary),
             title: const Text("Telefone (Horário Comercial)"),
             subtitle: const Text("(XX) XXXX-XXXX"), // <<< SUBSTITUIR pelo seu telefone real
              onTap: () {
                 debugPrint("TODO: Abrir discador");
                 // _launchPhone('+55XX...'); // Descomentar se usar url_launcher
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ligar (TODO)")));
              },
              contentPadding: EdgeInsets.zero,
          ),
          // Adicionar link para Website ou Redes Sociais se aplicável
        ],
      ),
    );
  }
}
