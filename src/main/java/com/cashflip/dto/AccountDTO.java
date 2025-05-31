package com.cashflip.dto;

import java.math.BigDecimal;
import java.util.Objects;

import com.cashflip.entity.Account;

public class AccountDTO {
    private Long id;
    private String name;
    private BigDecimal balance;
    private String accountType;
    private String currency;
    private Boolean isMain;
    // Добавить поля:
    private Integer iconCode;
    private Integer colorValue;

    // Конструкторы
    public AccountDTO() {
    }

    public AccountDTO(Long id, String name, BigDecimal balance, String accountType, String currency, Boolean isMain, Integer iconCode, Integer colorValue) {
        this.id = id;
        this.name = name;
        this.balance = balance;
        this.accountType = accountType;
        this.currency = currency;
        this.isMain = isMain;
        this.iconCode = iconCode;
        this.colorValue = colorValue;
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

    // Паттерн Builder для AccountDTO
    public static AccountDTOBuilder builder() {
        return new AccountDTOBuilder();
    }

    public static class AccountDTOBuilder {
        private Long id;
        private String name;
        private BigDecimal balance;
        private String accountType;
        private String currency;
        private Boolean isMain;
        // Добавить поля:
        private Integer iconCode;
        private Integer colorValue;

        public AccountDTOBuilder id(Long id) {
            this.id = id;
            return this;
        }

        public AccountDTOBuilder name(String name) {
            this.name = name;
            return this;
        }

        public AccountDTOBuilder balance(BigDecimal balance) {
            this.balance = balance;
            return this;
        }

        public AccountDTOBuilder accountType(String accountType) {
            this.accountType = accountType;
            return this;
        }

        public AccountDTOBuilder currency(String currency) {
            this.currency = currency;
            return this;
        }

        public AccountDTOBuilder isMain(Boolean isMain) {
            this.isMain = isMain;
            return this;
        }

        public AccountDTOBuilder iconCode(Integer iconCode) {
            this.iconCode = iconCode;
            return this;
        }

        public AccountDTOBuilder colorValue(Integer colorValue) {
            this.colorValue = colorValue;
            return this;
        }

        public AccountDTO build() {
            return new AccountDTO(id, name, balance, accountType, currency, isMain, iconCode, colorValue);
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AccountDTO that = (AccountDTO) o;
        return Objects.equals(id, that.id) &&
                Objects.equals(name, that.name) &&
                Objects.equals(balance, that.balance) &&
                Objects.equals(accountType, that.accountType) &&
                Objects.equals(currency, that.currency) &&
                Objects.equals(isMain, that.isMain);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, balance, accountType, currency, isMain);
    }

    @Override
    public String toString() {
        return "AccountDTO{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", balance=" + balance +
                ", accountType='" + accountType + '\'' +
                ", currency='" + currency + '\'' +
                ", isMain=" + isMain +
                '}';
    }

    // В метод mapToDTO в AccountService добавить:
    public AccountDTO mapToDTO(Account account) {
        // Существующий код...

        // Убедимся, что валюта и тип счета корректно закодированы
        String currency = account.getCurrency();
        if ("₽".equals(currency) && !currency.equals("₽")) {
            currency = "₽";
        }

        String accountType = account.getAccountType();
        if (accountType != null && accountType.contains("Ð¾Ð±ÑÑÐ½ÑÐ¹")) {
            accountType = "обычный";
        }

        return new AccountDTO.AccountDTOBuilder()
                .id(account.getId())
                .name(account.getName())
                .balance(account.getBalance())
                .accountType(accountType)
                .currency(currency)
                // остальные поля...
                .build();
    }
}