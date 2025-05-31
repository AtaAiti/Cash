package com.cashflip.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TransactionDTO {
    private Long id;
    private String category;
    private String subcategory;
    private BigDecimal amount;
    private String account;
    private Long accountId;
    private Long categoryId;
    private String currency;
    private LocalDateTime date;
    private String note;
    private String description; // Добавляем поле description

    // Конструктор без параметров
    public TransactionDTO() {
    }

    // Полный конструктор
    public TransactionDTO(Long id, String category, String subcategory, BigDecimal amount,
                        String account, Long accountId, Long categoryId, String currency,
                        LocalDateTime date, String note, String description) {
        this.id = id;
        this.category = category;
        this.subcategory = subcategory;
        this.amount = amount;
        this.account = account;
        this.accountId = accountId;
        this.categoryId = categoryId;
        this.currency = currency;
        this.date = date;
        this.note = note;
        this.description = description;
    }

    // Геттеры и сеттеры
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getSubcategory() {
        return subcategory;
    }

    public void setSubcategory(String subcategory) {
        this.subcategory = subcategory;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getAccount() {
        return account;
    }

    public void setAccount(String account) {
        this.account = account;
    }

    public Long getAccountId() {
        return accountId;
    }

    public void setAccountId(Long accountId) {
        this.accountId = accountId;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public LocalDateTime getDate() {
        return date;
    }

    public void setDate(LocalDateTime date) {
        this.date = date;
    }

    public String getDescription() {
        // Если description не задан, возвращаем note
        return description != null ? description : note;
    }

    public void setDescription(String description) {
        this.description = description;
        // Для совместимости также устанавливаем note
        this.note = description;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
        // Для совместимости также устанавливаем description
        this.description = note;
    }
}