package com.cashflip.service;

import com.cashflip.dto.CategoryDTO;
import com.cashflip.entity.Category;
import com.cashflip.entity.User;
import com.cashflip.repository.CategoryRepository;
import com.cashflip.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    @Autowired
    public CategoryService(CategoryRepository categoryRepository, UserRepository userRepository) {
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    public List<CategoryDTO> getUserCategories() {
        // TODO: Реализовать получение категорий пользователя
        return List.of();
    }

    @Transactional
    public CategoryDTO createCategory(CategoryDTO categoryDTO) {
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

        Category category = new Category();
        category.setName(categoryDTO.getName());
        category.setIsExpense(categoryDTO.isExpense());
        // Исправляем преобразование типов
        category.setColor(String.valueOf(categoryDTO.getColorValue()));
        category.setIcon(String.valueOf(categoryDTO.getIconCode()));
        category.setUser(user);

        // Сохраняем категорию и проверяем результат
        Category savedCategory = categoryRepository.save(category);
        if (savedCategory.getId() == null) {
            System.err.println("ОШИБКА: ID категории после сохранения равен null");
        } else {
            System.out.println("Категория успешно сохранена с ID: " + savedCategory.getId());
        }

        // Возвращаем DTO с правильным ID
        CategoryDTO result = new CategoryDTO();
        result.setId(savedCategory.getId());
        result.setName(savedCategory.getName());
        result.setExpense(savedCategory.getIsExpense());
        result.setIconCode(Integer.parseInt(savedCategory.getIcon()));
        result.setColorValue(Integer.parseInt(savedCategory.getColor()));

        return result;
    }

    public CategoryDTO updateCategory(Long id, CategoryDTO categoryDTO) {
        // TODO: Реализовать обновление категории
        return categoryDTO;
    }

    public void deleteCategory(Long id) {
        // TODO: Реализовать удаление категории
    }
}
