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
    