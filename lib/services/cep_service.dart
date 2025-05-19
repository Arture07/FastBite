    // lib/services/cep_service.dart
    import 'dart:convert';
    import 'package:flutter/foundation.dart';
    import 'package:http/http.dart' as http;
    import 'package:myapp/model/address.dart'; // Importa seu modelo Address

    class CepService {
      static const String _baseUrl = "https://viacep.com.br/ws/";

      /// Busca um endereço a partir de um CEP usando a API ViaCEP.
      /// Retorna um objeto Address se encontrado, ou null se não encontrado ou erro.
      Future<Address?> fetchAddressFromCep(String cep) async {
        // Limpa o CEP, deixando apenas dígitos
        final String cleanedCep = cep.replaceAll(RegExp(r'[^0-9]'), '');

        if (cleanedCep.length != 8) {
          debugPrint("CepService: CEP inválido (precisa de 8 dígitos): $cleanedCep");
          return null; // CEP precisa ter 8 dígitos
        }

        final String requestUrl = "$_baseUrl$cleanedCep/json/";
        debugPrint("CepService: Buscando CEP em $requestUrl");

        try {
          final response = await http.get(Uri.parse(requestUrl));

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(response.body);

            // ViaCEP retorna {"erro": true} se o CEP não for encontrado
            if (responseData.containsKey('erro') && responseData['erro'] == true) {
              debugPrint("CepService: CEP $cleanedCep não encontrado pela API.");
              return null;
            }

            // Mapeia a resposta da API para o seu modelo Address
            // Atenção aos nomes dos campos retornados pela ViaCEP:
            // logradouro, bairro, localidade (cidade), uf (estado), cep
            return Address(
              id: '', // O ID será gerado ao salvar, ou pode ser o próprio CEP se único
              street: responseData['logradouro'] ?? '',
              number: '', // ViaCEP não retorna número, o utilizador preenche
              complement: responseData['complemento'] ?? '',
              neighborhood: responseData['bairro'] ?? '',
              city: responseData['localidade'] ?? '',
              state: responseData['uf'] ?? '',
              zipCode: responseData['cep']?.replaceAll('-', '') ?? cleanedCep, // Usa o CEP limpo como fallback
            );
          } else {
            debugPrint("CepService: Erro na requisição - Status ${response.statusCode}: ${response.body}");
            return null;
          }
        } catch (e) {
          debugPrint("CepService: Exceção ao buscar CEP: $e");
          return null;
        }
      }
    }