package com.cashflip.dto;

import java.util.List;

public class CategoryDTO {
    private Long id;
    private String name;
    private int iconCode;
    private Long colorValue;
    private boolean isExpense;
    private List<String> subcategories;

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

    public int getIconCode() {
        return iconCode;
    }

    public void setIconCode(int iconCode) {
        this.iconCode = iconCode;
    }

    public Long getColorValue() {
        return colorValue;
    }

    public void setColorValue(int colorValue) {
        this.colorValue = (long) colorValue;
    }

    public boolean isExpense() {
        return isExpense;
    }

    public void setExpense(boolean expense) {
        isExpense = expense;
    }

    public List<String> getSubcategories() {
        return subcategories;
    }

    public void setSubcategories(List<String> subcategories) {
        this.subcategories = subcategories;
    }
}