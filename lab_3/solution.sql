-- Удаление таблиц, если они существуют (для чистого перезапуска)
DROP TABLE IF EXISTS attempts CASCADE;
DROP TABLE IF EXISTS exercise_words CASCADE;
DROP TABLE IF EXISTS collection_words CASCADE;
DROP TABLE IF EXISTS user_languages CASCADE;
DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS collections CASCADE;
DROP TABLE IF EXISTS words CASCADE;
DROP TABLE IF EXISTS exercise_types CASCADE;
DROP TABLE IF EXISTS languages CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS user_log CASCADE; -- Добавлена новая таблица для удаления

-- Создание таблицы Пользователи
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL
);

-- Создание таблицы Языки
CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

-- Промежуточная таблица для связи Пользователь <-> Языки (M:N)
CREATE TABLE user_languages (
    user_id INT NOT NULL,
    language_id INT NOT NULL,
    PRIMARY KEY (user_id, language_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

-- Создание таблицы Коллекции
CREATE TABLE collections (
    id SERIAL PRIMARY KEY,
    language_id INT NOT NULL,
    creator_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Создание таблицы Слова
CREATE TABLE words (
    id SERIAL PRIMARY KEY,
    language_id INT NOT NULL,
    word_text VARCHAR(255) NOT NULL,
    translation VARCHAR(255) NOT NULL,
    transcription VARCHAR(255),
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

-- Промежуточная таблица для связи Коллекции <-> Слова (M:N)
CREATE TABLE collection_words (
    collection_id INT NOT NULL,
    word_id INT NOT NULL,
    PRIMARY KEY (collection_id, word_id),
    FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

-- Создание таблицы Типы упражнений
CREATE TABLE exercise_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Создание таблицы Упражнения
CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    exercise_type_id INT NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    difficulty_level VARCHAR(255),
    FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id) ON DELETE CASCADE
);

-- Промежуточная таблица для связи Упражнения <-> Слова (M:N)
CREATE TABLE exercise_words (
    exercise_id INT NOT NULL,
    word_id INT NOT NULL,
    PRIMARY KEY (exercise_id, word_id),
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
);

-- Создание таблицы Попытки
CREATE TABLE attempts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    score INT CHECK (score >= 0 AND score <= 100),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);

-- Создание вспомогательной таблицы для аудита пользователей.
CREATE TABLE user_log (
    log_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    nickname VARCHAR(255) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Хранимые функции
CREATE OR REPLACE FUNCTION calculate_user_average_score(p_user_id INT)
RETURNS NUMERIC AS $$
DECLARE
    avg_score NUMERIC;
BEGIN
    SELECT AVG(score) INTO avg_score
    FROM attempts
    WHERE user_id = p_user_id;

    IF avg_score IS NULL THEN
        RETURN 0; -- Возвращаем 0, если у пользователя нет попыток
    END IF;

    RETURN avg_score;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- На случай, если пользователь вообще не существует (хотя внешний ключ должен предотвратить это)
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Произошла непредвиденная ошибка при расчете среднего балла для пользователя ID: %', p_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_collection_word_count(p_collection_id INT)
RETURNS INT AS $$
DECLARE
    word_count INT;
BEGIN
    SELECT COUNT(word_id) INTO word_count
    FROM collection_words
    WHERE collection_id = p_collection_id;

    IF word_count IS NULL THEN
        RETURN 0; -- Возвращаем 0, если коллекция не существует или в ней нет слов
    END IF;

    RETURN word_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- На случай, если коллекция вообще не существует (хотя внешний ключ должен предотвратить это)
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Произошла непредвиденная ошибка при подсчете слов в коллекции ID: %', p_collection_id;
END;
$$ LANGUAGE plpgsql;

-- Хранимые процедуры
CREATE OR REPLACE PROCEDURE add_new_word_to_collection(
    p_collection_id INT,
    p_language_id INT,
    p_word_text VARCHAR(255),
    p_translation VARCHAR(255),
    p_transcription VARCHAR(255) DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_word_id INT;
BEGIN
    -- Проверяем существование коллекции
    IF NOT EXISTS (SELECT 1 FROM collections WHERE id = p_collection_id) THEN
        RAISE EXCEPTION 'Коллекция с ID % не найдена.', p_collection_id;
    END IF;

    -- Проверяем, существует ли уже такое слово для данного языка
    SELECT id INTO v_word_id
    FROM words
    WHERE language_id = p_language_id AND word_text = p_word_text;

    IF v_word_id IS NULL THEN
        -- Если слово не существует, добавляем его
        INSERT INTO words (language_id, word_text, translation, transcription)
        VALUES (p_language_id, p_word_text, p_translation, p_transcription)
        RETURNING id INTO v_word_id;
    END IF;

    -- Проверяем, не привязано ли уже это слово к данной коллекции
    IF EXISTS (SELECT 1 FROM collection_words WHERE collection_id = p_collection_id AND word_id = v_word_id) THEN
        RAISE EXCEPTION 'Слово \'%\' (ID: %) уже существует в коллекции ID: %.', p_word_text, v_word_id, p_collection_id;
    END IF;

    -- Привязываем слово к коллекции
    INSERT INTO collection_words (collection_id, word_id)
    VALUES (p_collection_id, v_word_id);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'Ошибка при добавлении слова \'%\' в коллекцию ID: %: %'
            , p_word_text, p_collection_id, SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE update_attempt_score(
    p_attempt_id INT,
    p_score INT
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Проверяем существование попытки
    IF NOT EXISTS (SELECT 1 FROM attempts WHERE id = p_attempt_id) THEN
        RAISE EXCEPTION 'Попытка с ID % не найдена.', p_attempt_id;
    END IF;

    -- Проверяем валидность балла
    IF p_score < 0 OR p_score > 100 THEN
        RAISE EXCEPTION 'Балл % должен быть в диапазоне от 0 до 100.', p_score;
    END IF;

    -- Обновляем балл и время завершения попытки
    UPDATE attempts
    SET
        score = p_score,
        completed_at = CURRENT_TIMESTAMP
    WHERE
        id = p_attempt_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE EXCEPTION 'Ошибка при обновлении балла для попытки ID %: %'
            , p_attempt_id, SQLERRM;
END;
$$;

-- Триггеры
CREATE OR REPLACE FUNCTION log_new_user_registration_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_log (user_id, nickname, action_type)
    VALUES (NEW.id, NEW.nickname, 'REGISTRATION');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_new_user_registration
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION log_new_user_registration_func();

CREATE OR REPLACE FUNCTION prevent_duplicate_word_in_collection_func()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM collection_words WHERE collection_id = NEW.collection_id AND word_id = NEW.word_id) THEN
        RAISE EXCEPTION 'Слово (ID: %) уже существует в коллекции (ID: %).'
            , NEW.word_id, NEW.collection_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER prevent_duplicate_word_in_collection
BEFORE INSERT ON collection_words
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_word_in_collection_func();


-- DML-операции для демонстрации (убедитесь, что данные существуют для их выполнения)

-- Начальные данные для демонстрации
INSERT INTO users (nickname, email, hashed_password) VALUES
('user1', 'user1@example.com', 'hash1_pass1'),
('user2', 'user2@example.com', 'hash2_pass2'),
('user3', 'user3@example.com', 'hash3_pass3'),
('user4', 'user4@example.com', 'hash4_pass4');

INSERT INTO languages (name) VALUES
('English'),
('Spanish'),
('French'),
('German');

INSERT INTO user_languages (user_id, language_id) VALUES
(1, 1), -- user1 изучает English
(1, 2), -- user1 изучает Spanish
(2, 1), -- user2 изучает English
(3, 3), -- user3 изучает French
(4, 4); -- user4 изучает German

INSERT INTO collections (language_id, creator_id, name) VALUES
(1, 1, 'English Basics'),
(1, 2, 'Advanced English'),
(2, 1, 'Spanish Phrases'),
(3, 3, 'French Verbs');

INSERT INTO words (language_id, word_text, translation, transcription) VALUES
(1, 'Hello', 'Привет', '/həˈloʊ/'),
(1, 'World', 'Мир', '/wɜːrld/'),
(1, 'Apple', 'Яблоко', '/ˈæpl/'),
(2, 'Hola', 'Привет', '/ˈo.la/'),
(2, 'Gracias', 'Спасибо', '/ˈɡra.θjas/'),
(3, 'Bonjour', 'Привет', '/bɔ̃ʒuʁ/'),
(3, 'Merci', 'Спасибо', '/mɛʁsi/');

INSERT INTO exercise_types (name) VALUES
('Flashcards'),
('Test'),
('Quiz'),
('Typing');

INSERT INTO exercises (exercise_type_id, exercise_name, difficulty_level) VALUES
(1, 'Basic English Words', 'Beginner'),
(2, 'English Grammar Test', 'Intermediate'),
(1, 'Spanish Greetings Practice', 'Beginner'),
(3, 'French Verb Conjugation', 'Intermediate');

INSERT INTO exercise_words (exercise_id, word_id) VALUES
(1, 1), -- Basic English Words: Hello
(1, 2), -- Basic English Words: World
(1, 3), -- Basic English Words: Apple
(2, 1), -- English Grammar Test: Hello
(2, 2), -- English Grammar Test: World
(3, 4), -- Spanish Greetings Practice: Hola
(3, 5), -- Spanish Greetings Practice: Gracias
(4, 6), -- French Verb Conjugation: Bonjour
(4, 7); -- French Verb Conjugation: Merci

INSERT INTO attempts (user_id, exercise_id, started_at, completed_at, score) VALUES
(1, 1, '2023-10-26 10:00:00', '2023-10-26 10:10:00', 85),
(1, 1, '2023-10-27 11:00:00', '2023-10-27 11:15:00', 90),
(2, 1, '2023-10-26 10:05:00', '2023-10-26 10:12:00', 70),
(3, 4, '2023-10-26 12:00:00', '2023-10-26 12:20:00', 95),
(1, 2, '2023-10-28 09:00:00', '2023-10-28 09:25:00', 75);

-- Демонстрация хранимых функций
SELECT calculate_user_average_score(1) AS user_1_avg_score;
SELECT calculate_user_average_score(999) AS non_existent_user_avg_score;

SELECT get_collection_word_count(1) AS collection_1_word_count;
SELECT get_collection_word_count(999) AS non_existent_collection_word_count;

-- Демонстрация хранимых процедур
CALL add_new_word_to_collection(1, 1, 'DemoWord', 'Демо Слово', '/ˈdemə wɜːrd/');
SELECT w.word_text, c.name FROM words w JOIN collection_words cw ON w.id = cw.word_id JOIN collections c ON cw.collection_id = c.id WHERE w.word_text = 'DemoWord';

-- Следующие CALL закомментированы, так как они вызывают ошибки для демонстрации
-- CALL add_new_word_to_collection(999, 1, 'FailWord', 'Проваливающееся Слово');
-- CALL add_new_word_to_collection(1, 1, 'Hello', 'Привет');

SELECT id, score, completed_at FROM attempts WHERE id = 1;
CALL update_attempt_score(1, 98);
SELECT id, score, completed_at FROM attempts WHERE id = 1;

-- Следующие CALL закомментированы, так как они вызывают ошибки для демонстрации
-- CALL update_attempt_score(999, 80);
-- CALL update_attempt_score(1, 105);

-- Демонстрация триггеров
INSERT INTO users (nickname, email, hashed_password) VALUES ('trigger_user', 'trigger@example.com', 'trigger_hash');
SELECT * FROM user_log;

-- Следующие INSERT закомментированы, так как они вызывают ошибки для демонстрации
-- INSERT INTO collection_words (collection_id, word_id) VALUES (1, 1);

INSERT INTO words (language_id, word_text, translation, transcription) VALUES (1, 'TrulyUniqueWord', 'Действительно Уникальное Слово', '/ˈtruːli juːˈniːk wɜːrd/');
INSERT INTO collection_words (collection_id, word_id) VALUES (1, (SELECT id FROM words WHERE word_text = 'TrulyUniqueWord'));
SELECT c.name AS collection_name, w.word_text FROM collection_words cw JOIN collections c ON cw.collection_id = c.id JOIN words w ON cw.word_id = w.id WHERE w.word_text = 'TrulyUniqueWord';
