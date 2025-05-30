import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/categories_provider.dart';

class CategoryFormModal extends StatefulWidget {
  final bool isExpenseCategory;
  final Function(Map<String, dynamic>)? onSave;

  // Добавляем параметры для редактирования существующей категории
  final String? categoryId;
  final String? initialName;
  final IconData? initialIcon;
  final Color? initialColor;
  final List<String>? initialSubcategories;

  const CategoryFormModal({
    Key? key,
    required this.isExpenseCategory,
    this.onSave,
    this.categoryId,
    this.initialName,
    this.initialIcon,
    this.initialColor,
    this.initialSubcategories,
  }) : super(key: key);

  @override
  _CategoryFormModalState createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends State<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late Color _categoryColor;
  late IconData _categoryIcon;

  // Список подкатегорий
  List<String> _subcategories = [];
  final _subcategoryController = TextEditingController();
  bool _isEditing = false;

  // Доступные иконки для категорий
  final List<IconData> _categoryIcons = [
    Icons.shopping_basket,
    Icons.restaurant,
    Icons.directions_bus,
    Icons.volunteer_activism,
    Icons.shopping_bag,
    Icons.laptop,
    Icons.sports_esports,
    Icons.handshake,
    Icons.local_bar,
    Icons.money,
    Icons.card_giftcard,
    Icons.attach_money,
    Icons.monetization_on,
    Icons.savings,
    Icons.account_balance_wallet,
    Icons.house,
    Icons.school,
    Icons.health_and_safety,
    Icons.sports_bar,
    Icons.brush,
    Icons.smartphone,
    Icons.pets,
    Icons.child_care,
    Icons.fitness_center,
  ];

  // Доступные цвета для категорий
  final List<Color> _categoryColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Color(0xFF4FC3F7),
    Color(0xFFB39DDB),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFBCAAA4),
    Color(0xFF8D6E63),
    Color(0xFF4DD0E1),
    Color(0xFFDCE775),
    Color(0xFFFFF176),
  ];

  @override
  void initState() {
    super.initState();

    // Если переданы данные для редактирования, используем их
    _isEditing = widget.categoryId != null;

    if (_isEditing) {
      _nameController.text = widget.initialName ?? '';
      _categoryIcon = widget.initialIcon ?? Icons.category;
      _categoryColor = widget.initialColor ?? Colors.blue;
      _subcategories = widget.initialSubcategories?.toList() ?? [];
    } else {
      _categoryIcon = Icons.category;
      _categoryColor = Colors.blue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  void _showIconColorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF23222A),
          title: Text(
            'Выберите цвет и иконку',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Цвет категории',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _categoryColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _categoryColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    _categoryColor == color
                                        ? Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        )
                                        : null,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Иконка категории',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _categoryIcons.map((icon) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _categoryIcon = icon;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    _categoryIcon == icon
                                        ? _categoryColor
                                        : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color:
                                    _categoryIcon == icon
                                        ? Colors.white
                                        : Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Готово', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Color(0xFF5B6CF6)),
            ),
          ],
        );
      },
    );
  }

  void _addSubcategory() {
    if (_subcategoryController.text.isNotEmpty) {
      setState(() {
        _subcategories.add(_subcategoryController.text);
        _subcategoryController.clear();
      });
    }
  }

  void _removeSubcategory(int index) {
    setState(() {
      _subcategories.removeAt(index);
    });
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      // Создаем данные категории
      final categoryData = {
        'id':
            widget.categoryId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'icon': _categoryIcon,
        'color': _categoryColor,
        'isExpense': widget.isExpenseCategory,
        'subcategories': _subcategories,
      };

      // Получаем провайдер категорий
      final categoriesProvider = Provider.of<CategoriesProvider>(
        context,
        listen: false,
      );

      // В зависимости от режима создаем новую или обновляем существующую категорию
      if (_isEditing) {
        categoriesProvider.updateCategory(
          Category(
            id: categoryData['id'] as String,
            name: categoryData['name'] as String,
            icon: categoryData['icon'] as IconData,
            color: categoryData['color'] as Color,
            isExpense: categoryData['isExpense'] as bool,
            subcategories: categoryData['subcategories'] as List<String>,
          ),
        );
      } else {
        categoriesProvider.addCategory(
          Category(
            id: categoryData['id'] as String,
            name: categoryData['name'] as String,
            icon: categoryData['icon'] as IconData,
            color: categoryData['color'] as Color,
            isExpense: categoryData['isExpense'] as bool,
            subcategories: categoryData['subcategories'] as List<String>,
          ),
        );
      }

      // Вызываем колбэк onSave, если он предоставлен
      if (widget.onSave != null) {
        widget.onSave!(categoryData);
      }

      // Показываем уведомление об успешном добавлении/изменении
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Категория успешно изменена!'
                : 'Категория успешно добавлена!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  void _deleteCategory() {
    if (!_isEditing) return; // Нельзя удалить несуществующую категорию

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF23222A),
          title: Text(
            'Удалить категорию?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Вы уверены, что хотите удалить категорию "${_nameController.text}"? Это действие нельзя отменить.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                // Удаляем категорию
                Provider.of<CategoriesProvider>(
                  context,
                  listen: false,
                ).deleteCategory(widget.categoryId!, context);

                Navigator.pop(context); // Закрываем диалог
                Navigator.pop(context); // Закрываем модальное окно категории

                // Показываем уведомление
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Категория успешно удалена!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFF23222A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing
                ? 'Редактирование категории'
                : (widget.isExpenseCategory
                    ? 'Новая категория расхода'
                    : 'Новая категория дохода'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: false,
          actions: [
            if (_isEditing)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteCategory,
              ),
            TextButton(
              onPressed: _saveCategory,
              child: Text(
                'Готово',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF5B6CF6),
                padding: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Category Preview
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _categoryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _categoryIcon,
                        color: _categoryColor,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Название категории'
                          : _nameController.text,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      widget.isExpenseCategory
                          ? 'Категория расхода'
                          : 'Категория дохода',
                      style: TextStyle(
                        color:
                            widget.isExpenseCategory
                                ? Colors.pinkAccent
                                : Colors.tealAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Category Name
              Text(
                'Название',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Введите название',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5B6CF6)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // Обновляем UI при изменении имени
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название категории';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Icon and Color
              InkWell(
                onTap: _showIconColorDialog,
                child: Row(
                  children: [
                    Text(
                      'Внешний вид',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _categoryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _categoryIcon,
                        color: _categoryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white24, height: 48),

              // Тип категории (информационный)
              Row(
                children: [
                  Icon(
                    widget.isExpenseCategory
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color:
                        widget.isExpenseCategory
                            ? Colors.pinkAccent
                            : Colors.tealAccent,
                  ),
                  SizedBox(width: 16),
                  Text(
                    widget.isExpenseCategory
                        ? 'Категория расхода'
                        : 'Категория дохода',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Подкатегории
              Row(
                children: [
                  Text(
                    'Подкатегории',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${_subcategories.length} шт.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Поле ввода для подкатегории
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subcategoryController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Добавить подкатегорию',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSubcategory,
                    child: Icon(Icons.add, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _categoryColor,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Список подкатегорий
              if (_subcategories.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _subcategories.length,
                    separatorBuilder:
                        (context, index) =>
                            Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _subcategories[index],
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.white54),
                          onPressed: () => _removeSubcategory(index),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Нет подкатегорий',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
