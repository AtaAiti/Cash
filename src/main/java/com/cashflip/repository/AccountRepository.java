package com.cashflip.repository;

import com.cashflip.entity.Account;
import com.cashflip.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AccountRepository extends JpaRepository<Account, Long> {
    List<Account> findByUserId(Long userId);
    
    // Добавляем новый метод для проверки принадлежности счета пользователю
    Optional<Account> findByIdAndUser(Long id, User user);
}