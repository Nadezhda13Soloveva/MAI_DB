-- Сначала все EXPLAIN ANALYZE запросы без индексов

-- Таблица `users`
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user1@example.com';
EXPLAIN ANALYZE
SELECT * FROM users WHERE nickname LIKE 'user%' ORDER BY nickname;

-- Таблица `collections`
EXPLAIN ANALYZE
SELECT * FROM collections WHERE creator_id = 1;
EXPLAIN ANALYZE
SELECT * FROM collections WHERE language_id = 1 AND creator_id = 1;
EXPLAIN ANALYZE
SELECT * FROM collections WHERE name LIKE 'English%';
EXPLAIN ANALYZE
SELECT * FROM collections WHERE id BETWEEN 1 AND 3;

-- Таблица `words`
EXPLAIN ANALYZE
SELECT * FROM words WHERE language_id = 1;
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text LIKE 'H%' ORDER BY word_text;
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text = 'Hello' AND translation = 'Привет';

-- Таблица `exercise_types`
EXPLAIN ANALYZE
SELECT * FROM exercise_types WHERE name = 'Flashcards';

-- Таблица `exercises`
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE exercise_type_id = 1;
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE difficulty_level = 'Beginner' ORDER BY exercise_name;

-- Таблица `attempts`
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE user_id = 1;
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE exercise_id = 1;
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE started_at BETWEEN '2023-10-26 00:00:00' AND '2023-10-26 23:59:59';

-- Запрос 1: Поиск коллекций пользователя с определенным языком и количеством слов
EXPLAIN ANALYZE
SELECT
    u.nickname,
    c.name AS collection_name,
    l.name AS language_name,
    COUNT(cw.word_id) AS word_count
FROM
    users u
JOIN
    collections c ON u.id = c.creator_id
JOIN
    languages l ON c.language_id = l.id
LEFT JOIN
    collection_words cw ON c.id = cw.collection_id
WHERE
    u.nickname = 'user1' AND l.name = 'English'
GROUP BY
    u.nickname, c.name, l.name
HAVING
    COUNT(cw.word_id) > 2;

-- Запрос 2: Список упражнений с общим количеством слов и средней оценкой попыток
EXPLAIN ANALYZE
SELECT
    e.exercise_name,
    et.name AS exercise_type,
    COUNT(ew.word_id) AS total_words,
    AVG(a.score) AS average_score
FROM
    exercises e
JOIN
    exercise_types et ON e.exercise_type_id = et.id
LEFT JOIN
    exercise_words ew ON e.id = ew.exercise_id
LEFT JOIN
    attempts a ON e.id = a.exercise_id
GROUP BY
    e.exercise_name, et.name
ORDER BY
    average_score DESC NULLS LAST;


-- Теперь все CREATE INDEX
-- Таблица `users`
CREATE INDEX idx_users_email_btree ON users USING btree(email);
CREATE INDEX idx_users_nickname_btree ON users USING btree(nickname varchar_pattern_ops);
CREATE INDEX idx_users_id_email_include ON users(id) INCLUDE (email, nickname);

-- Таблица `collections`
CREATE INDEX idx_collections_creator_btree ON collections USING btree(creator_id);
CREATE INDEX idx_collections_language_creator ON collections USING btree(language_id, creator_id);
CREATE INDEX idx_collections_name_btree ON collections USING btree(name text_pattern_ops);
CREATE INDEX idx_collections_id_btree ON collections USING btree(id);

-- Таблица `words`
CREATE INDEX idx_words_language_btree ON words USING btree(language_id);
CREATE INDEX idx_words_wordtext_btree ON words USING btree(word_text text_pattern_ops);
CREATE INDEX idx_words_wordtext_translation ON words USING btree(word_text, translation);

-- Таблица `exercise_types`
CREATE UNIQUE INDEX idx_exercise_types_name_btree ON exercise_types USING btree(name);

-- Таблица `exercises`
CREATE INDEX idx_exercises_exercisetype_btree ON exercises USING btree(exercise_type_id);
CREATE INDEX idx_exercises_difficulty_btree ON exercises USING btree(difficulty_level);

-- Таблица `attempts`
CREATE INDEX idx_attempts_user_btree ON attempts USING btree(user_id);
CREATE INDEX idx_attempts_exercise_btree ON attempts USING btree(exercise_id);
CREATE INDEX idx_attempts_startedat_brin ON attempts USING brin(started_at);


-- 4.1 Теперь все EXPLAIN ANALYZE запросы с индексами
-- Таблица `users`
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user1@example.com';
EXPLAIN ANALYZE
SELECT * FROM users WHERE nickname LIKE 'user%' ORDER BY nickname;

-- Таблица `collections`
EXPLAIN ANALYZE
SELECT * FROM collections WHERE creator_id = 1;
EXPLAIN ANALYZE
SELECT * FROM collections WHERE language_id = 1 AND creator_id = 1;
EXPLAIN ANALYZE
SELECT * FROM collections WHERE name LIKE 'English%';
EXPLAIN ANALYZE
SELECT * FROM collections WHERE id BETWEEN 1 AND 3;

-- Таблица `words`
EXPLAIN ANALYZE
SELECT * FROM words WHERE language_id = 1;
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text LIKE 'H%' ORDER BY word_text;
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text = 'Hello' AND translation = 'Привет';

-- Таблица `exercise_types`
EXPLAIN ANALYZE
SELECT * FROM exercise_types WHERE name = 'Flashcards';

-- Таблица `exercises`
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE exercise_type_id = 1;
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE difficulty_level = 'Beginner' ORDER BY exercise_name;

-- Таблица `attempts`
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE user_id = 1;
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE exercise_id = 1;
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE started_at BETWEEN '2023-10-26 00:00:00' AND '2023-10-26 23:59:59';

-- 4.2. Анализ производительности с EXPLAIN (Запросы с индексами)
-- Запрос 1: Поиск коллекций пользователя с определенным языком и количеством слов
EXPLAIN ANALYZE
SELECT
    u.nickname,
    c.name AS collection_name,
    l.name AS language_name,
    COUNT(cw.word_id) AS word_count
FROM
    users u
JOIN
    collections c ON u.id = c.creator_id
JOIN
    languages l ON c.language_id = l.id
LEFT JOIN
    collection_words cw ON c.id = cw.collection_id
WHERE
    u.nickname = 'user1' AND l.name = 'English'
GROUP BY
    u.nickname, c.name, l.name
HAVING
    COUNT(cw.word_id) > 2;

-- Запрос 2: Список упражнений с общим количеством слов и средней оценкой попыток
EXPLAIN ANALYZE
SELECT
    e.exercise_name,
    et.name AS exercise_type,
    COUNT(ew.word_id) AS total_words,
    AVG(a.score) AS average_score
FROM
    exercises e
JOIN
    exercise_types et ON e.exercise_type_id = et.id
LEFT JOIN
    exercise_words ew ON e.id = ew.exercise_id
LEFT JOIN
    attempts a ON e.id = a.exercise_id
GROUP BY
    e.exercise_name, et.name
ORDER BY
    average_score DESC NULLS LAST;


-- 4.3. Транзакции и аномалии параллельного доступа

-- Dirty Read (Грязное чтение)
-- Транзакция T1 (READ COMMITTED)
BEGIN;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает изменения)
SELECT nickname FROM users WHERE id = 1;
COMMIT;

-- Транзакция T2
BEGIN;
UPDATE users SET nickname = 'DirtyUser' WHERE id = 1;
-- (Пауза, чтобы T1 успела прочитать до коммита)
ROLLBACK;

-- Non-repeatable Read (Неповторяющееся чтение)
-- Транзакция T1 (READ COMMITTED)
BEGIN;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1;
COMMIT;

-- Транзакция T2
BEGIN;
UPDATE users SET nickname = 'UpdatedUser' WHERE id = 1;
COMMIT;

-- Транзакция T1 (REPEATABLE READ)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1;
COMMIT;

-- Phantom Read (Фантомное чтение)
-- Транзакция T1 (REPEATABLE READ)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM words WHERE language_id = 4;
-- (Пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 4;
COMMIT;

-- Транзакция T2
BEGIN;
INSERT INTO words (language_id, word_text, translation) VALUES (4, 'NewWord', 'НовоеСлово');
COMMIT;

-- Транзакция T1 (SERIALIZABLE)
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM words WHERE language_id = 4;
-- (Пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 4;
COMMIT;
