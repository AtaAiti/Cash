package com.cashflip.service;

import com.cashflip.dto.AccountDTO;
import com.cashflip.entity.Account;
import com.cashflip.entity.Transaction;
import com.cashflip.entity.User;
import com.cashflip.repository.AccountRepository;
import com.cashflip.repository.TransactionRepository;
import com.cashflip.repository.UserRepository;

import jakarta.transaction.Transactional;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AccountService {
    
    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    
    // Добавляем TransactionRepository в конструктор
    public AccountService(
            AccountRepository accountRepository, 
            UserRepository userRepository,
            TransactionRepository transactionRepository) {
        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
    }
    
    public List<AccountDTO> getUserAccounts() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return accountRepository.findByUserId(user.getId()).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }
    
    public AccountDTO createAccount(AccountDTO accountDTO) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Account account = Account.builder()
                .name(accountDTO.getName())
                .balance(accountDTO.getBalance())
                .accountType(accountDTO.getAccountType())
                .currency(normalizeCurrency(accountDTO.getCurrency()))
                .isMain(accountDTO.getIsMain())
                .iconCode(accountDTO.getIconCode())
                .colorValue(accountDTO.getColorValue())
                .user(user)
                .build();
        
        return mapToDTO(accountRepository.save(account));
    }
    
    public AccountDTO updateAccount(Long id, AccountDTO accountDTO) {
        // Найти аккаунт и проверить, принадлежит ли он текущему пользователю
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Account account = accountRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Account not found"));
        
        // Проверяем, принадлежит ли счет пользователю
        if (!account.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Not authorized to update this account");
        }
        
        // Обновляем данные
        account.setName(accountDTO.getName());
        account.setBalance(accountDTO.getBalance());
        account.setAccountType(accountDTO.getAccountType());
        account.setCurrency(normalizeCurrency(accountDTO.getCurrency()));
        account.setIsMain(accountDTO.getIsMain());
        account.setIconCode(accountDTO.getIconCode());
        account.setColorValue(accountDTO.getColorValue());
        
        return mapToDTO(accountRepository.save(account));
    }
    
    @Transactional
    public void deleteAccount(Long id) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Account account = accountRepository.findByIdAndUser(id, user)
                .orElseThrow(() -> new RuntimeException("Счет не найден или не принадлежит пользователю"));
        
        // Подсчитываем количество транзакций для логирования
        int transactionsCount = 0;
        if (account.getTransactions() != null) {
            transactionsCount = account.getTransactions().size();
        }
        
        System.out.println("Удаление счета #" + id + " (" + account.getName() + 
                          ") с " + transactionsCount + " транзакциями");
        
        // Удаляем счет (транзакции удалятся автоматически благодаря каскадному удалению)
        accountRepository.delete(account);
        
        System.out.println("Счет #" + id + " успешно удален");
    }
    
    private AccountDTO mapToDTO(Account account) {
        // Убедимся, что валюта и тип счета корректно закодированы
        String currency = account.getCurrency();
        currency = normalizeCurrency(currency);
        
        String accountType = account.getAccountType();
        if (accountType != null && accountType.contains("Ð¾Ð±ÑÑÐ½ÑÐ¹")) {
            accountType = "обычный";
        }
        
        return AccountDTO.builder()
                .id(account.getId())
                .name(account.getName())
                .balance(account.getBalance())
                .accountType(accountType)
                .currency(currency)
                .isMain(account.getIsMain())
                .iconCode(account.getIconCode())
                .colorValue(account.getColorValue())
                .build();
    }

    public boolean isAccountOwnedByCurrentUser(Long accountId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
                
        return accountRepository.findByIdAndUser(accountId, user).isPresent();
    }
    
    @Transactional
    public List<AccountDTO> recoverAccountsFromTransactions() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Получаем все транзакции пользователя
        List<Transaction> transactions = transactionRepository.findByUserIdOrderByDateDesc(user.getId());
        
        // Собираем уникальные ID счетов из транзакций
        Set<Long> accountIds = new HashSet<>();
        for (Transaction transaction : transactions) {
            // Исправлено: проверяем, что поле account не null
            if (transaction.getAccountId() != null) {
                accountIds.add(transaction.getAccountId());
            }
        }
        
        // Находим счета, которых нет в базе
        List<Account> existingAccounts = accountRepository.findByUserId(user.getId());
        Set<Long> existingAccountIds = new HashSet<>();
        for (Account account : existingAccounts) {
            existingAccountIds.add(account.getId());
        }
        
        // Счета для восстановления
        List<Account> recoveredAccounts = new ArrayList<>();
        
        // Создаем недостающие счета
        for (Long accountId : accountIds) {
            if (!existingAccountIds.contains(accountId)) {
                // Находим первую транзакцию с этим счетом для получения информации
                Transaction sampleTransaction = null;
                for (Transaction transaction : transactions) {
                    // Исправлено: сравниваем accountId напрямую
                    if (transaction.getAccountId() != null && 
                        transaction.getAccountId().equals(accountId)) {
                        sampleTransaction = transaction;
                        break;
                    }
                }
                
                if (sampleTransaction != null) {
                    // Создаем новый счет
                    Account newAccount = new Account();
                    newAccount.setId(accountId);
                    
                    String accountName = "Восстановленный счет";
                    // Получаем название счета из другого источника или используем стандартное
                    newAccount.setName(accountName);
                    
                    newAccount.setAccountType("обычный"); // Тип по умолчанию
                    newAccount.setBalance(BigDecimal.ZERO); // Баланс будет пересчитан
                    
                    String currency = "₽"; // Валюта по умолчанию
                    // Получаем валюту из транзакции напрямую
                    if (sampleTransaction.getCurrency() != null) {
                        currency = sampleTransaction.getCurrency();
                    }
                    newAccount.setCurrency(currency);
                    
                    newAccount.setIconCode(0); // Значения по умолчанию
                    newAccount.setColorValue(0xFF2196F3);
                    newAccount.setIsMain(false);
                    newAccount.setUser(user);
                    
                    accountRepository.save(newAccount);
                    recoveredAccounts.add(newAccount);
                }
            }
        }
        
        // Пересчитываем балансы всех счетов
        recalculateBalances(user.getId());
        
        // Возвращаем все счета, включая восстановленные
        return accountRepository.findByUserId(user.getId()).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }
    
    // Метод для пересчета балансов счетов
    @Transactional
    public void recalculateBalances(Long userId) {
        // Получаем все счета пользователя и обнуляем балансы
        List<Account> accounts = accountRepository.findByUserId(userId);
        System.out.println("Пересчет балансов для " + accounts.size() + " счетов");
        
        for (Account account : accounts) {
            System.out.println("Счет #" + account.getId() + " (" + account.getName() + 
                              "): исходный баланс = " + account.getBalance());
            account.setBalance(BigDecimal.ZERO);
        }
        accountRepository.saveAll(accounts);
        
        // Получаем все транзакции и применяем их к счетам
        List<Transaction> transactions = transactionRepository.findByUserIdOrderByDateDesc(userId);
        System.out.println("Найдено " + transactions.size() + " транзакций для пересчета");
        
        // Создаем карту счетов для быстрого доступа
        java.util.Map<Long, Account> accountMap = new java.util.HashMap<>();
        for (Account account : accounts) {
            accountMap.put(account.getId(), account);
        }
        
        // Применяем транзакции
        for (Transaction transaction : transactions) {
            if (transaction.getAccountId() != null) {
                Long accountId = transaction.getAccountId();
                Account account = accountMap.get(accountId);
                
                if (account != null && transaction.getAmount() != null) {
                    account.setBalance(account.getBalance().add(transaction.getAmount()));
                    System.out.println("Транзакция #" + transaction.getId() + 
                                      " применена к счету #" + accountId + 
                                      ": новый баланс = " + account.getBalance());
                } else {
                    System.out.println("ОШИБКА: Не удалось применить транзакцию #" + 
                                      transaction.getId() + " к счету #" + accountId);
                }
            }
        }
        
        // Сохраняем обновленные счета
        accountRepository.saveAll(accounts);
        
        // Выводим итоговые балансы
        for (Account account : accounts) {
            System.out.println("Счет #" + account.getId() + " (" + account.getName() + 
                              "): итоговый баланс = " + account.getBalance());
        }
    }
    
    private String normalizeCurrency(String currency) {
        if (currency == null) {
            return "₽"; // Значение по умолчанию
        }
        
        // Исправление неправильно закодированных символов
        if (currency.contains("â½") || currency.equals("â½")) {
            return "₽";
        }
        if (currency.contains("Ñ$") || currency.equals("Ñ$")) {
            return "₽";
        }
        
        return currency;
    }

    @Transactional
    public List<AccountDTO> recalculateAndGetAccounts() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
        
        // Расширенная версия метода с логированием
        System.out.println("Начинаем пересчет балансов счетов для пользователя: " + email);
        
        recalculateBalances(user.getId());
        
        List<AccountDTO> accounts = getUserAccounts();
        System.out.println("Пересчет завершен. Обновлено счетов: " + accounts.size());
        
        return accounts;
    }
}