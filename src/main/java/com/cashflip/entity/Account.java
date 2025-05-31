package com.cashflip.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;

@Entity
@Table(name = "accounts")
public class Account {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private BigDecimal balance;
    private String accountType; // CASH, CARD, SAVINGS
    private String currency;
    private Boolean isMain;
    private Integer iconCode;
    private Integer colorValue;
    
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @OneToMany(mappedBy = "account", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Transaction> transactions;

    // Конструкторы
    public Account() {
    }

    public Account(Long id, String name, BigDecimal balance, String accountType, 
                  String currency, Boolean isMain, Integer iconCode, Integer colorValue, User user) {
        this.id = id;
        this.name = name;
        this.balance = balance;
        this.accountType = accountType;
        this.currency = currency;
        this.isMain = isMain;
        this.iconCode = iconCode;
        this.colorValue = colorValue;
        this.user = user;
    }

    // Геттеры и сеттеры
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public String getAccountType() {
        return accountType;
    }

    public void setAccountType(String accountType) {
        this.accountType = accountType;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public Boolean getIsMain() {
        return isMain;
    }

    public void setIsMain(Boolean isMain) {
        this.isMain = isMain;
    }

    public Integer getIconCode() {
        return iconCode;
    }

    public void setIconCode(Integer iconCode) {
        this.iconCode = iconCode;
    }

    public Integer getColorValue() {
        return colorValue;
    }

    public void setColorValue(Integer colorValue) {
        this.colorValue = colorValue;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public List<Transaction> getTransactions() {
        return transactions;
    }

    public void setTransactions(List<Transaction> transactions) {
        this.transactions = transactions;
    }

    // Паттерн Builder
    public static AccountBuilder builder() {
        return new AccountBuilder();
    }

    public static class AccountBuilder {
        private Long id;
        private String name;
        private BigDecimal balance;
        private String accountType;
        private String currency;
        private Boolean isMain;
        private Integer iconCode;
        private Integer colorValue;
        private User user;

        public AccountBuilder id(Long id) {
            this.id = id;
            return this;
        }

        public AccountBuilder name(String name) {
            this.name = name;
            return this;
        }

        public AccountBuilder balance(BigDecimal balance) {
            this.balance = balance;
            return this;
        }

        public AccountBuilder accountType(String accountType) {
            this.accountType = accountType;
            return this;
        }

        public AccountBuilder currency(String currency) {
            this.currency = currency;
            return this;
        }

        public AccountBuilder isMain(Boolean isMain) {
            this.isMain = isMain;
            return this;
        }

        public AccountBuilder iconCode(Integer iconCode) {
            this.iconCode = iconCode;
            return this;
        }

        public AccountBuilder colorValue(Integer colorValue) {
            this.colorValue = colorValue;
            return this;
        }

        public AccountBuilder user(User user) {
            this.user = user;
            return this;
        }

        public Account build() {
            return new Account(id, name, balance, accountType, currency, isMain, iconCode, colorValue, user);
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Account account = (Account) o;
        return Objects.equals(id, account.id) &&
                Objects.equals(name, account.name) &&
                Objects.equals(balance, account.balance) &&
                Objects.equals(accountType, account.accountType) &&
                Objects.equals(currency, account.currency) &&
                Objects.equals(isMain, account.isMain);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, balance, accountType, currency, isMain);
    }

    @Override
    public String toString() {
        return "Account{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", balance=" + balance +
                ", accountType='" + accountType + '\'' +
                ", currency='" + currency + '\'' +
                ", isMain=" + isMain +
                ", user=" + (user != null ? user.getId() : null) +
                '}';
    }
}