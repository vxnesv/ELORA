package br.com.elora.api.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.security.SecureRandom;
import java.util.Base64;
import org.junit.jupiter.api.Test;

class SensitiveDataCipherTest {

    private static final String KEY = Base64.getEncoder().encodeToString(new byte[32]);

    @Test
    void encryptsAndDecryptsOnlyInTheSameContext() {
        SensitiveDataCipher cipher = new SensitiveDataCipher(KEY, new SecureRandom());

        String encrypted = cipher.encrypt("informação sensível", "uid-1:consultation-note");

        assertThat(encrypted).doesNotContain("informação sensível");
        assertThat(cipher.decrypt(encrypted, "uid-1:consultation-note"))
                .isEqualTo("informação sensível");
        assertThatThrownBy(() -> cipher.decrypt(encrypted, "uid-2:consultation-note"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsKeysThatAreNotAes256() {
        String shortKey = Base64.getEncoder().encodeToString(new byte[16]);

        assertThatThrownBy(() -> new SensitiveDataCipher(shortKey, new SecureRandom()))
                .isInstanceOf(IllegalStateException.class);
    }
}

