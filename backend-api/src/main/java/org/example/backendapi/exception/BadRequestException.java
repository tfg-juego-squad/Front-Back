package org.example.backendapi.exception;

// Hereda de RuntimeException para no obligar a poner try-catch en todas partes
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}