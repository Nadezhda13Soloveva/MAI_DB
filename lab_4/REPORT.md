
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

#### Созданные индексы

| Таблица | Название индекса | Поле(я) | Причина |
| :--------------- | :---------------------------------- | :-------------------------------- | :---------------------------------------------------------------------------- |
| `user_languages` | `idx_user_languages_user_id` | `user_id` | Ускорение поиска и соединений по `user_id`|
| `user_languages` | `idx_user_languages_language_id` | `language_id` | Ускорение поиска и соединений по `language_id`|
| `collections` | `idx_collections_language_id` | `language_id` | Ускорение поиска и соединений по `language_id`|
| `collections` | `idx_collections_creator_id` | `creator_id` | Ускорение поиска и соединений по `creator_id`|
| `collections` | `idx_collections_name` | `name` | Ускорение поиска и сортировки по названию коллекции|
| `words` | `idx_words_language_id` | `language_id` | Ускорение поиска и фильтрации по `language_idё |
| `words` | `idx_words_word_text` | `word_text` | Ускорение поиска и сортировки по тексту слова|
| `words` | `idx_words_translation` | `translation` | Ускорение поиска и сортировки по переводу слова |
| `collection_words` | `idx_collection_words_collection_id` | `collection_id` | Ускорение поиска и соединений по `collection_id` |
| `collection_words` | `idx_collection_words_word_id` | `word_id` | Ускорение поиска и соединений по `word_id` |
| `exercises` | `idx_exercises_exercise_type_id` | `exercise_type_id` | Ускорение поиска и фильтрации по `exercise_type_id`|
| `exercises` | `idx_exercises_exercise_name` | `exercise_name` | Ускорение поиска и сортировки по названию упражнения |
| `exercises` | `idx_exercises_difficulty_level` | `difficulty_level` | Ускорение поиска и фильтрации по уровню сложности |
| `exercise_words` | `idx_exercise_words_exercise_id` | `exercise_id` | Ускорение поиска и соединений по `exercise_id` |
| `exercise_words` | `idx_exercise_words_word_id` | `word_id` | Ускорение поиска и соединений по `word_id`|
| `attempts` | `idx_attempts_user_id` | `user_id` | Ускорение поиска и фильтрации по `user_id` |
| `attempts` | `idx_attempts_exercise_id` | `exercise_id` | Ускорение поиска и фильтрации по `exercise_id` |
| `attempts` | `idx_attempts_started_at` | `started_at` | Ускорение поиска по диапазону дат и сортировки|
| `attempts` | `idx_attempts_completed_at` | `completed_at` | Ускорение поиска по диапазону дат и сортировки |
| `attempts` | `idx_attempts_score` | `score` | Ускорение поиска и фильтрации по баллам|
| `attempts` | `idx_attempts_user_exercise_score` | `user_id, exercise_id, score DESC` | Ускорение поиска, фильтрации и сортировки для комплексных запросов |
| `collections` | `idx_collections_language_creator` | `language_id, creator_id` | Ускорение поиска и фильтрации по языку и создателю коллекции|

#### Анализ простых запросов с индексами

| Запрос | Наличие индекса | Тип сканирования | Execution Time | Коммент |
| :------------------------------------------------------------ | :-------------- | :-------------------------------- | :--------- | :---------- |
| `SELECT * FROM users WHERE nickname = 'user_100';` | НЕТ | Seq Scan | 0.359 ms | Тут индекс не был создан, поэтому БД прошлась по всей таблице, чтобы найти нужного пользователя |
| `SELECT * FROM users WHERE nickname = 'user_100';` | ДА | Seq Scan | 0.074 ms | Даже с индексом по никнейму, БД всё равно решила пройтись по всей таблице. Вероятно, потому что таблица с пользователями оказалась небольшой (всего 200 записей), и прямой перебор оказался быстрее, чем использование индекса|
| `SELECT * FROM words WHERE language_id = 5;` | НЕТ | Seq Scan | 0.231 ms | Без индекса на `language_id` пришлось сканировать всю таблицу слов|
| `SELECT * FROM words WHERE language_id = 5;` | ДА | Bitmap Index Scan | 0.195 ms | Здесь индекс `idx_words_language_id` помог: БД сначала быстро нашла нужные записи по индексу, а потом получила данные из таблицы. Время немного сократилось|
| `SELECT * FROM collections WHERE creator_id = 50;` | НЕТ | Seq Scan | 0.109 ms | Опять же, без индекса на `creator_id` пришлось делать полное сканирование коллекции|
| `SELECT * FROM collections WHERE creator_id = 50;` | ДА | Seq Scan | 0.080 ms | Как и с пользователями, таблица коллекций (300 записей) оказалась слишком маленькой, чтобы индекс на `creator_id` существенно повлиял. Оптимизатор выбрал полное сканирование |
| `SELECT * FROM attempts WHERE user_id = 75 ORDER BY started_at DESC;` | НЕТ | Seq Scan | 0.322 ms | Без индекса, чтобы отсортировать попытки пользователя, БД сначала просканировала всё, а потом отсортировала в памяти|
| `SELECT * FROM attempts WHERE user_id = 75 ORDER BY started_at DESC;` | ДА | Bitmap Index Scan | 0.130 ms | Вот тут индекс `idx_attempts_user_id` помог: запрос выполнился быстрее, так как данные по пользователю были найдены по индексу, и сортировка по дате тоже использовала индекс|
| `SELECT * FROM exercises WHERE difficulty_level = 'Intermediate';` | НЕТ | Seq Scan | 0.112 ms | Полное сканирование упражнений, так как по уровню сложности индекса нет|
| `SELECT * FROM exercises WHERE difficulty_level = 'Intermediate';` | ДА | Seq Scan | 0.097 ms | Таблица с упражнениями тоже невелика (200 записей), поэтому индекс на `difficulty_level` не сильно изменил план выполнения — оптимизатор всё равно выбрал полное сканирование|


### 4.2. Анализ производительности с EXPLAIN

#### Запрос 1: Получить все слова (word_text, translation) из коллекций, созданных пользователями, изучающими 'English', отсортированные по названию коллекции и слову.

```sql
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
```

| Наличие индексов | План выполнения | Время (ms) | Комментарий |
| :--------------- | :-------------- | :--------- | :---------- |
| НЕТ | Sort  (cost=18.91..18.93 rows=7 width=30) (actual time=0.807..0.813 rows=18 loops=1)<br>  Sort Key: c.name, w.word_text<br>  Sort Method: quicksort  Memory: 25kB<br>  ->  Nested Loop  (cost=9.14..18.81 rows=7 width=30) (actual time=0.470..0.641 rows=18 loops=1)<br>        ->  Nested Loop  (cost=8.87..16.57 rows=7 width=18) (actual time=0.418..0.492 rows=18 loops=1)<br>              ->  Nested Loop  (cost=8.59..15.96 rows=1 width=18) (actual time=0.388..0.450 rows=2 loops=1)<br>                    ->  Nested Loop  (cost=8.45..15.75 rows=1 width=26) (actual time=0.362..0.420 rows=2 loops=1)<br>                          Join Filter: (ul.language_id = l.id)<br>                          ->  Hash Join  (cost=8.17..14.98 rows=2 width=30) (actual time=0.275..0.353 rows=17 loops=1)<br>                                Hash Cond: (c.language_id = l.id)<br>                                ->  Seq Scan on collections c  (cost=0.00..6.00 rows=300 width=26) (actual time=0.029..0.067 rows=300 loops=1)<br>                                ->  Hash  (cost=8.16..8.16 rows=1 width=4) (actual time=0.212..0.213 rows=1 loops=1)<br>                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB<br>                                      ->  Index Scan using languages_name_key on languages l  (cost=0.14..8.16 rows=1 width=4) (actual time=0.197..0.199 rows=1 loops=1)<br>                                            Index Cond: ((name)::text = 'English'::text)<br>                          ->  Index Only Scan using user_languages_pkey on user_languages ul  (cost=0.27..0.37 rows=1 width=8) (actual time=0.003..0.003 rows=0 loops=17)<br>                                Index Cond: ((user_id = c.creator_id) AND (language_id = c.language_id))<br>                                Heap Fetches: 2<br>                    ->  Index Only Scan using users_pkey on users u  (cost=0.14..0.21 rows=1 width=4) (actual time=0.013..0.013 rows=1 loops=2)<br>                          Index Cond: (id = ul.user_id)<br>                          Heap Fetches: 2<br>              ->  Index Only Scan using collection_words_pkey on collection_words cw  (cost=0.28..0.53 rows=7 width=8) (actual time=0.016..0.018 rows=9 loops=2)<br>                    Index Cond: (collection_id = c.id)<br>                    Heap Fetches: 0<br>        ->  Index Scan using words_pkey on words w  (cost=0.28..0.32 rows=1 width=20) (actual time=0.008..0.008 rows=1 loops=18)<br>              Index Cond: (id = cw.word_id)<br> | Planning Time: 14.234 ms<br>Execution Time: 1.015 ms | В этом случае, несмотря на отсутствие дополнительных индексов, PostgreSQL использует существующие PRIMARY KEY (которые являются индексами) для ускорения операций JOIN. Основные затраты времени приходятся на Sequential Scan по `collections` и `Hash Join`. Отсутствие индексов на FK-полях `user_languages` приводит к `Index Only Scan` по `user_languages_pkey` с `Join Filter` и `Heap Fetches`. |
| ДА | Sort  (cost=18.65..18.66 rows=7 width=30) (actual time=0.264..0.267 rows=18 loops=1)<br>  Sort Key: c.name, w.word_text<br>  Sort Method: quicksort  Memory: 25kB<br>  ->  Nested Loop  (cost=9.02..18.55 rows=7 width=30) (actual time=0.152..0.223 rows=18 loops=1)<br>        ->  Nested Loop  (cost=8.74..16.30 rows=7 width=18) (actual time=0.145..0.185 rows=18 loops=1)<br>              ->  Nested Loop  (cost=8.47..15.70 rows=1 width=18) (actual time=0.132..0.165 rows=2 loops=1)<br>                    ->  Nested Loop  (cost=8.32..15.49 rows=1 width=26) (actual time=0.124..0.155 rows=2 loops=1)<br>                          Join Filter: (ul.language_id = l.id)<br>                          ->  Hash Join  (cost=8.17..14.98 rows=2 width=30) (actual time=0.077..0.117 rows=17 loops=1)<br>                                Hash Cond: (c.language_id = l.id)<br>                                ->  Seq Scan on collections c  (cost=0.00..6.00 rows=300 width=26) (actual time=0.023..0.042 rows=300 loops=1)<br>                                ->  Hash  (cost=8.16..8.16 rows=1 width=4) (actual time=0.037..0.038 rows=1 loops=1)<br>                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB<br>                                      ->  Index Scan using languages_name_key on languages l  (cost=0.14..8.16 rows=1 width=4) (actual time=0.032..0.033 rows=1 loops=1)<br>                                            Index Cond: ((name)::text = 'English'::text)<br>                          ->  Index Scan using idx_user_languages_user_id on user_languages ul  (cost=0.15..0.24 rows=1 width=8) (actual time=0.002..0.002 rows=0 loops=17)<br>                                Index Cond: (user_id = c.creator_id)<br>                                Filter: (language_id = c.language_id)<br>                                Rows Removed by Filter: 2<br>                    ->  Index Only Scan using users_pkey on users u  (cost=0.14..0.21 rows=1 width=4) (actual time=0.004..0.004 rows=1 loops=2)<br>                          Index Cond: (id = ul.user_id)<br>                          Heap Fetches: 2<br>              ->  Index Only Scan using collection_words_pkey on collection_words cw  (cost=0.28..0.53 rows=7 width=8) (actual time=0.008..0.009 rows=9 loops=2)<br>                    Index Cond: (collection_id = c.id)<br>                    Heap Fetches: 0<br>        ->  Index Scan using words_pkey on words w  (cost=0.28..0.32 rows=1 width=20) (actual time=0.002..0.002 rows=1 loops=18)<br>              Index Cond: (id = cw.word_id) | Planning Time: 10.214 ms<br>Execution Time: 0.366 ms | После добавления индексов, `Seq Scan` по `collections` все еще используется, так как таблица небольшая. Однако `Index Scan` по `idx_user_languages_user_id` теперь эффективно используется, уменьшая `Rows Removed by Filter` (в этом случае, так как строк всего 0 после фильтрации, это не сильно влияет на общее время, но для больших объемов данных это будет критично). Общее время выполнения запроса заметно сократилось (с 1.015 ms до 0.366 ms). |

#### Запрос 2: Получить средний балл за попытки по каждому упражнению для пользователей, которые набрали >80 б в любой из попыток.

```sql
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
```

| Наличие индексов | План выполнения | Время (ms) | Комментарий |
| :--------------- | :-------------- | :--------- | :---------- |
| НЕТ | Sort  (cost=84.22..84.72 rows=200 width=44) (actual time=5.855..5.885 rows=199 loops=1)<br>  Sort Key: (avg(a.score)) DESC<br>  Sort Method: quicksort  Memory: 33kB<br>  ->  HashAggregate  (cost=74.08..76.58 rows=200 width=44) (actual time=2.605..2.726 rows=199 loops=1)<br>        Group Key: e.exercise_name<br>        Batches: 1  Memory Usage: 64kB<br>        ->  Hash Join  (cost=33.65..69.08 rows=1000 width=16) (actual time=0.638..1.312 rows=973 loops=1)<br>              Hash Cond: (a.user_id = attempts.user_id)<br>              ->  Hash Join  (cost=6.50..28.18 rows=1000 width=20) (actual time=0.210..0.651 rows=1000 loops=1)<br>                    Hash Cond: (a.exercise_id = e.id)<br>                    ->  Seq Scan on attempts a  (cost=0.00..19.00 rows=1000 width=12) (actual time=0.067..0.179 rows=1000 loops=1)<br>                    ->  Hash  (cost=4.00..4.00 rows=200 width=16) (actual time=0.097..0.098 rows=200 loops=1)<br>                          Buckets: 1024  Batches: 1  Memory Usage: 18kB<br>                          ->  Seq Scan on exercises e  (cost=0.00..4.00 rows=200 width=16) (actual time=0.019..0.052 rows=200 loops=1)<br>              ->  Hash  (cost=24.72..24.72 rows=194 width=4) (actual time=0.410..0.420 rows=188 loops=1)<br>                    Buckets: 1024  Batches: 1  Memory Usage: 15kB<br>                    ->  HashAggregate  (cost=22.78..24.72 rows=194 width=4) (actual time=0.350..0.379 rows=188 loops=1)<br>                          Group Key: attempts.user_id<br>                          Batches: 1  Memory Usage: 40kB<br>                          ->  Seq Scan on attempts  (cost=0.00..21.50 rows=512 width=4) (actual time=0.010..0.196 rows=512 loops=1)<br>                                Filter: (score > 80)<br>                                Rows Removed by Filter: 488 | Planning Time: 3.749 ms<br>Execution Time: 6.090 ms | Без индексов запрос использует `Hash Join` и `Seq Scan` для большинства таблиц. `Seq Scan` на `attempts` с фильтром `score > 80` показывает, что сканируется вся таблица для поиска подходящих записей, что не оптимально. Значительные затраты времени на `HashAggregate` и `Sort`. |
| ДА | Sort  (cost=84.22..84.72 rows=200 width=44) (actual time=2.115..2.129 rows=199 loops=1)<br>  Sort Key: (avg(a.score)) DESC<br>  Sort Method: quicksort  Memory: 33kB<br>  ->  HashAggregate  (cost=74.08..76.58 rows=200 width=44) (actual time=1.951..2.025 rows=199 loops=1)<br>        Group Key: e.exercise_name<br>        Batches: 1  Memory Usage: 64kB<br>        ->  Hash Join  (cost=33.65..69.08 rows=1000 width=16) (actual time=0.787..1.564 rows=973 loops=1)<br>              Hash Cond: (a.user_id = attempts.user_id)<br>              ->  Hash Join  (cost=6.50..28.18 rows=1000 width=20) (actual time=0.237..0.743 rows=1000 loops=1)<br>                    Hash Cond: (a.exercise_id = e.id)<br>                    ->  Seq Scan on attempts a  (cost=0.00..19.00 rows=1000 width=12) (actual time=0.039..0.168 rows=1000 loops=1)<br>                    ->  Hash  (cost=4.00..4.00 rows=200 width=16) (actual time=0.150..0.150 rows=200 loops=1)<br>                          Buckets: 1024  Batches: 1  Memory Usage: 18kB<br>                          ->  Seq Scan on exercises e  (cost=0.00..4.00 rows=200 width=16) (actual time=0.021..0.067 rows=200 loops=1)<br>              ->  Hash  (cost=24.72..24.72 rows=194 width=4) (actual time=0.528..0.530 rows=188 loops=1)<br>                    Buckets: 1024  Batches: 1  Memory Usage: 15kB<br>                    ->  HashAggregate  (cost=22.78..24.72 rows=194 width=4) (actual time=0.439..0.478 rows=188 loops=1)<br>                          Group Key: attempts.user_id<br>                          Batches: 1  Memory Usage: 40kB<br>                          ->  Seq Scan on attempts  (cost=0.00..21.50 rows=512 width=4) (actual time=0.019..0.265 rows=512 loops=1)<br>                                Filter: (score > 80)<br>                                Rows Removed by Filter: 488 | Planning Time: 2.569 ms<br>Execution Time: 2.268 ms | Несмотря на наличие индексов, оптимизатор все еще выбирает `Seq Scan` для `attempts` и `exercises` из-за небольшого размера таблиц. Однако, общее время выполнения заметно сократилось (с 6.090 ms до 2.268 ms). Это связано с улучшенным `Planning Time` и, возможно, более эффективной работой `Hash Join` на индексированных полях. Особенно важен индекс `idx_attempts_user_exercise_score`, который хотя и не отображается явно в этом плане, мог повлиять на общую стратегию или на внутренние операции. |


### 4.3. Транзакции и аномалии параллельного доступа

#### 4.3.1. Dirty Read (Грязное чтение)
<u>Сценарий:</u>
Исходное состояние: users (id=1, nickname='user1')

Транзакция T1 (уровень изоляции READ COMMITTED - по умолчанию):
```sql
BEGIN;
SELECT nickname FROM users WHERE id = 1; -- получим 'user1'
-- (пауза пока T2 делает изменения)
SELECT nickname FROM users WHERE id = 1; -- снова получаем 'user1', т.к. T2 еще не закоммитилась (Dirty Read предотвращен)
COMMIT;
```

Транзакция T2:
```sql
BEGIN;
UPDATE users SET nickname = 'DirtyUser' WHERE id = 1;
-- (пауза, чтобы T1 успела прочитать до коммита)
ROLLBACK;
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
SELECT nickname FROM users WHERE id = 1; -- получаем 'user1'
-- (пауза  пока T2 делает и коммитит изменения)
SELECT nickname FROM users WHERE id = 1; -- снова получили 'user1', потому что REPEATABLE READ не дает видеть изменения других транзакций после первого чтения
COMMIT;
```
#### 4.3.3. Phantom Read (Фантомное чтение)
<u>Сценарий:</u>
Исходное состояние: В таблице words нет слов для language_id = 11.

Транзакция T1 (уровень изоляции REPEATABLE READ):
```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM words WHERE language_id = 11; -- получили 0
-- (пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 11; -- все еще получаем 0, т.к. REPEATABLE READ не позволяет видеть новые строки
COMMIT;
```

Транзакция T2:
```sql
BEGIN;
INSERT INTO words (language_id, word_text, translation) VALUES (11, 'NewWord', 'НовоеСлово');
COMMIT;
```

Описание: В PostgreSQL уровень изоляции `REPEATABLE READ` может предотвращать *некоторые* виды фантомных чтений (например, для запросов с условием равенства, как показано выше), но для полной гарантии отсутствия фантомов во всех сложных сценариях (например, с более сложными условиями или агрегациями) необходим уровень изоляции `SERIALIZABLE`.
Как избавиться: Установить уровень изоляции SERIALIZABLE для Транзакции T1.

Транзакция T1 (уровень изоляции SERIALIZABLE):
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM words WHERE language_id = 11; -- получим 0
-- (пауза, пока T2 добавляет новую строку)
SELECT COUNT(*) FROM words WHERE language_id = 11; -- все еще получаем 0
COMMIT; -- если T2 коммит, то эта транзакция может быть отменена с ошибкой сериализации
```

Важно: При уровне SERIALIZABLE, если транзакция T2 добавила строку, которая могла бы изменить результат запроса T1, то T1 может быть откачена с ошибкой сериализации, требуя повторного выполнения. Это гарантирует, что параллельно выполняющиеся сериализуемые транзакции производят тот же результат, что и последовательное их выполнение.




