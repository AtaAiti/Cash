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
import java.util.stream.Collectors;

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
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

        // Получаем категории пользователя из репозитория
        List<Category> categories = categoryRepository.findByUser(user);

        // Конвертируем в DTO
        return categories.stream().map(category -> {
            CategoryDTO dto = new CategoryDTO();
            dto.setId(category.getId());
            dto.setName(category.getName());
            dto.setExpense(category.getIsExpense());

            // Преобразуем строковые значения в числовые
            try {
                dto.setIconCode(Integer.parseInt(category.getIcon()));
                dto.setColorValue(Integer.parseInt(category.getColor()));
            } catch (NumberFormatException e) {
                dto.setIconCode(58136); // Значение по умолчанию
                dto.setColorValue(2147483647); // Максимальное значение для Integer
            }

            return dto;
        }).collect(Collectors.toList());
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

    @Transactional
    public CategoryDTO updateCategory(Long id, CategoryDTO categoryDTO) {
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
        
        // Находим категорию по ID и проверяем, принадлежит ли она пользователю
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Категория не найдена"));
        
        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Нет прав на редактирование этой категории");
        }
        
        // Обновляем данные категории
        category.setName(categoryDTO.getName());
        category.setIsExpense(categoryDTO.isExpense());
        category.setColor(String.valueOf(categoryDTO.getColorValue()));
        category.setIcon(String.valueOf(categoryDTO.getIconCode()));
        
        // Сохраняем и возвращаем обновленную категорию
        Category updatedCategory = categoryRepository.save(category);
        
        CategoryDTO result = new CategoryDTO();
        result.setId(updatedCategory.getId());
        result.setName(updatedCategory.getName());
        result.setExpense(updatedCategory.getIsExpense());
        result.setIconCode(Integer.parseInt(updatedCategory.getIcon()));
        result.setColorValue(Integer.parseInt(updatedCategory.getColor()));
        
        return result;
    }

    @Transactional
    public void deleteCategory(Long id) {
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
        
        // Находим категорию по ID и проверяем, принадлежит ли она пользователю
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Категория не найдена"));
        
        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Нет прав на удаление этой категории");
        }
        
        // Опционально: проверить, есть ли транзакции с этой категорией
        // и принять решение об их обработке (например, установить категорию в null)
        
        // Удаляем категорию
        categoryRepository.delete(category);
        
        System.out.println("Категория #" + id + " (" + category.getName() + ") успешно удалена");
    }
}
