# FastBite

# FastBite - Aplicativo de Delivery de Comida (Estilo iFood)

Bem-vindo ao FastBite! Este é um aplicativo de delivery de comida desenvolvido em Flutter, com o objetivo de fornecer uma plataforma completa tanto para clientes que desejam pedir comida quanto para restaurantes que querem gerenciar seus cardápios e pedidos. O projeto utiliza Firebase como backend para autenticação, banco de dados (Cloud Firestore) e armazenamento de imagens (Firebase Storage).

##  Screenshots (Exemplos)

## Funcionalidades Implementadas

O aplicativo é dividido em duas interfaces principais: Cliente e Restaurante.

**Para Clientes:**

* **Autenticação:**
    * Registo de nova conta de cliente.
    * Login com e-mail e senha (integrado com Firebase Authentication).
    * Logout seguro.
    * Opção de alterar senha.
* **Navegação e Descoberta:**
    * **Tela Inicial (`HomeScreen`):**
        * Visualização de categorias de comida.
        * Filtragem de pratos por categoria selecionada.
        * Busca textual por restaurantes ou pratos.
        * Seção "Descubra Novos Sabores" com pratos de diversos restaurantes.
        * Banner promocional clicável (leva para a tela de um restaurante específico).
    * Navegação para a tela de detalhes do restaurante.
    * Navegação para a tela de detalhes do prato.
* **Interação com Restaurantes e Pratos:**
    * Visualização do cardápio de um restaurante.
    * Adicionar/remover pratos à sacola de compras.
    * Marcar restaurantes e pratos como favoritos.
    * **Avaliações e Comentários:**
        * Avaliar restaurantes com estrelas (1-5).
        * Escrever comentários textuais sobre restaurantes.
        * Avaliar pratos individuais com estrelas (1-5).
        * Escrever comentários textuais sobre pratos.
        * Visualizar avaliações e comentários de outros utilizadores.
* **Checkout e Pedidos:**
    * Visualização da sacola de compras.
    * Seleção de endereço de entrega (com CRUD de endereços).
    * Seleção de forma de pagamento (com CRUD de cartões - simulado, sem dados reais).
    * Cálculo de subtotal, taxa de entrega e total do pedido (com valores em centavos internamente, exibidos em reais).
    * Opções de parcelamento (simuladas) para cartão de crédito.
    * Confirmação e finalização do pedido (salvo no Firestore).
    * **Histórico de Pedidos (`OrderHistoryScreen`):** Visualização dos pedidos feitos, com status e detalhes.
* **Perfil do Cliente:**
    * Visualização dos dados do perfil.
    * **Edição de Perfil (`EditClientProfileScreen`):**
        * Alterar nome.
        * Selecionar/tirar foto de perfil e fazer upload para Firebase Storage.
    * Opção de encerrar a conta (com reautenticação e exclusão de dados via Cloud Functions - recomendado).

**Para Restaurantes:**

* **Autenticação:**
    * Registo de nova conta de restaurante (associada a um utilizador).
    * Login e Logout (integrado com Firebase Authentication).
* **Painel do Restaurante (`RestaurantDashboardScreen`):**
    * Visão geral e navegação para funcionalidades do restaurante.
* **Gerenciamento de Cardápio (`ManageMenuScreen`):**
    * Adicionar novos pratos (`AddEditDishScreen`).
    * Editar pratos existentes.
    * Remover pratos do cardápio.
    * **Seleção de Imagem do Prato:** Escolher imagem da galeria/câmera e fazer upload para Firebase Storage.
    * **Seleção de Múltiplas Categorias para Pratos:** Associar um prato a uma ou mais categorias existentes (ex: "Petiscos", "Principais").
* **Gerenciamento de Pedidos (`RestaurantOrdersScreen`):**
    * Visualizar pedidos recebidos pelos clientes.
    * Atualizar status dos pedidos: "Pendente" -> "Em Preparo" -> "A Caminho" -> "Entregue".
    * Opção de cancelar pedidos.
* **Perfil do Restaurante (`EditRestaurantProfileScreen`):**
    * Editar informações do restaurante (nome, descrição, imagem principal).
    * **Seleção de Imagem de Perfil/Banner:** Escolher imagem da galeria/câmera e fazer upload.
    * Opção de encerrar a conta (com reautenticação e exclusão de dados).

**Funcionalidades Gerais:**

* **Gerenciamento de Estado:** Utilização do `Provider` para um gerenciamento de estado reativo e organizado.
* **Tema:** Suporte a tema claro e escuro, com preferência salva localmente (`ThemeProvider` e `SharedPreferences`).
* **Persistência de Dados:**
    * Cloud Firestore para dados principais (utilizadores, restaurantes, pratos, pedidos, reviews, favoritos).
    * Firebase Storage para imagens (perfis, pratos, restaurantes).
    * `SharedPreferences` para preferências locais (tema, sacola de compras).
* **Formatação:** Uso do pacote `intl` para formatação de datas e valores monetários.
* **Navegação:** Uso de `Navigator.push`, `Navigator.pushNamed` e `Navigator.pushNamedAndRemoveUntil`.
* **Widgets Reutilizáveis:** Componentes como `AppDrawer`, `getAppBar`, cards de prato e restaurante.

## Tecnologias Utilizadas

* **Flutter & Dart:** Framework e linguagem principal para desenvolvimento multiplataforma.
* **Firebase:**
    * **Firebase Authentication:** Para registo, login e gerenciamento de utilizadores.
    * **Cloud Firestore:** Banco de dados NoSQL para armazenar todos os dados da aplicação.
    * **Firebase Storage:** Para armazenamento de arquivos de imagem.
    * **(Recomendado) Cloud Functions for Firebase:** Para lógica de backend, como exclusão de dados em cascata ao encerrar contas.
* **Provider:** Para gerenciamento de estado.
* **Pacotes Flutter/Dart:**
    * `intl`: Para internacionalização e formatação (datas, números, moedas).
    * `uuid`: Para gerar IDs únicos.
    * `shared_preferences`: Para armazenamento local de preferências simples.
    * `image_picker`: Para selecionar imagens da galeria ou câmera.
    * `cached_network_image`: Para exibir e armazenar em cache imagens da rede (URLs do Firebase Storage).
    * `flutter_rating_bar`: Para a UI de seleção e exibição de estrelas de avaliação.
    * `badges`: Para o contador na sacola de compras.
    * `collection`: Para utilitários de coleção (ex: `firstWhereOrNull`).

## Configuração do Projeto Localmente

1.  **Pré-requisitos:**
    * Flutter SDK instalado (verifique a versão no `pubspec.yaml` ou use a mais recente estável).
    * Um editor de código como VS Code ou Android Studio.
    * Node.js e npm (para a Firebase CLI e o script de população, se for usá-lo).
    * Firebase CLI instalada e logada (`firebase login`).
    * FlutterFire CLI instalada (`dart pub global activate flutterfire_cli`).

2.  **Clonar o Repositório:**
    ```bash
    git clone [https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git](https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git)
    cd SEU_REPOSITORIO
    ```

3.  **Configurar Projeto Firebase:**
    * Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
    * Registre seus aplicativos Android e iOS neste projeto.
        * **Android:** Adicione o `applicationId` (ex: `com.example.myapp`) e baixe o arquivo `google-services.json`. Coloque este arquivo na pasta `android/app/` do seu projeto Flutter.
        * **iOS:** Adicione o `Bundle ID` e baixe o arquivo `GoogleService-Info.plist`. Adicione este arquivo ao seu projeto iOS via Xcode, na pasta `Runner`.
    * No terminal, na raiz do seu projeto Flutter, rode:
        ```bash
        flutterfire configure
        ```
        Selecione o projeto Firebase criado e as plataformas desejadas. Isso irá gerar o arquivo `lib/firebase_options.dart`.

4.  **Instalar Dependências do Flutter:**
    ```bash
    flutter pub get
    ```

5.  **Configurar Arquivos Gradle (Android):**
    * Verifique se os arquivos `android/build.gradle.kts` (ou `.gradle`) e `android/app/build.gradle.kts` (ou `.gradle`) estão com as versões corretas dos plugins do Android Gradle, Kotlin e Google Services, conforme as correções que fizemos.
    * Certifique-se de que o `minSdkVersion` em `android/app/build.gradle.kts` é pelo menos `23`.
    * Certifique-se de que o `ndkVersion` está especificado em `android/app/build.gradle.kts` conforme os avisos (ex: `"27.0.12077973"`).

6.  **Popular Dados Iniciais (Opcional, se usar o script):**
    * Certifique-se de que seu arquivo `assets/data.json` está correto (preços em centavos, pratos com campo `categories`).
    * Ajuste os caminhos no script `populate_firestore.js` para o seu arquivo de chave de serviço do Firebase Admin e para o `data.json`.
    * Execute o script (requer Node.js e `npm install firebase-admin fs` na pasta do script):
        ```bash
        node caminho/para/seu/populate_firestore.js
        ```

7.  **Executar o Aplicativo:**
    * Conecte um emulador ou dispositivo.
    * Rode:
        ```bash
        flutter run
        ```
    * Se encontrar problemas de renderização no Android, tente:
        ```bash
        flutter run --no-enable-impeller
        ```

## Estrutura do Projeto (Simplificada `lib/`)

lib/├── data/                  # Lógica de dados, providers de dados (RestaurantData)├── model/                 # Modelos de dados (User, Restaurant, Dish, Order, Review, etc.)├── services/              # Serviços (ex: ImageUploadService)├── ui/                    # Widgets e telas da interface do utilizador│   ├── _core/             # Widgets e providers centrais/globais (AuthProvider, ThemeProvider, AppColors, AppDrawer, etc.)│   ├── auth/              # Telas de Login, Registro│   ├── checkout/          # Telas do fluxo de checkout│   ├── dish/              # Tela de detalhes do prato│   ├── favorites/         # Tela de favoritos│   ├── help/              # Tela de ajuda (se implementada)│   ├── home/              # Tela inicial e seus widgets específicos│   ├── orders/            # Telas de histórico e detalhes de pedidos│   ├── profile/           # Telas de edição de perfil do cliente│   ├── restaurant/        # Tela de detalhes do restaurante (visão do cliente)│   ├── restaurant_dashboard/ # Painel do restaurante│   ├── restaurant_menu/   # Telas de gerenciamento de cardápio│   ├── restaurant_orders/ # Tela de pedidos recebidos pelo restaurante│   ├── restaurant_profile/ # Tela de edição de perfil do restaurante│   ├── settings/          # Tela de configurações│   └── splash/            # Tela de splash inicial├── firebase_options.dart  # Configuração do Firebase (gerada)├── main_app_wrapper.dart  # Widget que decide entre Login ou Home/Dashboard└── main.dart              # Ponto de entrada principal da aplicação
## Funcionalidades Futuras (TODO)

* Integração com Gateway de Pagamento Real (Stripe, Mercado Pago, etc.).
* Rastreamento de Pedidos em Tempo Real no Mapa.
* Notificações Push (Firebase Cloud Messaging) para status de pedidos, promoções.
* Melhorias na UI/UX.
* Testes Unitários, de Widget e de Integração.
* Otimizações de performance.
* Busca de restaurantes por localização (GPS).
* Filtros mais avançados (preço, tempo de entrega, etc.).

## Contribuições

Contribuições são bem-vindas! Por favor, abra uma issue para discutir grandes mudanças ou novas funcionalidades antes de submeter um Pull Request.

## Licença

Este projeto é licenciado sob a Licença MIT - veja o arquivo `LICENSE.md` para detalhes (se você adicionar um).
