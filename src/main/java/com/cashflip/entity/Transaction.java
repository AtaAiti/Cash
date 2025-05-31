package com.cashflip.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Entity
@Table(name = "transactions")
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private BigDecimal amount;
    private String description;
    private LocalDateTime date;
    
    @ManyToOne
    @JoinColumn(name = "account_id")
    private Account account;
    
    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;
    
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    
    // Конструкторы
    public Transaction() {
    }
    
    public Transaction(Long id, BigDecimal amount, String description, LocalDateTime date, 
                     Account account, Category category, User user) {
        this.id = id;
        this.amount = amount;
        this.description = description;
        this.date = date;
        this.account = account;
        this.category = category;
        this.user = user;
    }
    
    // Геттеры и сеттеры
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public BigDecimal getAmount() {
        return amount;
    }
    
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public LocalDateTime getDate() {
        return date;
    }
    
    public void setDate(LocalDateTime date) {
        this.date = date;
    }
    
    public Account getAccount() {
        return account;
    }
    
    public void setAccount(Account account) {
        this.account = account;
    }
    
    public Category getCategory() {
        return category;
    }
    
    public void setCategory(Category category) {
        this.category = category;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    // Вспомогательные методы
    public Long getAccountId() {
        return account != null ? account.getId() : null;
    }
    
    public String getCurrency() {
        return account != null ? account.getCurrency() : null;
    }
    
    public BigDecimal getValue() {
        return amount;
    }
    
    // Паттерн Builder
    public static TransactionBuilder builder() {
        return new TransactionBuilder();
    }
    
    public static class TransactionBuilder {
        private Long id;
        private BigDecimal amount;
        private String description;
        private LocalDateTime date;
        private Account account;
        private Category category;
        private User user;
        
        public TransactionBuilder id(Long id) {
            this.id = id;
            return this;
        }
        
        public TransactionBuilder amount(BigDecimal amount) {
            this.amount = amount;
            return this;
        }
        
        public TransactionBuilder description(String description) {
            this.description = description;
            return this;
        }
        
        public TransactionBuilder date(LocalDateTime date) {
            this.date = date;
            return this;
        }
        
        public TransactionBuilder account(Account account) {
            this.account = account;
            return this;
        }
        
        public TransactionBuilder category(Category category) {
            this.category = category;
            return this;
        }
        
        public TransactionBuilder user(User user) {
            this.user = user;
            return this;
        }
        
        public Transaction build() {
            return new Transaction(id, amount, description, date, account, category, user);
        }
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Transaction that = (Transaction) o;
        return Objects.equals(id, that.id) &&
               Objects.equals(date, that.date) &&
               Objects.equals(amount, that.amount);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id, date, amount);
    }
    
    @Override
    public String toString() {
        return "Transaction{" +
               "id=" + id +
               ", amount=" + amount +
               ", date=" + date +
               ", account=" + (account != null ? account.getId() : null) +
               ", category=" + (category != null ? category.getId() : null) +
               ", user=" + (user != null ? user.getId() : null) +
               '}';
    }

}