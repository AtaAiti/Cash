package com.cashflip.repository;

import com.cashflip.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByUserIdOrderByDateDesc(Long userId);
    List<Transaction> findByUserIdAndDateBetweenOrderByDateDesc(Long userId, LocalDateTime start, LocalDateTime end);
    
    @Query("SELECT t FROM Transaction t WHERE t.user.id = :userId AND t.category.id = :categoryId")
    List<Transaction> findByUserIdAndCategoryId(Long userId, Long categoryId);

    List<Transaction> findByAccount_Id(Long accountId);
}