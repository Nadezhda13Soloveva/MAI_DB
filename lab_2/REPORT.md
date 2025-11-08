# Лабораторная работа №2: Работа с данными в реляционных базах данных

## 1. Цель работы

Приобретение практических навыков работы с языком SQL для манипулирования данными (DML-операции), выполнения сложных запросов с агрегацией и соединениями, а также создания представлений (VIEW) для упрощения доступа к данным.

## 2. Задачи работы

1.  Подготовить DDL-скрипты для создания таблиц на основе модели данных из лабораторной работы №1.
2.  Наполнить таблицы случайными данными с использованием DML-скриптов (INSERT INTO).
3.  Разработать DML-скрипты для обновления и удаления записей.
4.  Создать SQL-запросы с агрегатными функциями для анализа данных.
5.  Разработать SQL-запросы с использованием различных типов соединений для получения связанных данных.
6.  Создать 2-3 осмысленных представления (CREATE VIEW) для решения конкретных аналитических задач.

### Вариант 19: Приложение для изучения языков (Vocabulary Trainer)

**Описание:** Пользователи создают коллекции слов и фраз для изучения (словари). Система предоставляет упражнения для запоминания (карточки, тесты) и отслеживает прогресс изучения каждого слова.

## 3. Теоретические сведения

### 3.1. Языки SQL

*   **DDL (Data Definition Language)** — язык определения данных. Используется для создания, изменения и удаления объектов базы данных (таблиц, индексов, представлений и т.д.). Основные команды: `CREATE`, `ALTER`, `DROP`.

*   **DML (Data Manipulation Language)** — язык манипулирования данными. Используется для добавления, обновления, удаления и извлечения данных из базы данных. Основные команды: `INSERT`, `UPDATE`, `DELETE`, `SELECT`.

*   **DCL (Data Control Language)** — язык управления данными. Используется для управления правами доступа к данным. Основные команды: `GRANT`, `REVOKE`.

*   **TCL (Transaction Control Language)** — язык управления транзакциями. Используется для управления транзакциями в базе данных, обеспечивая целостность данных. Основные команды: `COMMIT`, `ROLLBACK`, `SAVEPOINT`.

### 3.2. Агрегатные функции

Агрегатные функции выполняют вычисления над набором строк и возвращают одно результирующее значение.

Основные агрегатные функции:

*   **`COUNT()`**: Возвращает кол-во строк или значений.
*   **`SUM()`**: Вычисляет сумму значений числового столбца.
*   **`AVG()`**: Вычисляет среднее значение числового столбца.
*   **`MIN()`**: Возвращает минимальное значение в столбце.
*   **`MAX()`**: Возвращает максимальное значение в столбце.

### 3.3. Типы соединений (JOIN)

Соединения используются для объединения строк из двух или более таблиц на основе связанных столбцов между ними.

Основные типы соединений:

*   **`INNER JOIN`**: Возвращает только те строки, которые имеют совпадающие значения в обеих таблицах.
*   **`LEFT JOIN` (или `LEFT OUTER JOIN`)**: Возвращает все строки из левой таблицы и совпадающие строки из правой таблицы. Если совпадений нет, для столбцов из правой таблицы возвращается `NULL`.
*   **`RIGHT JOIN` (или `RIGHT OUTER JOIN`)**: Возвращает все строки из правой таблицы и совпадающие строки из левой таблицы. Если совпадений нет, для столбцов из левой таблицы возвращается `NULL`.
*   **`FULL JOIN` (или `FULL OUTER JOIN`)**: Возвращает все строки, когда есть совпадение в одной из таблиц. Если совпадений нет, для отсутствующих столбцов возвращается `NULL`.

### 3.4. Представления (VIEW)

**Представление** — это виртуальная таблица, основанная на результирующем наборе оператора SQL. Представление содержит строки и столбцы, как и реальная таблица, но не хранит данные самостоятельно. Данные представления генерируются динамически при каждом обращении к нему на основе базовых таблиц. 

## 4. Решение
### 4.1. Схема базы данных (DDL-скрипты)

На основе лабораторной работы №1, приводим DDL-скрипты для создания таблиц:
- Добавлено ограничение на кол-во баллов

```sql
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

-- Создание таблицы Упражнения
CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    language_id INT NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    difficulty_level VARCHAR(255),
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
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
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    attempt_date_time_start TIMESTAMP NOT NULL,
    attempt_date_time_end TIMESTAMP,
    result INT CHECK (result >= 0 AND result <= 100), -- баллов из 100, ограничение: от 0 до 100
    PRIMARY KEY (user_id, exercise_id, attempt_date_time_start), -- Композитный ключ для уникальности попыток
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);
```

### 4.2. Наполнение базы данных (DML-скрипты: INSERT INTO)

```sql
INSERT INTO users (nickname, email, hashed_password) VALUES
('user1', 'user1@example.com', 'hash1_pass1'),
('user2', 'user2@example.com', 'hash2_pass2'),
('user3', 'user3@example.com', 'hash3_pass3'),
('user4', 'user4@example.com', 'hash4_pass4'),
```

```sql
INSERT INTO languages (name) VALUES
('English'),
('Spanish'),
('French'),
('German'),
```

```sql
INSERT INTO user_languages (user_id, language_id) VALUES
(1, 1), -- user1 изучает English
(1, 2), -- user1 изучает Spanish
(2, 1), -- user2 изучает English
(3, 3), -- user3 изучает French
(4, 4), -- user4 изучает German
```

```sql
INSERT INTO collections (language_id, creator_id, name) VALUES
(1, 1, 'English Basics'),
(1, 2, 'Advanced English'),
(2, 1, 'Spanish Phrases'),
(3, 3, 'French Verbs'),
```

```sql
INSERT INTO words (language_id, word_text, translation, transcription) VALUES
(1, 'Hello', 'Привет', '/həˈloʊ/'),
(1, 'World', 'Мир', '/wɜːrld/'),
(1, 'Apple', 'Яблоко', '/ˈæpl/'),
(2, 'Hola', 'Привет', '/ˈo.la/'),
(2, 'Gracias', 'Спасибо', '/ˈɡra.θjas/'),
(3, 'Bonjour', 'Привет', '/bɔ̃ʒuʁ/'),
(3, 'Merci', 'Спасибо', '/mɛʁsi/');
```

```sql
INSERT INTO collection_words (collection_id, word_id) VALUES
(1, 1), -- English Basics: Hello
(1, 2), -- English Basics: World
(1, 3), -- English Basics: Apple
(2, 1), -- Advanced English: Hello
(2, 2), -- Advanced English: World
(3, 4), -- Spanish Phrases: Hola
(3, 5), -- Spanish Phrases: Gracias
(4, 6), -- French Verbs: Bonjour
(4, 7), -- French Verbs: Merci
```

```sql
INSERT INTO exercises (language_id, exercise_name, type, difficulty_level) VALUES
(1, 'Basic English Words', 'Flashcards', 'Beginner'),
(1, 'English Grammar Test', 'Test', 'Intermediate'),
(2, 'Spanish Greetings Practice', 'Flashcards', 'Beginner'),
(3, 'French Verb Conjugation', 'Quiz', 'Intermediate'),
```

```sql
INSERT INTO exercise_words (exercise_id, word_id) VALUES
(1, 1), -- Basic English Words: Hello
(1, 2), -- Basic English Words: World
(1, 3), -- Basic English Words: Apple
(2, 1), -- English Grammar Test: Hello
(2, 2), -- English Grammar Test: World
(3, 4), -- Spanish Greetings Practice: Hola
(3, 5), -- Spanish Greetings Practice: Gracias
(4, 6), -- French Verb Conjugation: Bonjour
(4, 7), -- French Verb Conjugation: Merci
```

```sql
INSERT INTO attempts (user_id, exercise_id, attempt_date_time_start, attempt_date_time_end, result) VALUES
(1, 1, '2023-10-26 10:00:00', '2023-10-26 10:10:00', 85),
(1, 1, '2023-10-27 11:00:00', '2023-10-27 11:15:00', 90),
(2, 1, '2023-10-26 10:05:00', '2023-10-26 10:12:00', 70),
(3, 4, '2023-10-26 12:00:00', '2023-10-26 12:20:00', 95),
(4, 5, '2023-10-26 13:00:00', '2023-10-26 13:30:00', 80),
(1, 2, '2023-10-28 09:00:00', '2023-10-28 09:25:00', 75),
(5, 5, '2023-10-28 14:00:00', '2023-10-28 14:10:00', 60);
```

### 4.3. Простые DML-операции

#### 4.3.1. Вставка новых записей (INSERT INTO)

Примеры вставок уже были представлены в разделе "Наполнение базы данных".

#### 4.3.2. Обновление существующих записей (UPDATE)

Примеры обновления данных:

```sql
-- Обновить никнейм пользователя с ID = 1
UPDATE users
SET nickname = 'NewUser1'
WHERE id = 1;

-- Обновить результат попытки для пользователя 1, упражнения 1, начатой в 2023-10-26 10:00:00
UPDATE attempts
SET result = 92,
    attempt_date_time_end = '2023-10-26 10:11:00'
WHERE user_id = 1 AND exercise_id = 1 AND attempt_date_time_start = '2023-10-26 10:00:00';

-- Изменить уровень сложности упражнения 'Basic English Words' на 'Intermediate'
UPDATE exercises
SET difficulty_level = 'Intermediate'
WHERE exercise_name = 'Basic English Words';
```

#### 4.3.3. Удаление определённых записей (DELETE)

Примеры удаления данных:

```sql
-- Удалить пользователя с ID = 2
DELETE FROM users
WHERE id = 2;

-- Удалить слово 'Apple'
DELETE FROM words
WHERE word_text = 'Apple';

-- Удалить все попытки пользователя 5
DELETE FROM attempts
WHERE user_id = 5;
```

### 4.4 Запросы с агрегацией

Примеры запросов с агрегатными функциями:

```sql
-- 1. Общее количество попыток для каждого пользователя
SELECT
    u.nickname,
    COUNT(a.user_id) AS total_attempts
FROM
    users u
LEFT JOIN
    attempts a ON u.id = a.user_id
GROUP BY
    u.nickname
ORDER BY
    total_attempts DESC;

-- 2. Средний балл за попытки по каждому упражнению
SELECT
    e.exercise_name,
    AVG(a.result) AS average_score
FROM
    exercises e
JOIN
    attempts a ON e.id = a.exercise_id
GROUP BY
    e.exercise_name
ORDER BY
    average_score DESC;

-- 3. Максимальный и минимальный балл по всем попыткам
SELECT
    MAX(result) AS max_score,
    MIN(result) AS min_score
FROM
    attempts;

-- 4. Количество слов в каждой коллекции
SELECT
    c.name AS collection_name,
    COUNT(cw.word_id) AS total_words
FROM
    collections c
LEFT JOIN
    collection_words cw ON c.id = cw.collection_id
GROUP BY
    c.name
ORDER BY
    total_words DESC;

-- 5. Количество пользователей, изучающих каждый язык (для языков, которые изучаются более чем 1 пользователем)
SELECT
    l.name AS language_name,
    COUNT(ul.user_id) AS num_users
FROM
    languages l
JOIN
    user_languages ul ON l.id = ul.language_id
GROUP BY
    l.name
HAVING
    COUNT(ul.user_id) > 1
ORDER BY
    num_users DESC;
```

### 4.5. Запросы с соединениями таблиц

```sql
-- 1. Получить информацию о пользователях и языках, которые они изучают (INNER JOIN)
SELECT
    u.nickname,
    u.email,
    l.name AS language_name
FROM
    users u
JOIN
    user_languages ul ON u.id = ul.user_id
JOIN
    languages l ON ul.language_id = l.id;

-- 2. Получить все слова в каждой коллекции, включая информацию о языке (LEFT JOIN)
SELECT
    c.name AS collection_name,
    w.word_text,
    w.translation,
    l.name AS language_name
FROM
    collections c
LEFT JOIN
    collection_words cw ON c.id = cw.collection_id
LEFT JOIN
    words w ON cw.word_id = w.id
LEFT JOIN
    languages l ON w.language_id = l.id
ORDER BY
    c.name, w.word_text;

-- 3. Получить упражнения и слова, которые в них используются, для определенного языка (например, English)
SELECT
    e.exercise_name,
    e.type,
    e.difficulty_level,
    w.word_text,
    w.translation
FROM
    exercises e
JOIN
    exercise_words ew ON e.id = ew.exercise_id
JOIN
    words w ON ew.word_id = w.id
JOIN
    languages l ON e.language_id = l.id
WHERE
    l.name = 'English';

-- 4. Получить все попытки пользователей, включая их никнеймы, названия упражнений и результаты
SELECT
    u.nickname,
    e.exercise_name,
    a.attempt_date_time_start,
    a.attempt_date_time_end,
    a.result
FROM
    attempts a
JOIN
    users u ON a.user_id = u.id
JOIN
    exercises e ON a.exercise_id = e.id
ORDER BY
    u.nickname, a.attempt_date_time_start;
```

### 4.6. Создание представлений

```sql
-- 1. Представление 'user_language_progress': Показывает прогресс пользователей по языкам
CREATE VIEW user_language_progress AS
SELECT
    u.id AS user_id,
    u.nickname,
    l.name AS language_name,
    COUNT(DISTINCT a.exercise_id) AS completed_exercises,
    AVG(a.result) AS average_score,
    MAX(a.attempt_date_time_end) AS last_attempt_date
FROM
    users u
JOIN
    user_languages ul ON u.id = ul.user_id
JOIN
    languages l ON ul.language_id = l.id
LEFT JOIN
    exercises e ON l.id = e.language_id
LEFT JOIN
    attempts a ON u.id = a.user_id AND e.id = a.exercise_id
GROUP BY
    u.id, u.nickname, l.name
ORDER BY
    u.nickname, l.name;

-- 2. Представление 'collection_word_counts': Показывает количество слов в каждой коллекции по языкам
CREATE VIEW collection_word_counts AS
SELECT
    c.id AS collection_id,
    c.name AS collection_name,
    l.name AS language_name,
    COUNT(cw.word_id) AS total_words,
    MAX(w.id) AS last_word_id -- Пример дополнительного атрибута (идентификатор последнего добавленного слова)
FROM
    collections c
JOIN
    languages l ON c.language_id = l.id
LEFT JOIN
    collection_words cw ON c.id = cw.collection_id
LEFT JOIN
    words w ON cw.word_id = w.id
GROUP BY
    c.id, c.name, l.name
ORDER BY
    total_words DESC, collection_name;

-- 3. Представление 'top_performing_users': Топ-пользователи по среднему баллу за все попытки
CREATE VIEW top_performing_users AS
SELECT
    u.id AS user_id,
    u.nickname,
    u.email,
    AVG(a.result) AS overall_average_score,
    COUNT(a.id) AS total_attempts,
    MAX(a.attempt_date_time_end) AS last_activity
FROM
    users u
JOIN
    attempts a ON u.id = a.user_id
GROUP BY
    u.id, u.nickname, u.email
HAVING
    COUNT(a.id) > 0 -- Учитываем только пользователей с хотя бы одной попыткой
ORDER BY
    overall_average_score DESC
LIMIT 5;
```
