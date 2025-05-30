package com.cashflip.service;

import com.cashflip.dto.UserDTO;
import org.springframework.security.core.context.SecurityContextHolder;
import com.cashflip.entity.User;
import com.cashflip.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    // Получить текущего пользователя
    public UserDTO getCurrentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        // Преобразование User -> UserDTO (добавьте поля по необходимости)
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setName(user.getName());
        dto.setEmail(user.getEmail());
        return dto;
    }

    // Обновить текущего пользователя
    public UserDTO updateCurrentUser(UserDTO userDTO) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setName(userDTO.getName());
        // Можно добавить обновление других полей, если нужно
        userRepository.save(user);
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setName(user.getName());
        dto.setEmail(user.getEmail());
        return dto;
    }

    public String getGreeting() {
        return "Hello from UserService!";
    }
}
