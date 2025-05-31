package com.cashflip.controller;

import com.cashflip.dto.TransactionDTO;
import com.cashflip.service.TransactionService;
import com.cashflip.service.AccountService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {
    
    private final TransactionService transactionService;
    private final AccountService accountService;
    private static final Logger logger = LoggerFactory.getLogger(TransactionController.class);
    
    public TransactionController(TransactionService transactionService, AccountService accountService) {
        this.transactionService = transactionService;
        this.accountService = accountService;
    }
    
    @GetMapping
    public ResponseEntity<List<TransactionDTO>> getUserTransactions() {
        try {
            return ResponseEntity.ok(transactionService.getUserTransactions());
        } catch (Exception e) {
            // Добавить логирование
            logger.error("Error fetching transactions: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @PostMapping
    public ResponseEntity<?> createTransaction(@RequestBody TransactionDTO transactionDTO) {
        try {
            // Проверяем принадлежность счета пользователю
            if (!accountService.isAccountOwnedByCurrentUser(transactionDTO.getAccountId())) {
                logger.warn("Attempt to create transaction for account not owned by user: " + transactionDTO.getAccountId());
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Account does not belong to current user"));
            }
            
            TransactionDTO createdTransaction = transactionService.createTransaction(transactionDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdTransaction);
        } catch (Exception e) {
            logger.error("Error creating transaction: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<?> updateTransaction(@PathVariable Long id, @RequestBody TransactionDTO transactionDTO) {
        try {
            // Проверяем принадлежность счета пользователю
            if (!accountService.isAccountOwnedByCurrentUser(transactionDTO.getAccountId())) {
                logger.warn("Attempt to update transaction for account not owned by user: " + transactionDTO.getAccountId());
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Account does not belong to current user"));
            }
            
            TransactionDTO updatedTransaction = transactionService.updateTransaction(id, transactionDTO);
            return ResponseEntity.ok(updatedTransaction);
        } catch (Exception e) {
            logger.error("Error updating transaction: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteTransaction(@PathVariable Long id) {
        try {
            transactionService.deleteTransaction(id);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            logger.error("Error deleting transaction: " + e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}