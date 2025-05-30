package com.cashflip.service;

import com.cashflip.dto.AccountDTO;
import com.cashflip.entity.Account;
import com.cashflip.entity.User;
import com.cashflip.repository.AccountRepository;
import com.cashflip.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AccountService {
    
    private final AccountRepository accountRepository;
    private final UserRepository userRepository;
    
    // Конструктор вместо @RequiredArgsConstructor
    public AccountService(AccountRepository accountRepository, UserRepository userRepository) {
        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
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
                .currency(accountDTO.getCurrency())
                .isMain(accountDTO.getIsMain())
                .iconCode(accountDTO.getIconCode())  // Add this
                .colorValue(accountDTO.getColorValue()) // Add this
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
        account.setCurrency(accountDTO.getCurrency());
        account.setIsMain(accountDTO.getIsMain());
        account.setIconCode(accountDTO.getIconCode());
        account.setColorValue(accountDTO.getColorValue());
        
        return mapToDTO(accountRepository.save(account));
    }
    
    public void deleteAccount(Long id) {
        // Найти аккаунт и проверить, принадлежит ли он текущему пользователю
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Account account = accountRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Account not found"));
        
        // Проверяем, принадлежит ли счет пользователю
        if (!account.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Not authorized to delete this account");
        }
        
        accountRepository.delete(account);
    }
    
    private AccountDTO mapToDTO(Account account) {
        return AccountDTO.builder()
                .id(account.getId())
                .name(account.getName())
                .balance(account.getBalance())
                .accountType(account.getAccountType())
                .currency(account.getCurrency())
                .isMain(account.getIsMain())
                .iconCode(account.getIconCode())
                .colorValue(account.getColorValue())
                .build();
    }
}