-- 1. Представление 'user_language_progress': Показывает прогресс пользователей по языкам
CREATE VIEW user_language_progress AS
SELECT
    u.id AS user_id,
    u.nickname,
    l.name AS language_name,
    COUNT(DISTINCT a.exercise_id) AS completed_exercises,
    AVG(a.score) AS average_score,
    MAX(a.completed_at) AS last_attempt_date
FROM
    users u
JOIN
    user_languages ul ON u.id = ul.user_id
JOIN
    languages l ON ul.language_id = l.id
LEFT JOIN
    collections c ON l.id = c.language_id
LEFT JOIN
    words w ON c.language_id = w.language_id
LEFT JOIN
    exercise_words ew ON w.id = ew.word_id
LEFT JOIN
    exercises e ON ew.exercise_id = e.id
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
    AVG(a.score) AS overall_average_score,
    COUNT(a.user_id) AS total_attempts,
    MAX(a.completed_at) AS last_activity
FROM
    users u
JOIN
    attempts a ON u.id = a.user_id
GROUP BY
    u.id, u.nickname, u.email
HAVING
    COUNT(a.user_id) > 0 -- Учитываем только пользователей с хотя бы одной попыткой
ORDER BY
    overall_average_score DESC
LIMIT 5;