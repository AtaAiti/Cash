package com.cashflip.repository;

import com.cashflip.entity.Category;
import com.cashflip.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByUserIdAndIsExpense(Long userId, Boolean isExpense);
    Optional<Category> findByNameAndUser(String name, User user);
}