package com.cashflip.service;

import com.cashflip.dto.TransactionDTO;
import com.cashflip.entity.Account;
import com.cashflip.entity.Category;
import com.cashflip.entity.Transaction;
import com.cashflip.entity.User;
import com.cashflip.repository.AccountRepository;
import com.cashflip.repository.CategoryRepository;
import com.cashflip.repository.TransactionRepository;
import com.cashflip.repository.UserRepository;

import jakarta.transaction.Transactional;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TransactionService {
    private final AccountRepository accountRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    
    // Добавить AccountService
    private final AccountService accountService;
    
    // Исправленный конструктор для внедрения всех зависимостей
    public TransactionService(
            TransactionRepository transactionRepository, 
            CategoryRepository categoryRepository,
            AccountRepository accountRepository, 
            UserRepository userRepository,
            AccountService accountService) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
        this.accountService = accountService;
    }

    @Transactional
    public TransactionDTO createTransaction(TransactionDTO transactionDTO) {
        try {
            String email = SecurityContextHolder.getContext().getAuthentication().getName();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
                    
            // Находим счет
            Account account = accountRepository.findById(transactionDTO.getAccountId())
                    .orElseThrow(() -> new RuntimeException("Счет не найден"));
            
            // Проверяем принадлежность счета пользователю
            if (!account.getUser().getId().equals(user.getId())) {
                throw new RuntimeException("Счет не принадлежит пользователю");
            }
            
            // Находим категорию по имени или идентификатору
            Category category = null;
            if (transactionDTO.getCategoryId() != null) {
                category = categoryRepository.findById(transactionDTO.getCategoryId())
                        .orElse(null);
            } else if (transactionDTO.getCategory() != null && !transactionDTO.getCategory().isEmpty()) {
                category = categoryRepository.findByNameAndUser(transactionDTO.getCategory(), user)
                        .orElse(null);
            }
            
            // Создаем транзакцию
            Transaction transaction = new Transaction();
            transaction.setAmount(transactionDTO.getAmount());
            transaction.setDescription(transactionDTO.getDescription() != null ? 
                                       transactionDTO.getDescription() : 
                                       transactionDTO.getNote());
            transaction.setDate(transactionDTO.getDate());
            transaction.setAccount(account);
            transaction.setCategory(category);
            transaction.setUser(user);
            
            // Обновляем баланс счета
            account.setBalance(account.getBalance().add(transactionDTO.getAmount()));
            accountRepository.save(account);
            
            // Сохраняем транзакцию
            Transaction savedTransaction = transactionRepository.save(transaction);
            
            // Пересчитываем баланс счетов
            accountService.recalculateBalances(user.getId());
            
            return mapToDTO(savedTransaction);
        } catch (Exception e) {
            // Логирование ошибки
            System.err.println("Error creating transaction: " + e.getMessage());
            throw new RuntimeException("Failed to create transaction", e);
        }
    }
    
    @Transactional
    public TransactionDTO updateTransaction(Long id, TransactionDTO transactionDTO) {
        // Получаем текущего пользователя
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
                
        Transaction existingTransaction = transactionRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Транзакция с ID " + id + " не найдена"));
        
        // Проверка принадлежности транзакции пользователю
        if (!existingTransaction.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Нет прав на редактирование этой транзакции");
        }
        
        // Если изменилась сумма или счет, обновляем балансы
        if (!existingTransaction.getAmount().equals(transactionDTO.getAmount()) ||
            !existingTransaction.getAccount().getId().equals(transactionDTO.getAccountId())) {
            
            // Отменяем старую транзакцию (вычитаем сумму из старого счета)
            Account oldAccount = existingTransaction.getAccount();
            oldAccount.setBalance(oldAccount.getBalance().subtract(existingTransaction.getAmount()));
            accountRepository.save(oldAccount);
            
            // Применяем новую транзакцию (добавляем сумму к новому счету)
            Account newAccount = accountRepository.findByIdAndUser(transactionDTO.getAccountId(), user)
                .orElseThrow(() -> new RuntimeException("Счет с ID " + transactionDTO.getAccountId() + " не найден или не принадлежит пользователю"));
            newAccount.setBalance(newAccount.getBalance().add(transactionDTO.getAmount()));
            accountRepository.save(newAccount);
        }
        
        // Обновляем данные транзакции
        updateTransactionFields(existingTransaction, transactionDTO, user);
        Transaction updatedTransaction = transactionRepository.save(existingTransaction);
        
        // Пересчитываем баланс счетов
        accountService.recalculateBalances(user.getId());
        
        return mapToDTO(updatedTransaction);
    }
    
    @Transactional
    public void deleteTransaction(Long id) {
        // Получаем текущего пользователя
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
                
        Transaction transaction = transactionRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Транзакция с ID " + id + " не найдена"));
            
        // Проверка принадлежности транзакции пользователю
        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Нет прав на удаление этой транзакции");
        }
        
        // Отменяем влияние транзакции на баланс счета
        Account account = transaction.getAccount();
        account.setBalance(account.getBalance().subtract(transaction.getAmount()));
        accountRepository.save(account);
        
        // Удаляем транзакцию
        transactionRepository.delete(transaction);
        
        // Пересчитываем баланс счетов
        accountService.recalculateBalances(user.getId());
    }
    
    public List<TransactionDTO> getUserTransactions() {
        // Получаем текущего пользователя
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
                
        return transactionRepository.findByUserIdOrderByDateDesc(user.getId()).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<TransactionDTO> getTransactionsByDateRange(LocalDateTime start, LocalDateTime end) {
        // Получаем текущего пользователя
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
                
        return transactionRepository.findByUserIdAndDateBetweenOrderByDateDesc(user.getId(), start, end).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }
    
    // Вспомогательные методы для преобразования Entity <-> DTO
    
    private Transaction mapToEntity(TransactionDTO dto, User user) {
        Account account = accountRepository.findById(dto.getAccountId())
                .orElseThrow(() -> new RuntimeException("Счет не найден"));
                
        Category category = null;
        if (dto.getCategoryId() != null) {
            category = categoryRepository.findById(dto.getCategoryId())
                    .orElse(null);
        }
        
        return Transaction.builder()
                .amount(dto.getAmount())
                .description(dto.getDescription())
                .date(dto.getDate())
                .account(account)
                .category(category)
                .user(user)
                .build();
    }
    
    private TransactionDTO mapToDTO(Transaction transaction) {
        TransactionDTO dto = new TransactionDTO();
        dto.setId(transaction.getId());
        dto.setAmount(transaction.getAmount());
        
        // Устанавливаем description и note с учетом совместимости
        String description = transaction.getDescription();
        dto.setDescription(description);
        dto.setNote(description); // Для совместимости устанавливаем то же значение в note
        
        dto.setDate(transaction.getDate());
        dto.setAccountId(transaction.getAccount().getId());
        
        // Имя счета для отображения
        dto.setAccount(transaction.getAccount().getName());
        
        // Валюта из счета
        dto.setCurrency(transaction.getAccount().getCurrency());
        
        // Категория, если есть
        if (transaction.getCategory() != null) {
            dto.setCategoryId(transaction.getCategory().getId());
            dto.setCategory(transaction.getCategory().getName());
            
            // Если нужна подкатегория, можно добавить логику здесь
        }
        
        return dto;
    }
    
    private void updateTransactionFields(Transaction transaction, TransactionDTO dto, User user) {
        transaction.setAmount(dto.getAmount());
        
        // Обновляем description из note или description
        if (dto.getDescription() != null) {
            transaction.setDescription(normalizeString(dto.getDescription()));
        } else if (dto.getNote() != null) {
            transaction.setDescription(normalizeString(dto.getNote()));
        }
        
        transaction.setDate(dto.getDate());
        
        // Обновляем счет с проверкой принадлежности пользователю
        Account account = accountRepository.findByIdAndUser(dto.getAccountId(), user)
                .orElseThrow(() -> new RuntimeException("Счет не найден или не принадлежит пользователю"));
        transaction.setAccount(account);
        
        // Обновляем категорию, если указана
        if (dto.getCategoryId() != null) {
            Category category = categoryRepository.findById(dto.getCategoryId())
                    .orElse(null);
            transaction.setCategory(category);
        } else if (dto.getCategory() != null && !dto.getCategory().isEmpty()) {
            Category category = categoryRepository.findByNameAndUser(dto.getCategory(), user)
                    .orElse(null);
            transaction.setCategory(category);
        } else {
            transaction.setCategory(null);
        }
        
        // Пользователь не меняется
    }
    
    private String normalizeString(String input) {
        if (input == null) {
            return null;
        }
        
        // Заменяем некорректно закодированные символы
        if (input.contains("Ð¾Ð±ÑÑÐ½ÑÐ¹")) {
            return input.replace("Ð¾Ð±ÑÑÐ½ÑÐ¹", "обычный");
        }
        
        return input;
    }
}
