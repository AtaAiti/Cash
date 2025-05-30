package com.cashflip.service;

import com.cashflip.dto.CategoryDTO;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CategoryService {
    public List<CategoryDTO> getUserCategories() {
        // TODO: Реализовать получение категорий пользователя
        return List.of();
    }

    public CategoryDTO createCategory(CategoryDTO categoryDTO) {
        // TODO: Реализовать создание категории
        return categoryDTO;
    }

    public CategoryDTO updateCategory(Long id, CategoryDTO categoryDTO) {
        // TODO: Реализовать обновление категории
        return categoryDTO;
    }

    public void deleteCategory(Long id) {
        // TODO: Реализовать удаление категории
    }
}
