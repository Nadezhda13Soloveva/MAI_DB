# Лабораторная работа №3: Программируемые объекты БД

## 1. Цель работы

Освоение методов создания и использования хранимых процедур, функций и триггеров в реляционных базах данных для реализации бизнес-логики, повышения эффективности и обеспечения целостности данных, включая механизмы обработки ошибок.

## 2. Задачи работы

1.  Разработать не менее 2-3 хранимых процедур и функций, реализующих бизнес-логику и вычисляемые показатели.
2.  Создать 2-3 триггера для проверки бизнес-правил и ведения статистики/аудита.
3.  Реализовать обработку системных ошибок в процедурах и триггерах с преобразованием их в понятные бизнес-сообщения.
4.  Подготовить DML-операции для демонстрации работы процедур, функций и триггеров.

Лабораторная работа выполняется на основе структуры базы данных, разработанной в Лабораторной работе №1 и наполненной данными в Лабораторной работе №2. 

### Вариант 19: Приложение для изучения языков (Vocabulary Trainer)

**Описание:** Пользователи создают коллекции слов и фраз для изучения (словари). Система предоставляет упражнения для запоминания (карточки, тесты) и отслеживает прогресс изучения каждого слова.

## 3. Теоретические сведения

**Хранимая процедура** — это именованный блок операторов SQL, который хранится в базе данных и может быть вызван многократно. Процедуры могут принимать параметры, но не возвращают значения напрямую (хотя могут использовать выходные параметры). Они часто используются для выполнения сложных операций DML или для инкапсуляции бизнес-логики.

**Хранимая функция** — это также именованный блок операторов SQL, хранящийся в базе данных, который всегда возвращает значение. Функции могут быть использованы в выражениях SQL (например, в `SELECT`, `WHERE`, `HAVING`).

**Триггер** — это специальный тип хранимой процедуры, которая автоматически выполняется (срабатывает) в ответ на определенные события в базе данных (например, `INSERT`, `UPDATE`, `DELETE`) на указанной таблице. Триггеры используются для обеспечения целостности данных, автоматизации задач, ведения аудита или реализации сложных бизнес-правил.

PostgreSQL позволяет **обрабатывать ошибки** внутри PL/pgSQL-блоков с помощью конструкции `EXCEPTION`. Это позволяет перехватывать системные ошибки и возвращать пользовательские сообщения, делая работу с БД более удобной и информативной.

## 4. Решение

### 4.1. Хранимые функции

#### 4.1.1. Функция `calculate_user_average_score`

Эта функция вычисляет средний балл пользователя по всем его попыткам. Если пользователь не найден или у него нет попыток, функция вернет 0 и обработает исключение.

```sql
CREATE OR REPLACE FUNCTION calculate_user_average_score(p_user_id INT)
RETURNS NUMERIC AS $$
DECLARE
    avg_score NUMERIC(5, 2); -- локальная переменная
BEGIN
    SELECT AVG(score) INTO avg_score
    FROM attempts
    WHERE user_id = p_user_id;

    IF avg_score IS NULL THEN
        RETURN 0; -- возвращаем 0, если у пользователя нет попыток
    END IF;

    RETURN avg_score;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Произошла непредвиденная ошибка при расчете среднего балла для пользователя ID: %', p_user_id;
END;
$$ LANGUAGE plpgsql;
```

**Пример использования:**

```sql
SELECT calculate_user_average_score(1);
SELECT calculate_user_average_score(999); -- Пользователь не существует
```

#### 4.1.2. Функция `get_collection_word_count`

Эта функция возвращает кол-во слов в конкретной коллекции. Если коллекция не найдена, функция вернет 0 и обработает исключение.

```sql
CREATE OR REPLACE FUNCTION get_collection_word_count(p_collection_id INT)
RETURNS INT AS $$
DECLARE
    word_count INT;
BEGIN
    SELECT COUNT(word_id) INTO word_count
    FROM collection_words
    WHERE collection_id = p_collection_id;

    IF word_count IS NULL THEN
        RETURN 0; -- возвращаем 0, если коллекция не существует или в ней нет слов
    END IF;

    RETURN word_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Произошла непредвиденная ошибка при подсчете слов в коллекции ID: %', p_collection_id;
END;
$$ LANGUAGE plpgsql;
```

**Пример использования:**

```sql
SELECT get_collection_word_count(1);
SELECT get_collection_word_count(999); -- Коллекция не существует
```

### 4.2. Хранимые процедуры

#### 4.2.1. Процедура `add_new_word_to_collection`

Эта процедура добавляет новое слово в таблицу `words` и затем связывает его с указанной коллекцией в таблице `collection_words`. Процедура включает обработку ошибок, например, если коллекция не существует или слово уже присутствует в коллекции.

```sql
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
    -- проверяем существование коллекции
    IF NOT EXISTS (SELECT 1 FROM collections WHERE id = p_collection_id) THEN
        RAISE EXCEPTION 'Коллекция с ID % не найдена.', p_collection_id;
    END IF;

    -- проверяем, существует ли уже такое слово для данного языка
    SELECT id INTO v_word_id
    FROM words
    WHERE language_id = p_language_id AND word_text = p_word_text;

    IF v_word_id IS NULL THEN
        -- если слово не существует -> добавляем его
        INSERT INTO words (language_id, word_text, translation, transcription)
        VALUES (p_language_id, p_word_text, p_translation, p_transcription)
        RETURNING id INTO v_word_id;
    END IF;

    -- проверяем, не привязано ли уже это слово к данной коллекции
    IF EXISTS (SELECT 1 FROM collection_words WHERE collection_id = p_collection_id AND word_id = v_word_id) THEN
        RAISE EXCEPTION 'Слово \'%\' (ID: %) уже существует в коллекции ID: %.', p_word_text, v_word_id, p_collection_id;
    END IF;

    --привязываем слово к коллекции
    INSERT INTO collection_words (collection_id, word_id)
    VALUES (p_collection_id, v_word_id);

EXCEPTION
    WHEN OTHERS THEN -- перехватывает любые другие неопределенные исключения
        RAISE EXCEPTION 'Ошибка при добавлении слова \'%\' в коллекцию ID: %: %'
            , p_word_text, p_collection_id, SQLERRM;
END;
$$;
```

**Пример использования:**

```sql
CALL add_new_word_to_collection(1, 1, 'NewWord', 'Новое Слово', '/nuː wɜːrd/');
CALL add_new_word_to_collection(999, 1, 'Test', 'Тест'); -- Ошибка: коллекция не найдена
CALL add_new_word_to_collection(1, 1, 'Hello', 'Привет'); -- Ошибка: слово уже в коллекции
```

#### 4.2.2. Процедура `update_attempt_score`

Эта процедура обновляет балл за конкретную попытку пользователя и устанавливает время завершения. Процедура включает проверку существования попытки и валидность балла.

```sql
CREATE OR REPLACE PROCEDURE update_attempt_score(
    p_attempt_id INT,
    p_score INT
)
LANGUAGE plpgsql AS $$
BEGIN
    -- проверяем существование попытки
    IF NOT EXISTS (SELECT 1 FROM attempts WHERE id = p_attempt_id) THEN
        RAISE EXCEPTION 'Попытка с ID % не найдена.', p_attempt_id;
    END IF;

    -- проверяем валидность балла
    IF p_score < 0 OR p_score > 100 THEN
        RAISE EXCEPTION 'Балл % должен быть в диапазоне от 0 до 100.', p_score;
    END IF;

    -- обновляем балл и время завершения попытки
    UPDATE attempts
    SET
        score = p_score,
        completed_at = CURRENT_TIMESTAMP
    WHERE
        id = p_attempt_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при обновлении балла для попытки ID %: %'
            , p_attempt_id, SQLERRM;
END;
$$;
```

**Пример использования:**

```sql
CALL update_attempt_score(1, 95); -- Корректное обновление для существующей попытки
CALL update_attempt_score(999, 80); -- Ошибка: попытка не найдена
CALL update_attempt_score(1, 101); -- Ошибка: невалидный балл
```

### 4.3. Триггеры

Для работы с триггерами создадим вспомогательную таблицу для аудита пользователей.

```sql
CREATE TABLE user_log (
    log_id SERIAL PRIMARY KEY,
    user_id INT,
    nickname VARCHAR(255) NOT NULL, -- компромисс между нормализацией и сохранением исторической информации аудита
    action_type VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL -- user_id обнуляется при удалении пользователя, логи сохраняются
);
```

#### 4.3.1. Триггер `log_new_user_registration`

Этот триггер срабатывает `AFTER INSERT` на таблице `users` и записывает информацию о каждом новом зарегистрированном пользователе в таблицу `user_log`.

```sql
CREATE OR REPLACE FUNCTION log_new_user_registration_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_log (user_id, nickname, action_type)
    VALUES (NEW.id, NEW.nickname, 'REGISTRATION');
    RETURN NEW; -- после регистрации пользователя NEW должна быть передана дальше для завершения операции INSERT в users
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_new_user_registration
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION log_new_user_registration_func();
```

#### 4.3.2. Триггер `log_user_updates`

Этот триггер срабатывает `AFTER UPDATE` на таблице `users` и записывает информацию об изменениях пользователя в таблицу `user_log`.

```sql
CREATE OR REPLACE FUNCTION log_user_updates_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_log (user_id, nickname, action_type)
    VALUES (NEW.id, NEW.nickname, 'UPDATE');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_user_updates
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_updates_func();
```

#### 4.3.3. Триггер `log_user_deletions`

Этот триггер срабатывает `AFTER DELETE` на таблице `users` и записывает информацию об удалении пользователя в таблицу `user_log`.

```sql
CREATE OR REPLACE FUNCTION log_user_deletions_func()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_log (user_id, nickname, action_type)
    VALUES (OLD.id, OLD.nickname, 'DELETE');
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER log_user_deletions
AFTER DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_deletions_func();
```

#### 4.3.4. Триггер `prevent_duplicate_word_in_collection`

Этот триггер срабатывает `BEFORE INSERT` на таблице `collection_words` и проверяет, не привязано ли уже добавляемое слово к данной коллекции. Если слово уже существует, триггер отменит операцию вставки и выдаст пользовательскую ошибку.

```sql
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
```

**Пример использования (DML):**

```sql
-- Попытка добавить существующее слово в коллекцию (должна вызвать ошибку)
INSERT INTO collection_words (collection_id, word_id) VALUES (1, 1);
-- Попытка добавить новое слово в коллекцию (должна пройти успешно)
INSERT INTO words (language_id, word_text, translation, transcription) VALUES (1, 'UniqueWord', 'Уникальное Слово', '/juːˈniːk wɜːrd/');
INSERT INTO collection_words (collection_id, word_id) VALUES (1, (SELECT id FROM words WHERE word_text = 'UniqueWord'));
```

### 4.4. DML-операции для демонстрации

Ниже приведены DML-операции, демонстрирующие работу разработанных хранимых функций, процедур и триггеров.

#### 4.4.1. Демонстрация хранимых функций

```sql
-- Вычисление среднего балла пользователя с ID = 1
SELECT calculate_user_average_score(1) AS user_1_avg_score;
-- Попытка вычисления среднего балла для несуществующего пользователя (вернет 0)
SELECT calculate_user_average_score(999) AS non_existent_user_avg_score;

-- Подсчет слов в коллекции с ID = 1
SELECT get_collection_word_count(1) AS collection_1_word_count;
-- Попытка подсчета слов для несуществующей коллекции (вернет 0)
SELECT get_collection_word_count(999) AS non_existent_collection_word_count;
```

#### 4.4.2. Демонстрация хранимых процедур

```sql
-- Добавление нового слова в коллекцию (успешно)
CALL add_new_word_to_collection(1, 1, 'DemoWord', 'Демо Слово', '/ˈdemə wɜːrd/');
SELECT w.word_text, c.name FROM words w JOIN collection_words cw ON w.id = cw.word_id JOIN collections c ON cw.collection_id = c.id WHERE w.word_text = 'DemoWord';

-- Попытка добавить слово в несуществующую коллекцию (вызовет ошибку)
-- CALL add_new_word_to_collection(999, 1, 'FailWord', 'Проваливающееся Слово');

-- Попытка добавить существующее слово в коллекцию (вызовет ошибку)
-- CALL add_new_word_to_collection(1, 1, 'Hello', 'Привет');

-- Обновление балла для существующей попытки (успешно)
SELECT id, score, completed_at FROM attempts WHERE id = 1;
CALL update_attempt_score(1, 98);
SELECT id, score, completed_at FROM attempts WHERE id = 1;

-- Попытка обновления балла для несуществующей попытки (вызовет ошибку)
-- CALL update_attempt_score(999, 80);

-- Попытка обновления балла с невалидным значением (вызовет ошибку)
-- CALL update_attempt_score(1, 105);
```

#### 4.4.3. Демонстрация триггеров

```sql
-- Добавление нового пользователя (сработает триггер log_new_user_registration)
INSERT INTO users (nickname, email, hashed_password) VALUES ('trigger_user', 'trigger@example.com', 'trigger_hash');
SELECT * FROM user_log;

-- Попытка добавить существующее слово в коллекцию (сработает триггер prevent_duplicate_word_in_collection и вызовет ошибку)
-- INSERT INTO collection_words (collection_id, word_id) VALUES (1, 1);

-- Добавление нового уникального слова и его привязка к коллекции (пройдет успешно)
INSERT INTO words (language_id, word_text, translation, transcription) VALUES (1, 'TrulyUniqueWord', 'Действительно Уникальное Слово', '/ˈtruːli juːˈniːk wɜːrd/');
INSERT INTO collection_words (collection_id, word_id) VALUES (1, (SELECT id FROM words WHERE word_text = 'TrulyUniqueWord'));
SELECT c.name AS collection_name, w.word_text FROM collection_words cw JOIN collections c ON cw.collection_id = c.id JOIN words w ON cw.word_id = w.id WHERE w.word_text = 'TrulyUniqueWord';
```

