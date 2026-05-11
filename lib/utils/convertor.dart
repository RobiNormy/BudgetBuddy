import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'debouncer.dart';

import 'package:http/http.dart' as http;

const List<Map<String, String>> kCurrencies = [
  {'code': 'KES', 'label': 'KES — Kenyan Shilling'},
  {'code': 'USD', 'label': 'USD — US Dollar'},
  {'code': 'EUR', 'label': 'EUR — Euro'},
  {'code': 'GBP', 'label': 'GBP — British Pound'},
  {'code': 'UGX', 'label': 'UGX — Ugandan Shilling'},
  {'code': 'TZS', 'label': 'TZS — Tanzanian Shilling'},
  {'code': 'ZAR', 'label': 'ZAR — South African Rand'},
  {'code': 'NGN', 'label': 'NGN — Nigerian Naira'},
  {'code': 'CNY', 'label': 'CNY — Chinese Yuan'},
  {'code': 'JPY', 'label': 'JPY — Japanese Yen'},
  {'code': 'AED', 'label': 'AED — UAE Dirham'},
  {'code': 'INR', 'label': 'INR — Indian Rupee'},
];

class CurrencyConvertor extends StatefulWidget {
  const CurrencyConvertor({super.key});

  @override
  State<CurrencyConvertor> createState() => _CurrencyConvertorState();
}

class _CurrencyConvertorState extends State<CurrencyConvertor> {
  final TextEditingController _amountController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  String _fromCurrency = 'USD';
  String _toCurrency = 'KES';
  String? _result;
  bool _isLoading = false;
  String? _error;
  @override
  @override
  void dispose() {
    _amountController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final raw = _amountController.text.trim();
    final amount = double.tryParse(raw);
    if (amount == null || raw.isEmpty) {
      setState(() {
        _result = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiKey = dotenv.env['API_KEY'] ?? '';
      final apiBase = (dotenv.env['API_BASE'] ?? '').replaceFirst('API_KEY', apiKey);
      final url = '$apiBase$_fromCurrency';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'error') {
          setState(() {
            setState(() {
              _error = data['error-type'] ?? 'API error.';
            });
            return;
          });
        }
        final rates = data['conversion_rates'] as Map<String, dynamic>;
        final rate = (rates[_toCurrency] as num).toDouble();
        final converted = amount * rate;
        setState(() {
          _result = '${converted.toStringAsFixed(2)} $_toCurrency';
        });
      } else {
        setState(() {
          _error = 'Failed to fetch rate (${response.statusCode}).';
        });
      }
      //
      // final url = Uri.parse('https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$_fromCurrency.json'
      // );
    } catch (e) {
      setState(() {
        _error = "Network Error Please Try again.";
        _error = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _result = null;
    });
    if (_amountController.text.isNotEmpty) _convert();
  }

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    final colors = Theme.of(context).colorScheme;
    final selected = kCurrencies.firstWhere((c) => c['code'] == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.surfaceContainerHigh,
          style: TextStyle(color: colors.onSurface, fontSize: 14),
          selectedItemBuilder: (context) => kCurrencies.map((c) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    c['code']!.toUpperCase(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c['label']!.split('—').last.trim(),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          items: kCurrencies.map((c) {
            return DropdownMenuItem(value: c['code'], child: Text(c['label']!));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(Icons.currency_exchange_outlined),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Currency Convertor",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Live rates via ExchangeRate-API",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colors.onSurface),
            decoration: InputDecoration(
              labelText: "Amount",
              prefixIcon: Icon(Icons.attach_money_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colors.surfaceContainerHigh,
            ),
            onChanged: (_) => _debouncer.run(_convert),
          ),
          SizedBox(height: 16),
          _buildDropdown(_fromCurrency, (val) {
            if (val != null) {
              setState(() {
                _fromCurrency = val;
                _result = null;
                _debouncer.run(_convert);
              });
            }
          }),
          SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _swap,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_vert_circle_outlined,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(_toCurrency, (val) {
            if (val != null) {
              setState(() {
                _toCurrency = val;
                _result = null;
              });
              _debouncer.run(_convert);
            }
          }),
          SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Text(_error!, style: TextStyle(color: colors.error))
                : _result != null
                ? Container(
                    key: ValueKey(_result),
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Converted Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onPrimaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _result!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
