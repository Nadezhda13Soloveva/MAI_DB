
INSERT INTO users (nickname, email, hashed_password)
SELECT 
    'user_' || i,
    'user_' || i || '@example.com',
    '$2b$10$' || substr(md5(random()::text), 1, 22)
FROM generate_series(1, 200) AS i;


INSERT INTO languages (name) VALUES
('English'),
('Spanish'),
('French'),
('German'),
('Italian'),
('Chinese'),
('Japanese'),
('Russian'),
('Portuguese'),
('Arabic');


INSERT INTO user_languages (user_id, language_id)
SELECT DISTINCT
    (random() * 199 + 1)::int,
    (random() * 9 + 1)::int
FROM generate_series(1, 500);


INSERT INTO collections (language_id, creator_id, name)
SELECT 
    (random() * 9 + 1)::int,
    (random() * 199 + 1)::int,
    'Collection ' || i
FROM generate_series(1, 300) AS i;


WITH word_templates AS (
    SELECT 1 as lang_id, 'Hello' as original, 'Привет' as translation, '/həˈloʊ/' as transcription UNION
    SELECT 1, 'World', 'Мир', '/wɜːrld/' UNION
    SELECT 1, 'Apple', 'Яблоко', '/ˈæpl/' UNION
    SELECT 1, 'Water', 'Вода', '/ˈwɔːtər/' UNION
    SELECT 1, 'Fire', 'Огонь', '/ˈfaɪər/' UNION
    SELECT 1, 'Love', 'Любовь', '/lʌv/' UNION
    SELECT 1, 'Peace', 'Мир', '/piːs/' UNION
    SELECT 1, 'Friend', 'Друг', '/frend/' UNION
    SELECT 1, 'Time', 'Время', '/taɪm/' UNION
    SELECT 1, 'Home', 'Дом', '/hoʊm/' UNION
    
    SELECT 2, 'Hola', 'Привет', '/ˈo.la/' UNION
    SELECT 2, 'Gracias', 'Спасибо', '/ˈɡra.θjas/' UNION
    SELECT 2, 'Agua', 'Вода', '/ˈa.ɣwa/' UNION
    SELECT 2, 'Amigo', 'Друг', '/aˈmi.ɣo/' UNION
    
    SELECT 3, 'Bonjour', 'Привет', '/bɔ̃ʒuʁ/' UNION
    SELECT 3, 'Merci', 'Спасибо', '/mɛʁsi/' UNION
    SELECT 3, 'Eau', 'Вода', '/o/' UNION
    SELECT 3, 'Ami', 'Друг', '/a.mi/' UNION
    
    SELECT 4, 'Hallo', 'Привет', '/ˈhaloː/' UNION
    SELECT 4, 'Wasser', 'Вода', '/ˈvasɐ/' UNION
    SELECT 4, 'Freund', 'Друг', '/fʁɔʏ̯nt/' UNION
    
    SELECT 5, 'Ciao', 'Привет', '/ˈtʃa.o/' UNION
    SELECT 5, 'Acqua', 'Вода', '/ˈak.kwa/' UNION
    
    SELECT 6, '你好', 'Привет', '/nǐ xɤ/' UNION
    SELECT 6, '水', 'Вода', '/ʂwèi/' UNION
    
    SELECT 7, 'こんにちは', 'Привет', '/konnichiwa/' UNION
    SELECT 7, '水', 'Вода', '/mizu/' UNION
    
    SELECT 8, 'Привет', 'Hello', '/prʲɪˈvʲet/' UNION
    SELECT 8, 'Вода', 'Water', '/vɐˈda/' UNION
    
    SELECT 9, 'Olá', 'Привет', '/oˈla/' UNION
    SELECT 9, 'Água', 'Вода', '/ˈa.ɡwɐ/' UNION
    
    SELECT 10, 'مرحبا', 'Привет', '/marħaba/' UNION
    SELECT 10, 'ماء', 'Вода', '/maːʔ/'
)
INSERT INTO words (language_id, word_text, translation, transcription)
SELECT 
    wt.lang_id,
    wt.original,
    wt.translation,
    wt.transcription
FROM word_templates wt
CROSS JOIN generate_series(1, 100) AS multiplier
LIMIT 1000;


INSERT INTO exercise_types (name) VALUES
('Flashcards'),
('Test'),
('Quiz'),
('Typing'),
('Listening'),
('Speaking'),
('Writing'),
('Grammar'),
('Vocabulary');


INSERT INTO exercises (exercise_type_id, exercise_name, difficulty_level)
SELECT 
    (random() * 8 + 1)::int,
    'Exercise ' || i,
    CASE (random() * 2)::int
        WHEN 0 THEN 'Beginner'
        WHEN 1 THEN 'Intermediate'
        ELSE 'Advanced'
    END
FROM generate_series(1, 200) AS i;


INSERT INTO exercise_words (exercise_id, word_id)
SELECT DISTINCT
    (random() * 199 + 1)::int,
    (random() * 999 + 1)::int
FROM generate_series(1, 1500);


INSERT INTO collection_words (collection_id, word_id)
SELECT DISTINCT
    (random() * 299 + 1)::int,
    (random() * 999 + 1)::int
FROM generate_series(1, 2000);


INSERT INTO attempts (user_id, exercise_id, started_at, completed_at, score)
SELECT 
    (random() * 199 + 1)::int,
    (random() * 199 + 1)::int,
    NOW() - (random() * 30)::int * INTERVAL '1 day' - (random() * 86400)::int * INTERVAL '1 second',
    NOW() - (random() * 30)::int * INTERVAL '1 day' - (random() * 86400)::int * INTERVAL '1 second' + (random() * 1800 + 300)::int * INTERVAL '1 second',
    (random() * 40 + 60)::int
FROM generate_series(1, 1000);

