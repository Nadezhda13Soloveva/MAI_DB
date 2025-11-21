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

-- 3. Получить упражнения, их типы и слова, которые в них используются, для определенного языка (например, English)
SELECT
    e.exercise_name,
    et.name AS exercise_type,
    e.difficulty_level,
    w.word_text,
    w.translation
FROM
    exercises e
JOIN
    exercise_types et ON e.exercise_type_id = et.id
JOIN
    exercise_words ew ON e.id = ew.exercise_id
JOIN
    words w ON ew.word_id = w.id
JOIN
    collections c ON w.language_id = c.language_id -- предполагаем, что язык упражнения соответствует языку слова в коллекции
JOIN
    languages l ON c.language_id = l.id
WHERE
    l.name = 'English';

-- 4. Получить все попытки пользователей, включая их никнеймы, названия упражнений и результаты
SELECT
    u.nickname,
    e.exercise_name,
    a.started_at,
    a.completed_at,
    a.score
FROM
    attempts a
JOIN
    users u ON a.user_id = u.id
JOIN
    exercises e ON a.exercise_id = e.id
ORDER BY
    u.nickname, a.started_at;