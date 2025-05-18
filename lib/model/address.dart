// lib/model/address.dart
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos no fromJson como fallback

// Representa um endereço de entrega ou de usuário.
class Address {
  final String id; // Identificador único do endereço
  final String street; // Nome da rua, avenida, etc.
  final String number; // Número do imóvel
  final String complement; // Complemento (ex: Apto 101, Bloco B, Casa 2)
  final String neighborhood; // Bairro
  final String city; // Cidade
  final String state; // Estado ou UF (Unidade Federativa)
  // Adicione outros campos se necessário, como:
  // final String zipCode;   // CEP
  // final String country;   // País
  // final String reference; // Ponto de referência

  // Construtor da classe Address
  Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement = "", // Valor padrão vazio se não fornecido
    this.neighborhood = "", // Valor padrão vazio
    this.city = "", // Valor padrão vazio
    this.state = "", // Valor padrão vazio
    // required this.zipCode, // Tornar obrigatório se necessário
  });

  // --- Getters para Exibição Formatada ---

  // Retorna o endereço formatado (Rua, Número - Complemento)
  String get formattedAddress =>
      '$street, $number${complement.isNotEmpty ? ' - $complement' : ''}';

  // Retorna a cidade e estado formatados (Cidade - UF)
  String get cityState =>
      city.isNotEmpty && state.isNotEmpty
          ? '$city - $state'
          : (city.isNotEmpty ? city : state);

  // --- Métodos para Persistência (toJson/fromJson) ---

  // Converte o objeto Address para um Mapa (formato JSON)
  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'number': number,
    'complement': complement,
    'neighborhood': neighborhood,
    'city': city,
    'state': state,
    // 'zipCode': zipCode, // Adicionar se usar CEP
  };

  // Factory constructor para criar um objeto Address a partir de um Mapa (JSON)
  factory Address.fromJson(Map<String, dynamic> json) {
    // Usa os valores do JSON ou valores padrão/fallback se estiverem ausentes ou nulos
    return Address(
      id:
          json['id']?.toString() ??
          const Uuid().v4(), // Usa ID do JSON ou gera um novo
      street: json['street']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      complement: json['complement']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      // zipCode: json['zipCode']?.toString() ?? '', // Adicionar se usar CEP
    );
  }

  // --- Método copyWith (Útil para Edição) ---
  // Cria uma cópia do objeto Address, permitindo modificar campos específicos.
  Address copyWith({
    String? id,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    // String? zipCode,
  }) {
    // Usa o valor passado como argumento ou o valor atual do objeto (this)
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      // zipCode: zipCode ?? this.zipCode,
    );
  }

  // --- Overrides para Comparação e Debug ---

  // Define como dois objetos Address são considerados iguais (pelo ID)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address && runtimeType == other.runtimeType && id == other.id;

  // Define o código hash baseado no ID (importante para uso em Sets e Maps)
  @override
  int get hashCode => id.hashCode;

  // Representação em string do objeto (útil para debug)
  @override
  String toString() {
    return 'Address{id: $id, street: $street, number: $number}'; // Exemplo simplificado
  }
}
