-- INSERT
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

-- UPDATE
-- Обновить никнейм пользователя с ID = 1
UPDATE users
SET nickname = 'NewUser1'
WHERE id = 1;

-- Обновить результат попытки для пользователя 1, упражнения 1, начатой в 2023-10-26 10:00:00
UPDATE attempts
SET score = 92,
    completed_at = '2023-10-26 10:11:00'
WHERE user_id = 1 AND exercise_id = 1 AND started_at = '2023-10-26 10:00:00';

-- Изменить уровень сложности упражнения 'Basic English Words' на 'Intermediate'
UPDATE exercises
SET difficulty_level = 'Intermediate'
WHERE exercise_name = 'Basic English Words';

-- DELETE
-- Удалить пользователя с ID = 2
DELETE FROM users
WHERE id = 2;

-- Удалить слово 'Apple'
DELETE FROM words
WHERE word_text = 'Apple';

-- Удалить все попытки пользователя 5
DELETE FROM attempts
WHERE user_id = 5;