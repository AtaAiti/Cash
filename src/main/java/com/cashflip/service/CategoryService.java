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
import java.util.Random;
import java.util.stream.Collectors;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final Random random = new Random();

    @Autowired
    public CategoryService(CategoryRepository categoryRepository, UserRepository userRepository) {
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    // Вспомогательный метод для генерации случайного цвета (не слишком темного и не слишком светлого)
    private int generateRandomColor() {
        int r = random.nextInt(156) + 100; // 100-255
        int g = random.nextInt(156) + 100; // 100-255
        int b = random.nextInt(156) + 100; // 100-255
        // Alpha будет 255 (непрозрачный)
        return (255 << 24) | (r << 16) | (g << 8) | b;
    }

    public List<CategoryDTO> getUserCategories() {
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

        // Получаем категории пользователя из репозитория
        List<Category> categories = categoryRepository.findByUser(user);

        // Конвертируем в DTO
        return categories.stream().map(categoryEntity -> {
            CategoryDTO dto = new CategoryDTO();
            dto.setId(categoryEntity.getId());
            dto.setName(categoryEntity.getName());
            dto.setExpense(categoryEntity.getIsExpense());

            int iconCodeToSet = 58136; // По умолчанию (help_outline)
            try {
                if (categoryEntity.getIcon() != null && !categoryEntity.getIcon().isEmpty()) {
                    iconCodeToSet = Integer.parseInt(categoryEntity.getIcon());
                }
            } catch (NumberFormatException e) {
                System.err.println("Error parsing iconCode for category " + categoryEntity.getName() + ", value: " + categoryEntity.getIcon());
            }
            dto.setIconCode(iconCodeToSet);

            int colorValueToSet = 0;
            boolean updateCategoryInDb = false;
            try {
                if (categoryEntity.getColor() != null && !categoryEntity.getColor().isEmpty()) {
                    long colorVal = Long.parseLong(categoryEntity.getColor());
                    if (colorVal == 0) { // Если в БД хранится "0"
                        colorValueToSet = generateRandomColor();
                        categoryEntity.setColor(String.valueOf(colorValueToSet));
                        updateCategoryInDb = true;
                         System.out.println("Category " + categoryEntity.getName() + " had color 0, new random color generated: " + colorValueToSet);
                    } else if (colorVal > Integer.MAX_VALUE || colorVal < Integer.MIN_VALUE) {
                        System.err.println("Warning: colorValue " + colorVal + " for category " + categoryEntity.getName() + " is out of int range. Generating random color.");
                        colorValueToSet = generateRandomColor();
                        categoryEntity.setColor(String.valueOf(colorValueToSet));
                        updateCategoryInDb = true;
                    } else {
                        colorValueToSet = (int) colorVal;
                    }
                } else { // Если цвет null или пустой в БД
                    colorValueToSet = generateRandomColor();
                    categoryEntity.setColor(String.valueOf(colorValueToSet));
                    updateCategoryInDb = true;
                     System.out.println("Category " + categoryEntity.getName() + " had no color, new random color generated: " + colorValueToSet);
                }
            } catch (NumberFormatException e) {
                System.err.println("Error parsing colorValue for category " + categoryEntity.getName() + ", value: " + categoryEntity.getColor() + ". Generating random color.");
                colorValueToSet = generateRandomColor();
                categoryEntity.setColor(String.valueOf(colorValueToSet));
                updateCategoryInDb = true;
            }
            dto.setColorValue(colorValueToSet);

            if (updateCategoryInDb) {
                categoryRepository.save(categoryEntity); // Сохраняем изменения в БД
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
        
        int colorToSave = categoryDTO.getColorValue();
        if (colorToSave == 0) { // Если фронт прислал 0, генерируем случайный цвет
            colorToSave = generateRandomColor();
            System.out.println("CreateCategory: Frontend sent color 0 for " + categoryDTO.getName() + ". Generated random color: " + colorToSave);
        }
        category.setColor(String.valueOf(colorToSave));
        category.setIcon(String.valueOf(categoryDTO.getIconCode()));
        category.setUser(user);

        Category savedCategory = categoryRepository.save(category);
        
        CategoryDTO resultDTO = new CategoryDTO();
        resultDTO.setId(savedCategory.getId()); 
        resultDTO.setName(savedCategory.getName()); 
        resultDTO.setExpense(savedCategory.getIsExpense());
        resultDTO.setIconCode(Integer.parseInt(savedCategory.getIcon())); // Берем из сохраненной сущности, т.к. icon не менялся
        resultDTO.setColorValue(Integer.parseInt(savedCategory.getColor())); // Берем из сохраненной сущности, т.к. цвет мог быть сгенерирован
        
        return resultDTO;
    }

    @Transactional
    public CategoryDTO updateCategory(Long id, CategoryDTO categoryDTO) {
        // Получаем текущего пользователя из контекста безопасности
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
        
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Категория не найдена"));
        
        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Нет прав на редактирование этой категории");
        }
        
        category.setName(categoryDTO.getName());
        category.setIsExpense(categoryDTO.isExpense());

        int colorToUpdate = categoryDTO.getColorValue();
        if (colorToUpdate == 0) { // Если фронт прислал 0 при обновлении, можно оставить старый или сгенерировать новый
                                  // Пока оставим как есть - если 0, то сохранится "0"
                                  // Либо можно: colorToUpdate = generateRandomColor(); 
                                  // Или: if (categoryDTO.getColorValue() == 0 && (category.getColor() == null || category.getColor().equals("0"))) {
                                  //          colorToUpdate = generateRandomColor();
                                  //      } else if (categoryDTO.getColorValue() != 0) {
                                  //          colorToUpdate = categoryDTO.getColorValue();
                                  //      } else {
                                  //          colorToUpdate = Integer.parseInt(category.getColor()); // оставить старый
                                  //      }
        }

        category.setColor(String.valueOf(colorToUpdate)); 
        category.setIcon(String.valueOf(categoryDTO.getIconCode()));
        
        Category updatedCategory = categoryRepository.save(category);
        
        CategoryDTO resultDTO = new CategoryDTO();
        resultDTO.setId(updatedCategory.getId());
        resultDTO.setName(updatedCategory.getName());
        resultDTO.setExpense(updatedCategory.getIsExpense());
        resultDTO.setIconCode(Integer.parseInt(updatedCategory.getIcon()));
        resultDTO.setColorValue(Integer.parseInt(updatedCategory.getColor()));
        
        return resultDTO;
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
