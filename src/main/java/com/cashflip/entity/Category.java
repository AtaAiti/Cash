package com.cashflip.entity;

import jakarta.persistence.*;
import java.util.Objects;

@Entity
@Table(name = "categories")
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Убедитесь, что ID генерируется правильно
    private Long id;
    
    private String name;
    private String icon;
    private String color;
    private Boolean isExpense; // true = расход, false = доход
    
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    
    // Конструкторы
    public Category() {
    }
    
    public Category(Long id, String name, String icon, String color, Boolean isExpense, User user) {
        this.id = id;
        this.name = name;
        this.icon = icon;
        this.color = color;
        this.isExpense = isExpense;
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
    
    public String getIcon() {
        return icon;
    }
    
    public void setIcon(String icon) {
        this.icon = icon;
    }
    
    public String getColor() {
        return color;
    }
    
    public void setColor(String color) {
        this.color = color;
    }
    
    public Boolean getIsExpense() {
        return isExpense;
    }
    
    public void setIsExpense(Boolean isExpense) {
        this.isExpense = isExpense;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    // Паттерн Builder
    public static CategoryBuilder builder() {
        return new CategoryBuilder();
    }
    
    public static class CategoryBuilder {
        private Long id;
        private String name;
        private String icon;
        private String color;
        private Boolean isExpense;
        private User user;
        
        public CategoryBuilder id(Long id) {
            this.id = id;
            return this;
        }
        
        public CategoryBuilder name(String name) {
            this.name = name;
            return this;
        }
        
        public CategoryBuilder icon(String icon) {
            this.icon = icon;
            return this;
        }
        
        public CategoryBuilder color(String color) {
            this.color = color;
            return this;
        }
        
        public CategoryBuilder isExpense(Boolean isExpense) {
            this.isExpense = isExpense;
            return this;
        }
        
        public CategoryBuilder user(User user) {
            this.user = user;
            return this;
        }
        
        public Category build() {
            return new Category(id, name, icon, color, isExpense, user);
        }
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Category category = (Category) o;
        return Objects.equals(id, category.id) &&
               Objects.equals(name, category.name);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id, name);
    }
    
    @Override
    public String toString() {
        return "Category{" +
               "id=" + id +
               ", name='" + name + '\'' +
               ", isExpense=" + isExpense +
               '}';
    }
}