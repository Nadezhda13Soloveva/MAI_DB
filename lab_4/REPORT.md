
# Лабораторная работа №4: Индексы, анализ производительности, транзакции и аномалии параллельного доступа

## 1. Цель работы

Освоение методов создания и использования различных типов индексов в PostgreSQL для оптимизации производительности запросов, анализ планов выполнения с помощью EXPLAIN, изучение механизмов партиционирования таблиц, а также исследование транзакций и аномалий параллельного доступа.

## 2. Задачи работы

1. **Индексы**
    *   Создать индексы на атрибуты, которые могут использоваться для поиска, фильтрации, группировки и сортировки. Для каждого типа данных и операции выбрать наиболее подходящий индекс.
    *   Для каждого индекса:
        *   Выполнить заранее подготовленный запрос без индекса и зафиксировать план выполнения и время (EXPLAIN ANALYZE).
        *   Создать индекс и повторно выполнить тот же запрос.
    *   Примеры запросов:
        *   Поиск записей по диапазону значений.
        *   Фильтрация и сортировка по текстовым полям.
        *   Поиск записей по подстроке с использованием LIKE.

2. **Анализ производительности с EXPLAIN**
    *   Подготовить несколько запросов средней и высокой сложности (с фильтрацией, JOIN, сортировкой и агрегацией).
    *   Для каждого запроса:
        *   Выполнить его до создания индексов и проанализировать план (Seq Scan, Hash Join и т.д.).
        *   Выполнить его после создания индексов и сравнить изменения (Index Scan, Bitmap Index Scan, Nested Loop и др.).
        *   Сделать вывод о том, как индексы влияют на выбор стратегии выполнения запроса и его время работы.

3. **Транзакции и аномалии параллельного доступа**
    *   Реализовать не менее трёх сценариев, демонстрирующих различные виды аномалий при параллельной работе транзакций:
        *   Dirty read.
        *   Non-repeatable read – показать, как повторный запрос в одной транзакции возвращает разные результаты.
        *   Phantom read – показать, как появляются новые строки при повторном выполнении запроса.
    *   Для каждого сценария:
        *   Описать пошагово действия двух параллельных транзакций (Т1 и Т2).
        *   Объяснить, какая аномалия возникает и почему.
        *   Затем показать, как избавиться от аномалии.
    *   Продемонстрировать работу уровней изоляции.

Лабораторная работа выполняется на основе структуры базы данных Vocabulary Trainer, разработанной в предыдущих лабораторных работах.

### Вариант 19: Приложение для изучения языков (Vocabulary Trainer)

**Описание:** Пользователи создают коллекции слов и фраз для изучения (словари). Система предоставляет упражнения для запоминания (карточки, тесты) и отслеживает прогресс изучения каждого слова.

## 3. Теоретические сведения

### 3.1. Типы индексов в PostgreSQL
| Тип | Назначение | Оптимален для | Особенности |
|-|-|-|-|
| B-tree (Balanced Tree) индекс|Универсальный индекс для равенства (=), диапазонов (BETWEEN, >, <), сортировки (ORDER BY)| Числовых, текстовых полей, дат| Поддерживает уникальность, эффективен для префиксного поиска|
|Hash индекс| Только для операций равенства (=)| Точного совпадения, когда не нужны диапазоны| уступает B-tree в большинстве случаев|
|GIN (Generalized Inverted Index)| Составные значения - массивы, JSONB, полнотекстовый поиск|Операторов @>, <@, && для массивов|Хорош для "содержит" операций|
|GiST (Generalized Search Tree)| Геометрические данные, диапазоны, поиск ближайших соседей|&& (пересечение), @> (содержит), <-> (расстояние)|Может работать медленнее GIN для некоторых операций|
|BRIN (Block Range Index)|Большие таблицы с естественной сортировкой|Хронологических данных, где значения коррелируют с физическим расположением|Очень компактный, но менее точен|

### 3.2. Типы сканирования
* **Seq Scan (Sequential Scan)** — последовательное чтение всей таблицы.

* **Index Scan** — использование индекса для поиска строк с последующим обращением к таблице.

* **Index Only Scan** — чтение данных только из индекса без обращения к таблице.

* **Bitmap Index Scan** — создание битовой карты страниц, содержащих нужные строки, с последующим эффективным чтением.

### 3.3. Транзакции и уровни изоляции
Уровни изоляции в PostgreSQL:

* **READ UNCOMMITTED** — в PostgreSQL эквивалентен READ COMMITTED

* **READ COMMITTED** — по умолчанию, предотвращает Dirty Read

* **REPEATABLE READ** — предотвращает Dirty Read и Non-repeatable Read

* **SERIALIZABLE** — предотвращает все аномалии, включая Phantom Read

### 3.4. Аномалии параллельного доступа

При параллельном выполнении транзакций могут возникать различные аномалии, если не используются адекватные уровни изоляции. Основные аномалии включают:

* **Dirty Read (Грязное чтение):** Транзакция Т1 читает данные, измененные транзакцией Т2, но еще не закоммиченные. Если Т2 откатится, Т1 прочитает "грязные" (несуществующие) данные. В PostgreSQL на уровне `READ COMMITTED` (по умолчанию) и выше эта аномалия предотвращается.

* **Non-repeatable Read (Неповторяющееся чтение):** В рамках одной транзакции (Т1) один и тот же запрос, выполненный дважды, возвращает разные результаты. Это происходит потому, что другая транзакция (Т2) закоммитила изменения (UPDATE или DELETE существующих строк), затронувшие прочитанные Т1 данные, между двумя чтениями Т1. Уровень изоляции `REPEATABLE READ` предотвращает эту аномалию.

* **Phantom Read (Фантомное чтение):** В рамках одной транзакции (Т1) запрос, выбирающий набор строк по определенному условию, выполненный дважды, возвращает разное количество строк. Это происходит потому, что другая транзакция (Т2) закоммитила добавление или удаление строк, удовлетворяющих условию запроса Т1, между двумя чтениями Т1. В PostgreSQL уровень изоляции `REPEATABLE READ` предотвращает *некоторые* виды фантомных чтений (например, для запросов с условием равенства), но для *полной* гарантии отсутствия фантомов во всех сложных сценариях (например, с более сложными условиями или агрегациями) необходим уровень изоляции `SERIALIZABLE`, который предотвращает эту аномалию, гарантируя, что все параллельно выполняющиеся сериализуемые транзакции производят тот же результат, что и последовательное их выполнение.

## 4. Решение

### 4.1. Создание и тестирование индексов
#### 4.1.1. Таблица `users`
```
-- 1. B-tree индекс для email (уникальные значения, точный поиск)
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user1@example.com';
-- Index Scan using users_email_key on users  (cost=0.14..8.16 rows=1 width=1552) (actual time=0.084..0.085 rows=1 loops=1)
--   Index Cond: ((email)::text = 'user1@example.com'::text)
-- Planning Time: 3.672 ms
-- Execution Time: 0.889 ms

CREATE INDEX idx_users_email_btree ON users USING btree(email);

EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user1@example.com';
Seq Scan on users  (cost=0.00..1.05 rows=1 width=1552) (actual time=0.047..0.049 rows=1 loops=1)
  Filter: ((email)::text = 'user1@example.com'::text)
  Rows Removed by Filter: 3
Planning Time: 3.502 ms
Execution Time: 0.068 ms

-- 2. B-tree индекс для nickname (поиск по префиксу, сортировка)
-- Обоснование: nickname используется для поиска пользователей и сортировки списков
CREATE INDEX idx_users_nickname_btree ON users USING btree(nickname varchar_pattern_ops);

EXPLAIN ANALYZE
SELECT * FROM users WHERE nickname LIKE 'user%' ORDER BY nickname;
-- Sort  (cost=10.63..10.64 rows=1 width=1552) (actual time=0.253..0.255 rows=4 loops=1)
--   Sort Key: nickname
--   Sort Method: quicksort  Memory: 25kB
--   ->  Seq Scan on users  (cost=0.00..10.62 rows=1 width=1552) (actual time=0.078..0.080 rows=4 loops=1)
--         Filter: ((nickname)::text ~~ 'user%'::text)
-- Planning Time: 1.344 ms
-- Execution Time: 0.297 ms

EXPLAIN ANALYZE
SELECT * FROM users WHERE nickname LIKE 'user%' ORDER BY nickname;
Sort  (cost=1.06..1.06 rows=1 width=1552) (actual time=0.069..0.070 rows=4 loops=1)
  Sort Key: nickname
  Sort Method: quicksort  Memory: 25kB
  ->  Seq Scan on users  (cost=0.00..1.05 rows=1 width=1552) (actual time=0.040..0.042 rows=4 loops=1)
        Filter: ((nickname)::text ~~ 'user%'::text)
Planning Time: 1.753 ms
Execution Time: 0.378 ms

-- 3. Составной индекс для частых JOIN с фильтрацией
-- Обоснование: часто запрашиваются пользователи с определенным прогрессом
-- Важно: порядок столбцов в составном индексе (id, email) влияет на его эффективность. Здесь 'id' - для равенства, 'email' - для выборки. Если бы были другие условия, порядок мог бы быть иным.
CREATE INDEX idx_users_id_email_include ON users(id) INCLUDE (email, nickname);
```
#### 4.1.2 Таблица `collections`
```
-- 1. B-tree индекс для creator_id (внешний ключ, частые JOIN)
-- Обоснование: пользователь часто смотрит свои коллекции
EXPLAIN ANALYZE
SELECT * FROM collections WHERE creator_id = 1;
-- Seq Scan on collections  (cost=0.00..11.75 rows=1 width=528) (actual time=0.027..0.030 rows=2 loops=1)
--   Filter: (creator_id = 1)
--   Rows Removed by Filter: 2
-- Planning Time: 2.849 ms
-- Execution Time: 0.051 ms

CREATE INDEX idx_collections_creator_btree ON collections USING btree(creator_id);

EXPLAIN ANALYZE
SELECT * FROM collections WHERE creator_id = 1;
Seq Scan on collections  (cost=0.00..1.05 rows=1 width=528) (actual time=0.029..0.030 rows=2 loops=1)
  Filter: (creator_id = 1)
  Rows Removed by Filter: 2
Planning Time: 5.474 ms
Execution Time: 0.068 ms

-- 2. Составной индекс для запросов по языку и создателю
-- Обоснование: частый запрос "коллекции пользователя по языку"
-- Важно: порядок столбцов в составном индексе (language_id, creator_id) важен. Сначала по "language_id", затем по "creator_id" для эффективного использования индекса в запросах с условиями на оба поля.
EXPLAIN ANALYZE
SELECT * FROM collections WHERE language_id = 1 AND creator_id = 1;
-- Seq Scan on collections  (cost=0.00..12.10 rows=1 width=528) (actual time=0.029..0.031 rows=1 loops=1)
--   Filter: ((language_id = 1) AND (creator_id = 1))
--   Rows Removed by Filter: 3
-- Planning Time: 0.157 ms
-- Execution Time: 0.067 ms

CREATE INDEX idx_collections_language_creator ON collections USING btree(language_id, creator_id);

EXPLAIN ANALYZE
SELECT * FROM collections WHERE language_id = 1 AND creator_id = 1;
Seq Scan on collections  (cost=0.00..1.06 rows=1 width=528) (actual time=0.021..0.023 rows=1 loops=1)
  Filter: ((language_id = 1) AND (creator_id = 1))
  Rows Removed by Filter: 3
Planning Time: 0.192 ms
Execution Time: 0.045 ms

-- 3. B-tree индекс для имени с text_pattern_ops
-- Обоснование: поиск коллекций по имени
EXPLAIN ANALYZE
SELECT * FROM collections WHERE name LIKE 'English%';
-- Seq Scan on collections  (cost=0.00..11.75 rows=1 width=528) (actual time=0.032..0.034 rows=1 loops=1)
--   Filter: ((name)::text ~~ 'English%'::text)
--   Rows Removed by Filter: 3
-- Planning Time: 0.168 ms
-- Execution Time: 0.055 ms

CREATE INDEX idx_collections_name_btree ON collections USING btree(name text_pattern_ops);

EXPLAIN ANALYZE
SELECT * FROM collections WHERE name LIKE 'English%';
Seq Scan on collections  (cost=0.00..1.05 rows=1 width=528) (actual time=0.171..0.182 rows=1 loops=1)
  Filter: ((name)::text ~~ 'English%'::text)
  Rows Removed by Filter: 3
Planning Time: 0.166 ms
Execution Time: 0.204 ms

-- 4. B-tree индекс для id (для диапазонного поиска)
-- Обоснование: поиск коллекций по диапазону ID
EXPLAIN ANALYZE
SELECT * FROM collections WHERE id BETWEEN 1 AND 3;
-- Index Scan using collections_pkey on collections  (cost=0.14..8.16 rows=1 width=528) (actual time=0.010..0.014 rows=3 loops=1)
--   Index Cond: ((id >= 1) AND (id <= 3))
-- Planning Time: 0.114 ms
-- Execution Time: 0.029 ms

CREATE INDEX idx_collections_id_btree ON collections USING btree(id);

EXPLAIN ANALYZE
SELECT * FROM collections WHERE id BETWEEN 1 AND 3;
Seq Scan on collections  (cost=0.00..1.06 rows=1 width=528) (actual time=0.024..0.026 rows=3 loops=1)
  Filter: ((id >= 1) AND (id <= 3))
  Rows Removed by Filter: 1
Planning Time: 0.244 ms
Execution Time: 0.051 ms
```
#### 4.1.3 Таблица `words`
```
-- 1. B-tree индекс для language_id (внешний ключ, частые JOIN)
-- Обоснование: часто запрашиваются слова определенного языка
EXPLAIN ANALYZE
SELECT * FROM words WHERE language_id = 1;
-- Seq Scan on words  (cost=0.00..10.62 rows=1 width=1556) (actual time=0.026..0.028 rows=5 loops=1)
--   Filter: (language_id = 1)
--   Rows Removed by Filter: 4
-- Planning Time: 2.478 ms
-- Execution Time: 0.048 ms

CREATE INDEX idx_words_language_btree ON words USING btree(language_id);

EXPLAIN ANALYZE
SELECT * FROM words WHERE language_id = 1;
Seq Scan on words  (cost=0.00..1.11 rows=1 width=1556) (actual time=0.023..0.026 rows=5 loops=1)
  Filter: (language_id = 1)
  Rows Removed by Filter: 4
Planning Time: 5.287 ms
Execution Time: 0.048 ms

-- 2. B-tree индекс для word_text (поиск по префиксу, сортировка)
-- Обоснование: поиск слов по тексту
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text LIKE 'H%' ORDER BY word_text;
-- Sort  (cost=10.63..10.64 rows=1 width=1556) (actual time=0.079..0.081 rows=2 loops=1)
-- Sort Key: word_text
-- Sort Method: quicksort  Memory: 25kB
--   ->  Seq Scan on words  (cost=0.00..10.62 rows=1 width=1556) (actual time=0.024..0.028 rows=2 loops=1)
--         Filter: ((word_text)::text ~~ 'H%'::text)
--         Rows Removed by Filter: 7
-- Planning Time: 0.373 ms
-- Execution Time: 0.115 ms

CREATE INDEX idx_words_wordtext_btree ON words USING btree(word_text text_pattern_ops);

EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text LIKE 'H%' ORDER BY word_text;
Sort  (cost=1.12..1.13 rows=1 width=1556) (actual time=0.066..0.067 rows=2 loops=1)
  Sort Key: word_text
  Sort Method: quicksort  Memory: 25kB
  ->  Seq Scan on words  (cost=0.00..1.11 rows=1 width=1556) (actual time=0.021..0.025 rows=2 loops=1)
        Filter: ((word_text)::text ~~ 'H%'::text)
        Rows Removed by Filter: 7
Planning Time: 0.182 ms
Execution Time: 0.091 ms

-- 3. Составной индекс для поиска по слову и переводу
-- Обоснование: часто ищутся слова с их переводом
-- Важно: порядок столбцов в составном индексе (word_text, translation) важен для эффективности запросов, использующих оба поля.
EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text = 'Hello' AND translation = 'Привет';
-- Seq Scan on words  (cost=0.00..10.75 rows=1 width=1556) (actual time=0.020..0.023 rows=1 loops=1)
--   Filter: (((word_text)::text = 'Hello'::text) AND ((translation)::text = 'Привет'::text))
--   Rows Removed by Filter: 8
-- Planning Time: 0.091 ms
-- Execution Time: 0.039 ms

CREATE INDEX idx_words_wordtext_translation ON words USING btree(word_text, translation);

EXPLAIN ANALYZE
SELECT * FROM words WHERE word_text = 'Hello' AND translation = 'Привет';
Seq Scan on words  (cost=0.00..1.14 rows=1 width=1556) (actual time=0.077..0.083 rows=1 loops=1)
  Filter: (((word_text)::text = 'Hello'::text) AND ((translation)::text = 'Привет'::text))
  Rows Removed by Filter: 8
Planning Time: 0.166 ms
Execution Time: 0.109 ms
```
#### 4.1.4 Таблица `exercise_types`
```
-- 1. B-tree индекс для name (UNIQUE, точный поиск)
-- Обоснование: часто ищутся типы упражнений по имени
EXPLAIN ANALYZE
SELECT * FROM exercise_types WHERE name = 'Flashcards';
-- Index Scan using exercise_types_name_key on exercise_types  (cost=0.15..8.17 rows=1 width=222) (actual time=0.043..0.044 rows=1 loops=1)
--   Index Cond: ((name)::text = 'Flashcards'::text)
-- Planning Time: 4.286 ms
-- Execution Time: 0.069 ms

CREATE UNIQUE INDEX idx_exercise_types_name_btree ON exercise_types USING btree(name);

EXPLAIN ANALYZE
SELECT * FROM exercise_types WHERE name = 'Flashcards';
Seq Scan on exercise_types  (cost=0.00..1.05 rows=1 width=222) (actual time=0.019..0.021 rows=1 loops=1)
  Filter: ((name)::text = 'Flashcards'::text)
  Rows Removed by Filter: 3
Planning Time: 2.375 ms
Execution Time: 0.039 ms
```
#### 4.1.5 Таблица `exercises`
```
-- 1. B-tree индекс для exercise_type_id (внешний ключ, частые JOIN)
-- Обоснование: часто ищутся упражнения по типу
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE exercise_type_id = 1;
Seq Scan on exercises  (cost=0.00..10.88 rows=1 width=1040) (actual time=0.014..0.015 rows=2 loops=1)
  Filter: (exercise_type_id = 1)
  Rows Removed by Filter: 2
Planning Time: 1.703 ms
Execution Time: 0.028 ms

CREATE INDEX idx_exercises_exercisetype_btree ON exercises USING btree(exercise_type_id);

EXPLAIN ANALYZE
SELECT * FROM exercises WHERE exercise_type_id = 1;
Seq Scan on exercises  (cost=0.00..1.05 rows=1 width=1040) (actual time=0.020..0.022 rows=2 loops=1)
  Filter: (exercise_type_id = 1)
  Rows Removed by Filter: 2
Planning Time: 3.322 ms
Execution Time: 0.041 ms

-- 2. B-tree индекс для difficulty_level (фильтрация, сортировка)
-- Обоснование: часто фильтруются упражнения по уровню сложности
EXPLAIN ANALYZE
SELECT * FROM exercises WHERE difficulty_level = 'Beginner' ORDER BY exercise_name;
Sort  (cost=10.88..10.89 rows=1 width=1040) (actual time=0.049..0.050 rows=2 loops=1)
  Sort Key: exercise_name
  Sort Method: quicksort  Memory: 25kB
  ->  Seq Scan on exercises  (cost=0.00..10.88 rows=1 width=1040) (actual time=0.022..0.024 rows=2 loops=1)
        Filter: ((difficulty_level)::text = 'Beginner'::text)
        Rows Removed by Filter: 2
Planning Time: 0.230 ms
Execution Time: 0.091 ms

CREATE INDEX idx_exercises_difficulty_btree ON exercises USING btree(difficulty_level);

EXPLAIN ANALYZE
SELECT * FROM exercises WHERE difficulty_level = 'Beginner' ORDER BY exercise_name;
Sort  (cost=1.06..1.06 rows=1 width=1040) (actual time=0.046..0.047 rows=2 loops=1)
  Sort Key: exercise_name
  Sort Method: quicksort  Memory: 25kB
  ->  Seq Scan on exercises  (cost=0.00..1.05 rows=1 width=1040) (actual time=0.020..0.022 rows=2 loops=1)
        Filter: ((difficulty_level)::text = 'Beginner'::text)
        Rows Removed by Filter: 2
Planning Time: 0.146 ms
Execution Time: 0.071 ms
```

#### 4.1.6 Таблица `attempts`
```
-- 1. B-tree индекс для user_id (внешний ключ, частые JOIN, фильтрация)
-- Обоснование: часто ищутся попытки определенного пользователя
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE user_id = 1;
Seq Scan on attempts  (cost=0.00..27.00 rows=7 width=32) (actual time=0.027..0.029 rows=3 loops=1)
  Filter: (user_id = 1)
  Rows Removed by Filter: 2
Planning Time: 1.664 ms
Execution Time: 0.051 ms

CREATE INDEX idx_attempts_user_btree ON attempts USING btree(user_id);

EXPLAIN ANALYZE
SELECT * FROM attempts WHERE user_id = 1;
Seq Scan on attempts  (cost=0.00..1.06 rows=1 width=32) (actual time=0.012..0.013 rows=3 loops=1)
  Filter: (user_id = 1)
  Rows Removed by Filter: 2
Planning Time: 1.552 ms
Execution Time: 0.032 ms

-- 2. B-tree индекс для exercise_id (внешний ключ, частые JOIN, фильтрация)
-- Обоснование: часто ищутся попытки для определенного упражнения
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE exercise_id = 1;
Seq Scan on attempts  (cost=0.00..27.00 rows=7 width=32) (actual time=0.022..0.024 rows=3 loops=1)
  Filter: (exercise_id = 1)
  Rows Removed by Filter: 2
Planning Time: 0.119 ms
Execution Time: 0.044 ms

CREATE INDEX idx_attempts_exercise_btree ON attempts USING btree(exercise_id);

EXPLAIN ANALYZE
SELECT * FROM attempts WHERE exercise_id = 1;
Seq Scan on attempts  (cost=0.00..1.06 rows=1 width=32) (actual time=0.036..0.039 rows=3 loops=1)
  Filter: (exercise_id = 1)
  Rows Removed by Filter: 2
Planning Time: 0.220 ms
Execution Time: 0.062 ms

-- 3. BRIN индекс для started_at (диапазон, большие таблицы с хронологическими данными)
-- Обоснование: поиск попыток в определенном временном диапазоне, таблица attempts может быть очень большой.
-- Важно: BRIN индексы наиболее эффективны для очень больших таблиц, где данные логически отсортированы по индексируемому столбцу. Для небольших таблиц (как у меня) BRIN может быть менее эффективен, чем B-tree из-за меньшей точности.
EXPLAIN ANALYZE
SELECT * FROM attempts WHERE started_at BETWEEN '2023-10-26 00:00:00' AND '2023-10-26 23:59:59';
Seq Scan on attempts  (cost=0.00..30.40 rows=7 width=32) (actual time=0.016..0.017 rows=3 loops=1)
  Filter: ((started_at >= '2023-10-26 00:00:00'::timestamp without time zone) AND (started_at <= '2023-10-26 23:59:59'::timestamp without time zone))
  Rows Removed by Filter: 2
Planning Time: 0.122 ms
Execution Time: 0.036 ms

CREATE INDEX idx_attempts_startedat_brin ON attempts USING brin(started_at);

EXPLAIN ANALYZE
SELECT * FROM attempts WHERE started_at BETWEEN '2023-10-26 00:00:00' AND '2023-10-26 23:59:59';
Seq Scan on attempts  (cost=0.00..1.07 rows=1 width=32) (actual time=0.015..0.016 rows=3 loops=1)
  Filter: ((started_at >= '2023-10-26 00:00:00'::timestamp without time zone) AND (started_at <= '2023-10-26 23:59:59'::timestamp without time zone))
  Rows Removed by Filter: 2
Planning Time: 0.202 ms
Execution Time: 0.040 ms
```
### 4.2. Анализ производительности с EXPLAIN

#### 4.2.1. Запрос 1: Поиск коллекций пользователя с определенным языком и количеством слов
Описание: Запрос выбирает коллекции пользователя (user1), которые имеют язык English и содержат более 2 слов.
Ожидаемый эффект: без индексов - Seq Scan и Hash Join; с индексами - Index Scan, Nested Loop (или Bitmap Index Scan).
```
-- Запрос без индексов
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
HashAggregate  (cost=21.70..21.90 rows=5 width=1556) (actual time=0.371..0.373 rows=1 loops=1)
  Group Key: c.name
  Filter: (count(cw.word_id) > 2)
  Batches: 1  Memory Usage: 24kB
  ->  Nested Loop Left Join  (cost=8.47..21.62 rows=16 width=1552) (actual time=0.338..0.355 rows=5 loops=1)
        ->  Nested Loop  (cost=8.31..20.82 rows=1 width=1552) (actual time=0.156..0.168 rows=1 loops=1)
              ->  Hash Join  (cost=8.17..19.95 rows=1 width=1040) (actual time=0.131..0.137 rows=2 loops=1)
                    Hash Cond: (c.language_id = l.id)
                    ->  Seq Scan on collections c  (cost=0.00..11.40 rows=140 width=528) (actual time=0.044..0.046 rows=4 loops=1)
                    ->  Hash  (cost=8.16..8.16 rows=1 width=520) (actual time=0.068..0.068 rows=1 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          ->  Index Scan using languages_name_key on languages l  (cost=0.14..8.16 rows=1 width=520) (actual time=0.055..0.057 rows=1 loops=1)
                                Index Cond: ((name)::text = 'English'::text)
              ->  Index Scan using users_pkey on users u  (cost=0.14..0.50 rows=1 width=520) (actual time=0.013..0.013 rows=0 loops=2)
                    Index Cond: (id = c.creator_id)
                    Filter: ((nickname)::text = 'user1'::text)
                    Rows Removed by Filter: 0
        ->  Index Only Scan using collection_words_pkey on collection_words cw  (cost=0.15..0.69 rows=11 width=8) (actual time=0.180..0.183 rows=5 loops=1)
              Index Cond: (collection_id = c.id)
              Heap Fetches: 5
Planning Time: 6.759 ms
Execution Time: 0.742 ms

-- Запрос после создания индексов
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
HashAggregate  (cost=22.70..22.75 rows=1 width=1556) (actual time=0.063..0.064 rows=1 loops=1)
  Group Key: c.name
  Filter: (count(cw.word_id) > 2)
  Batches: 1  Memory Usage: 24kB
  ->  Nested Loop Left Join  (cost=2.39..19.87 rows=565 width=1552) (actual time=0.049..0.055 rows=5 loops=1)
        ->  Nested Loop  (cost=0.14..10.31 rows=1 width=1552) (actual time=0.037..0.042 rows=1 loops=1)
              Join Filter: (c.language_id = l.id)
              Rows Removed by Join Filter: 1
              ->  Nested Loop  (cost=0.00..2.14 rows=1 width=1040) (actual time=0.021..0.023 rows=2 loops=1)
                    Join Filter: (u.id = c.creator_id)
                    Rows Removed by Join Filter: 2
                    ->  Seq Scan on users u  (cost=0.00..1.05 rows=1 width=520) (actual time=0.012..0.013 rows=1 loops=1)
                          Filter: ((nickname)::text = 'user1'::text)
                          Rows Removed by Filter: 3
                    ->  Seq Scan on collections c  (cost=0.00..1.04 rows=4 width=528) (actual time=0.007..0.008 rows=4 loops=1)
              ->  Index Scan using languages_name_key on languages l  (cost=0.14..8.16 rows=1 width=520) (actual time=0.009..0.009 rows=1 loops=2)
                    Index Cond: ((name)::text = 'English'::text)
        ->  Bitmap Heap Scan on collection_words cw  (cost=2.24..9.45 rows=11 width=8) (actual time=0.011..0.012 rows=5 loops=1)
              Recheck Cond: (c.id = collection_id)
              Heap Blocks: exact=1
              ->  Bitmap Index Scan on collection_words_pkey  (cost=0.00..2.24 rows=11 width=0) (actual time=0.005..0.005 rows=5 loops=1)
                    Index Cond: (collection_id = c.id)
Planning Time: 0.435 ms
Execution Time: 0.117 ms
```

#### 4.2.2. Запрос 2: Список упражнений с общим количеством слов и средней оценкой попыток
Описание: Запрос выводит список всех упражнений, количество слов в каждом упражнении и среднюю оценку по всем попыткам для каждого упражнения.
Ожидаемый эффект: без индексов - Seq Scan и Hash Join; с индексами - Index Scan, Nested Loop.
```
-- Запрос без индексов
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
Sort  (cost=14241.82..14297.82 rows=22400 width=774) (actual time=0.821..0.825 rows=4 loops=1)
  Sort Key: (avg(a.score)) DESC NULLS LAST
  Sort Method: quicksort  Memory: 25kB
  ->  GroupAggregate  (cost=11.85..4965.29 rows=22400 width=774) (actual time=0.730..0.742 rows=4 loops=1)
        Group Key: et.name, e.exercise_name
        ->  Incremental Sort  (cost=11.85..4246.20 rows=43909 width=742) (actual time=0.692..0.696 rows=15 loops=1)
              Sort Key: et.name, e.exercise_name
              Presorted Key: et.name
              Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB
              ->  Nested Loop Left Join  (cost=0.31..2132.10 rows=43909 width=742) (actual time=0.558..0.650 rows=15 loops=1)
                    ->  Nested Loop Left Join  (cost=0.15..1854.82 rows=1360 width=742) (actual time=0.266..0.318 rows=6 loops=1)
                          Join Filter: (e.id = a.exercise_id)
                          Rows Removed by Join Filter: 15
                          ->  Nested Loop  (cost=0.15..399.82 rows=70 width=738) (actual time=0.190..0.225 rows=4 loops=1)
                                Join Filter: (et.id = e.exercise_type_id)
                                Rows Removed by Join Filter: 12
                                ->  Index Scan using exercise_types_name_key on exercise_types et  (cost=0.15..52.95 rows=320 width=222) (actual time=0.012..0.036 rows=4 loops=1)
                                ->  Materialize  (cost=0.00..11.05 rows=70 width=524) (actual time=0.042..0.044 rows=4 loops=4)
                                      ->  Seq Scan on exercises e  (cost=0.00..10.70 rows=70 width=524) (actual time=0.035..0.037 rows=4 loops=1)
                          ->  Materialize  (cost=0.00..30.40 rows=1360 width=8) (actual time=0.018..0.021 rows=5 loops=4)
                                ->  Seq Scan on attempts a  (cost=0.00..23.60 rows=1360 width=8) (actual time=0.052..0.056 rows=5 loops=1)
                    ->  Memoize  (cost=0.17..1.04 rows=11 width=8) (actual time=0.051..0.053 rows=2 loops=6)
                          Cache Key: e.id
                          Cache Mode: logical
                          Hits: 2  Misses: 4  Evictions: 0  Overflows: 0  Memory Usage: 1kB
                          ->  Index Only Scan using exercise_words_pkey on exercise_words ew  (cost=0.15..1.03 rows=11 width=8) (actual time=0.072..0.074 rows=2 loops=4)
                                Index Cond: (exercise_id = e.id)
                                Heap Fetches: 9
Planning Time: 3.297 ms
Execution Time: 0.942 ms

-- Запрос после создания индексов
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
Sort  (cost=72.45..72.49 rows=16 width=774) (actual time=0.232..0.237 rows=4 loops=1)
  Sort Key: (avg(a.score)) DESC NULLS LAST
  Sort Method: quicksort  Memory: 25kB
  ->  HashAggregate  (cost=71.93..72.13 rows=16 width=774) (actual time=0.205..0.211 rows=4 loops=1)
        Group Key: e.exercise_name, et.name
        Batches: 1  Memory Usage: 24kB
        ->  Nested Loop Left Join  (cost=4.43..43.68 rows=2825 width=742) (actual time=0.119..0.175 rows=15 loops=1)
              ->  Hash Join  (cost=2.18..3.28 rows=5 width=742) (actual time=0.091..0.108 rows=6 loops=1)
                    Hash Cond: (e.exercise_type_id = et.id)
                    ->  Hash Right Join  (cost=1.09..2.16 rows=5 width=528) (actual time=0.040..0.054 rows=6 loops=1)
                          Hash Cond: (a.exercise_id = e.id)
                          ->  Seq Scan on attempts a  (cost=0.00..1.05 rows=5 width=8) (actual time=0.009..0.010 rows=5 loops=1)
                          ->  Hash  (cost=1.04..1.04 rows=4 width=524) (actual time=0.015..0.016 rows=4 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                ->  Seq Scan on exercises e  (cost=0.00..1.04 rows=4 width=524) (actual time=0.009..0.010 rows=4 loops=1)
                    ->  Hash  (cost=1.04..1.04 rows=4 width=222) (actual time=0.032..0.032 rows=4 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          ->  Seq Scan on exercise_types et  (cost=0.00..1.04 rows=4 width=222) (actual time=0.020..0.022 rows=4 loops=1)
              ->  Memoize  (cost=2.25..9.46 rows=11 width=8) (actual time=0.008..0.010 rows=2 loops=6)
                    Cache Key: e.id
                    Cache Mode: logical
                    Hits: 2  Misses: 4  Evictions: 0  Overflows: 0  Memory Usage: 1kB
                    ->  Bitmap Heap Scan on exercise_words ew  (cost=2.24..9.45 rows=11 width=8) (actual time=0.007..0.008 rows=2 loops=4)
                          Recheck Cond: (e.id = exercise_id)
                          Heap Blocks: exact=4
                          ->  Bitmap Index Scan on exercise_words_pkey  (cost=0.00..2.24 rows=11 width=0) (actual time=0.003..0.003 rows=2 loops=4)
                                Index Cond: (exercise_id = e.id)
Planning Time: 0.755 ms
Execution Time: 0.359 ms
```

### 4.3. Транзакции и аномалии параллельного доступа

#### 4.3.1. Dirty Read (Грязное чтение)
<u>Сценарий:</u>
Исходное состояние: users (id=1, nickname='user1')

Транзакция T1 (уровень изоляции READ COMMITTED - по умолчанию):
```sql
BEGIN;
SELECT nickname FROM users WHERE id = 1; -- Получает 'user1'
-- (Пауза, пока T2 делает изменения)
SELECT nickname FROM users WHERE id = 1; -- Снова получает 'user1', т.к. T2 еще не закоммитилась (Dirty Read предотвращен)
COMMIT;
```

Транзакция T2:
```sql
BEGIN;
UPDATE users SET nickname = 'DirtyUser' WHERE id = 1;
-- (Пауза, чтобы T1 успела прочитать до коммита)
ROLLBACK; -- Откат изменений
```

Описание: В PostgreSQL на уровне READ COMMITTED транзакция T1 не сможет прочитать изменения, сделанные T2, пока T2 не закоммитит свои изменения. Таким образом, Dirty Read предотвращается.
Как избавиться: В PostgreSQL по умолчанию уровень изоляции READ COMMITTED уже предотвращает Dirty Read.

#### 4.3.2. Non-repeatable Read (Неповторяющееся чтение)
<u>Сценарий:</u>
Исходное состояние: users (id=1, nickname='user1')

Транзакция T1 (уровень изоляции READ COMMITTED):
```sql
BEGIN;
SELECT nickname FROM users WHERE id = 1; -- Получает 'user1'
-- (Пауза, пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1; -- Получает 'UpdatedUser', т.к. T2 закоммитилась
COMMIT;
```

Транзакция T2:
```sql
BEGIN;
UPDATE users SET nickname = 'UpdatedUser' WHERE id = 1;
COMMIT;
```
Описание: T1 сначала читает 'user1'. Пока T1 находится в паузе, T2 обновляет никнейм и коммитит. Когда T1 читает снова, она видит новое значение 'UpdatedUser'. Это Non-repeatable Read.
Как избавиться: Установить уровень изоляции REPEATABLE READ для Транзакции T1.

Транзакция T1 (уровень изоляции REPEATABLE READ):
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT nickname FROM users WHERE id = 1; -- Получает 'user1'
-- (Пауза, пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1; -- Снова получает 'user1', потому что REPEATABLE READ не дает видеть изменения других транзакций после первого чтения.
COMMIT;
```
#### 4.3.3. Phantom Read (Фантомное чтение)
<u>Сценарий:</u>
Исходное состояние: В таблице words есть слова только для language_id = 1, 2, 3.

Транзакция T1 (уровень изоляции REPEATABLE READ):
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM words WHERE language_id = 4; -- Получает 0
-- (Пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 4; -- Все еще получает 0, т.к. REPEATABLE READ не позволяет видеть новые строки.
COMMIT;
```

Транзакция T2:
```sql
BEGIN;
INSERT INTO words (language_id, word_text, translation) VALUES (4, 'NewWord', 'НовоеСлово');
COMMIT;
```

Описание: В PostgreSQL уровень изоляции `REPEATABLE READ` может предотвращать *некоторые* виды фантомных чтений (например, для запросов с условием равенства, как показано выше), но для *полной* гарантии отсутствия фантомов во всех сложных сценариях (например, с более сложными условиями или агрегациями) необходим уровень изоляции `SERIALIZABLE`.
Как избавиться: Установить уровень изоляции SERIALIZABLE для Транзакции T1.

Транзакция T1 (уровень изоляции SERIALIZABLE):
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM words WHERE language_id = 4; -- Получает 0
-- (Пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 4; -- Все еще получает 0.
COMMIT; -- Если T2 закоммитилась, эта транзакция может быть отменена с ошибкой сериализации.
```

Важно: При уровне SERIALIZABLE, если транзакция T2 добавила строку, которая могла бы изменить результат запроса T1, то T1 может быть откачена с ошибкой сериализации, требуя повторного выполнения. Это гарантирует, что параллельно выполняющиеся сериализуемые транзакции производят тот же результат, что и последовательное их выполнение.



