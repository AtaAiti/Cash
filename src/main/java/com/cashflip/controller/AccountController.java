package com.cashflip.controller;

import com.cashflip.dto.AccountDTO;
import com.cashflip.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping
    public ResponseEntity<List<AccountDTO>> getUserAccounts() {
        return ResponseEntity.ok(accountService.getUserAccounts());
    }

    @PostMapping
    public ResponseEntity<AccountDTO> createAccount(@RequestBody AccountDTO accountDTO) {
        return new ResponseEntity<>(accountService.createAccount(accountDTO), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<AccountDTO> updateAccount(@PathVariable Long id, @RequestBody AccountDTO accountDTO) {
        return ResponseEntity.ok(accountService.updateAccount(id, accountDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAccount(@PathVariable Long id) {
        accountService.deleteAccount(id);
        return ResponseEntity.noContent().build(); // Добавить возврат ResponseEntity
    }

    @PostMapping("/recover-from-transactions")
    public ResponseEntity<List<AccountDTO>> recoverAccountsFromTransactions() {
        return ResponseEntity.ok(accountService.recoverAccountsFromTransactions());
    }

    @PostMapping("/sync-balances")
    public ResponseEntity<List<AccountDTO>> syncBalances() {
        System.out.println("Запрос на синхронизацию балансов от клиента");
        try {
            List<AccountDTO> accounts = accountService.recalculateAndGetAccounts();
            return ResponseEntity.ok(accounts);
        } catch (Exception e) {
            System.err.println("Ошибка при синхронизации балансов: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(List.of());
        }
    }
}