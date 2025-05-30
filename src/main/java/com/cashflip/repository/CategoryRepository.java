package com.cashflip.repository;

import com.cashflip.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByUserIdAndIsExpense(Long userId, Boolean isExpense);
}