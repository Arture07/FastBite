    // lib/model/address.dart
    import 'package:uuid/uuid.dart';

    class Address {
      final String id;
      final String street;
      final String number;
      final String complement;
      final String neighborhood;
      final String city;
      final String state;
      final String zipCode; // <<< CAMPO PARA O CEP

      Address({
        required this.id,
        required this.street,
        required this.number,
        this.complement = "",
        required this.neighborhood, // Tornando obrigatório se a API preenche
        required this.city,         // Tornando obrigatório se a API preenche
        required this.state,        // Tornando obrigatório se a API preenche
        required this.zipCode,      // Tornando obrigatório
      });

      String get formattedAddress =>
          '$street, $number${complement.isNotEmpty ? ' - $complement' : ''}';

      String get cityState =>
          city.isNotEmpty && state.isNotEmpty
              ? '$city - $state'
              : (city.isNotEmpty ? city : state);

      Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zipCode': zipCode,
      };

      factory Address.fromJson(Map<String, dynamic> json) {
        return Address(
          id: json['id'] ?? const Uuid().v4(),
          street: json['street'] ?? '',
          number: json['number'] ?? '',
          complement: json['complement'] ?? '',
          neighborhood: json['neighborhood'] ?? '',
          city: json['city'] ?? '',
          state: json['state'] ?? '',
          zipCode: json['zipCode'] ?? '',
        );
      }

      Address copyWith({
        String? id,
        String? street,
        String? number,
        String? complement,
        String? neighborhood,
        String? city,
        String? state,
        String? zipCode,
      }) {
        return Address(
          id: id ?? this.id,
          street: street ?? this.street,
          number: number ?? this.number,
          complement: complement ?? this.complement,
          neighborhood: neighborhood ?? this.neighborhood,
          city: city ?? this.city,
          state: state ?? this.state,
          zipCode: zipCode ?? this.zipCode,
        );
      }

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is Address && runtimeType == other.runtimeType && id == other.id;

      @override
      int get hashCode => id.hashCode;

      @override
      String toString() {
        return 'Address{id: $id, street: $street, number: $number, zipCode: $zipCode}';
      }
    }