-- Простые запросы
-- 1. поиск пользователя по никнейму
EXPLAIN ANALYZE
SELECT * FROM users WHERE nickname = 'user_100';

-- 2. поиск слов по language_id
EXPLAIN ANALYZE
SELECT * FROM words WHERE language_id = 5;

-- 3. получение всех коллекций, созданных пользователем с id = 50
EXPLAIN ANALYZE
SELECT * FROM collections WHERE creator_id = 50;

-- 4. получение попыток, сделанных пользователем с id = 75, с сортировкой по дате начала
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE user_id = 75 ORDER BY started_at DESC;

-- 5. поиск упражнений по уровню сложности
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE difficulty_level = 'Intermediate';


-- Сложные запросы
-- 1. получить все слова из коллекций, созданных пользователями, изучающими англ, отсортировать по названию коллекции и слову
EXPLAIN ANALYZE
SELECT
    c.name AS collection_name,
    w.word_text,
    w.translation
FROM
    users u
JOIN
    user_languages ul ON u.id = ul.user_id
JOIN
    languages l ON ul.language_id = l.id
JOIN
    collections c ON l.id = c.language_id AND u.id = c.creator_id
JOIN
    collection_words cw ON c.id = cw.collection_id
JOIN
    words w ON cw.word_id = w.id
WHERE
    l.name = 'English'
ORDER BY
    c.name, w.word_text;

-- 2. получить средний балл за попытки по каждому упражнению для пользователей, которые набрали >80 б в любой из попыток
EXPLAIN ANALYZE
SELECT
    e.exercise_name,
    AVG(a.score) AS average_score
FROM
    attempts a
JOIN
    exercises e ON a.exercise_id = e.id
WHERE
    a.user_id IN (SELECT user_id FROM attempts WHERE score > 80)
GROUP BY
    e.exercise_name
ORDER BY
    average_score DESC;



-- Сценарии транзакций и аномалий параллельного доступа
-- 4.3.1. Dirty Read (Грязное чтение)
-- Сессия 1 (T1)
BEGIN;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает изменения)
SELECT nickname FROM users WHERE id = 1;
COMMIT;

-- Сессия 2 (T2)
BEGIN;
UPDATE users SET nickname = 'DirtyUser' WHERE id = 1;
-- Ожидаем, что T1 прочитает до коммита T2
ROLLBACK;


-- 4.3.2. Non-repeatable Read (Неповторяющееся чтение)
-- Сессия 1 (T1, уровень изоляции READ COMMITTED)
BEGIN;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает и коммитит изменения) 
SELECT nickname FROM users WHERE id = 1;
COMMIT;

-- Сессия 2 (T2)
BEGIN;
UPDATE users SET nickname = 'UpdatedUser' WHERE id = 1;
COMMIT;

-- Сессия 1 (T1, уровень изоляции REPEATABLE READ)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT nickname FROM users WHERE id = 1;
-- (Пауза, пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1;
COMMIT;


-- 4.3.3. Phantom Read (Фантомное чтение)
-- Сессия 1 (T1, уровень изоляции REPEATABLE READ)
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM words WHERE language_id = 11;
-- (Пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 11;
COMMIT;

-- Сессия 2 (T2)
BEGIN;
INSERT INTO words (language_id, word_text, translation) VALUES (4, 'NewWord', 'НовоеСлово');
COMMIT;


-- Сессия 1 (T1, уровень изоляции SERIALIZABLE)
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM words WHERE language_id = 11;
-- (Пауза, пока T2 добавляет новую строку)

SELECT COUNT(*) FROM words WHERE language_id = 11;
COMMIT;

