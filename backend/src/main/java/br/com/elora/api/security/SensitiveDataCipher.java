package br.com.elora.api.security;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Criptografia autenticada para campos de maior sensibilidade.
 *
 * <p>A chave vem exclusivamente do ambiente/secret manager. O contexto deve
 * conter o UID e o nome lógico do campo para impedir a troca de cifras entre
 * usuários ou colunas.</p>
 */
@Component
public class SensitiveDataCipher {

    private static final String VERSION = "v1";
    private static final int NONCE_BYTES = 12;
    private static final int TAG_BITS = 128;

    private final SecretKey key;
    private final SecureRandom secureRandom;

    public SensitiveDataCipher(
            @Value("${elora.crypto.key-base64}") String encodedKey
    ) {
        this(encodedKey, new SecureRandom());
    }

    SensitiveDataCipher(String encodedKey, SecureRandom secureRandom) {
        byte[] rawKey;
        try {
            rawKey = Base64.getDecoder().decode(encodedKey);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                    "ELORA_FIELD_ENCRYPTION_KEY deve estar em Base64", exception);
        }
        if (rawKey.length != 32) {
            throw new IllegalStateException(
                    "ELORA_FIELD_ENCRYPTION_KEY deve representar exatamente 32 bytes");
        }
        this.key = new SecretKeySpec(rawKey, "AES");
        this.secureRandom = secureRandom;
    }

    public String encrypt(String plaintext, String context) {
        if (plaintext == null) {
            return null;
        }
        requireContext(context);
        byte[] nonce = new byte[NONCE_BYTES];
        secureRandom.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, nonce));
            cipher.updateAAD(context.getBytes(StandardCharsets.UTF_8));
            byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
            Base64.Encoder encoder = Base64.getUrlEncoder().withoutPadding();
            return VERSION + "." + encoder.encodeToString(nonce)
                    + "." + encoder.encodeToString(ciphertext);
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Não foi possível criptografar o campo", exception);
        }
    }

    public String decrypt(String value, String context) {
        if (value == null) {
            return null;
        }
        requireContext(context);
        String[] parts = value.split("\\.", -1);
        if (parts.length != 3 || !VERSION.equals(parts[0])) {
            throw new IllegalArgumentException("Formato de campo criptografado desconhecido");
        }
        try {
            Base64.Decoder decoder = Base64.getUrlDecoder();
            byte[] nonce = decoder.decode(parts[1]);
            if (nonce.length != NONCE_BYTES) {
                throw new IllegalArgumentException("Nonce criptográfico inválido");
            }
            byte[] ciphertext = decoder.decode(parts[2]);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, nonce));
            cipher.updateAAD(context.getBytes(StandardCharsets.UTF_8));
            return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
        } catch (GeneralSecurityException | IllegalArgumentException exception) {
            throw new IllegalArgumentException(
                    "Campo criptografado inválido ou fora do contexto autorizado", exception);
        }
    }

    private static void requireContext(String context) {
        if (context == null || context.isBlank()) {
            throw new IllegalArgumentException("Contexto criptográfico obrigatório");
        }
    }
}

