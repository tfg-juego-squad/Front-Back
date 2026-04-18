package org.example.backendapi.service;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class SecurityService {
    public String hashPassword(String password) {
        int logRounds = 12;
        return BCrypt.hashpw(password, BCrypt.gensalt(logRounds));
    }

    public boolean checkPassword(String passwordPlana, String hashAlmacenado) {
        return BCrypt.checkpw(passwordPlana, hashAlmacenado);
    }

    public String generarPasswordAleatoria(int length) {
        String caracteres = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        StringBuilder password = new StringBuilder();
        Random random = new Random();
        for (int i = 0; i < length; i++) {
            password.append(caracteres.charAt(random.nextInt(caracteres.length())));
        }
        return password.toString();
    }
}