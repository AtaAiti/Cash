import 'package:cash_flip_app/providers/accounts_provider.dart';
import 'package:cash_flip_app/providers/transactions_provider.dart';
import 'package:cash_flip_app/screens/AccountsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/auth_provider.dart';
import 'package:cash_flip_app/services/api_service.dart';
import 'package:cash_flip_app/screens/RegisterScreen.dart';
import 'package:cash_flip_app/main.dart'; // Добавлено
import 'package:cash_flip_app/providers/categories_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF23222A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CashFlip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Электронная почта',
                    filled: true,
                    fillColor: Color(0xFF393848),
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    filled: true,
                    fillColor: Color(0xFF393848),
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5B6CF6),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Войти', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Нет аккаунта?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          ),
                      child: Text(
                        'Зарегистрироваться',
                        style: TextStyle(color: Color(0xFF5B6CF6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.login(
          _emailController.text,
          _passwordController.text,
        );

        if (success) {
          // Принудительно устанавливаем данные сразу после успешного входа
          // Это гарантирует, что данные будут доступны при первом отображении MainScreen
          if (authProvider.userName == null || authProvider.userName!.isEmpty) {
            // Используем часть email как запасной вариант
            final defaultName = _emailController.text.split('@')[0];
            // Используем отражение для прямого доступа к приватному полю (крайняя мера)
            // ignore: invalid_use_of_protected_member
            (authProvider as dynamic)._userName = defaultName;
            // ignore: invalid_use_of_protected_member
            (authProvider as dynamic)._userEmail = _emailController.text;
            authProvider.notifyListeners();
          }

          // После успешного входа и очистки кэша в AuthProvider,
          // ЗАСТАВЛЯЕМ ДРУГИЕ ПРОВАЙДЕРЫ ЗАГРУЗИТЬ ДАННЫЕ С СЕРВЕРА
          // ignore: use_build_context_synchronously
          await Provider.of<AccountsProvider>(
            context,
            listen: false,
          ).loadData();
          // ignore: use_build_context_synchronously
          await Provider.of<TransactionsProvider>(
            context,
            listen: false,
          ).loadData();
          // ignore: use_build_context_synchronously
          await Provider.of<CategoriesProvider>(
            context,
            listen: false,
          ).loadData();
          // Добавьте вызовы для других провайдеров данных, если они есть

          // ИЗМЕНЕННАЯ НАВИГАЦИЯ:
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ), // <-- Укажите ваш главный экран здесь
            (Route<dynamic> route) => false,
          );
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось войти. Проверьте email и пароль.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Добавьте более детальный вывод ошибки
        print('Detailed login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
