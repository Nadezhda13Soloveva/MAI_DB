# Лабораторная работа №1: Проектирование реляционной модели данных

## 1. Цель работы

Освоить методологию проектирования реляционных баз данных путем создания концептуальной и логической модели данных для заданной предметной области. Сформировать практические навыки разработки ER-диаграмм и их реализации на языке SQL.

## 2. Задачи работы

1. Проанализировать предложенную предметную область и выделить ключевые сущности
2. Определить атрибуты сущностей и связи между ними
3. Спроектировать ER-диаграмму в нотации PlantUML
4. Реализовать модель данных в виде SQL DDL скрипта
5. Обосновать выбранные типы данных и структуру таблиц

### Вариант 19: Приложение для изучения языков (Vocabulary Trainer)

**Описание:** Пользователи создают коллекции слов и фраз для изучения (словари). Система предоставляет упражнения для запоминания (карточки, тесты) и отслеживает прогресс изучения каждого слова.

## 3. Теоретические сведения

### 3.1. Основные понятия реляционной модели

**Модель данных** — формализованное описание структуры данных, их атрибутов, ограничений и взаимосвязей, определяющее принципы хранения и манипулирования информацией в базе данных.

**Сущность (Entity)** — абстракция реального объекта или явления предметной области, информация о котором подлежит хранению. В реляционной модели сущности соответствуют таблицам.

**Атрибут (Attribute)** — характеристика сущности, описывающая ее свойства. Каждый атрибут имеет имя и тип данных. В таблицах атрибуты представлены столбцами.

**Связь (Relationship)** — логическая ассоциация между двумя или более сущностями, отражающая бизнес-правила предметной области.

### 3.2. Типы связей между сущностями

| Тип связи | Обозначение | Описание | Пример |
|-----------|-------------|----------|---------|
| Один-к-одному | 1:1 | Каждый экземпляр одной сущности связан не более чем с одним экземпляром другой сущности | Паспорт ↔ Человек |
| Один-ко-многим | 1:N | Экземпляр одной сущности может быть связан с несколькими экземплярами другой сущности | Заказ ↔ Позиции заказа |
| Многие-ко-многим | M:N | Каждый экземпляр одной сущности может быть связан с несколькими экземплярами другой сущности и наоборот | Студенты ↔ Курсы |

## 4. Решение: Приложение для изучения языков

### 4.1 Анализ предметной области

**Ключевые сущности:**
 * Пользователи
 * Коллекции (словари) слов, созданные пользователем
 * Слова и словосочетания
 * Упражнения, предоставляемые системой для запоминания
 * Языки
 * Попытки

### 4.2 Сущности, атрибуты и связи

#### 4.2.1 Атрибуты

**Пользователь:**   
    - ID    
    - Никнейм   
    - Почта     
    - Хэш-пароль    

**Язык:**   
    - ID    
    - Название  

**Коллекция слов:**     
    - ID    
    - Язык ID   
    - Название  
    - Создатель ID  

**Слова и словосочетания:** 
    - ID    
    - Язык ID   
    - Слово     
    - Перевод   
    - Транскрипция  

**Типы упражнений:**
    - ID
    - Название

**Упражнения:**     
    - ID    
    - Тип упражнения ID
    - Название упражнения   
    - Уровень сложности     

**Попытки:**    
    - ID
    - Пользователь ID   
    - Упражнение ID     
    - Дата начала прохождения   
    - Дата конца прохождения    
    - Результат (баллы от 0 до 100)

#### 4.2.2 Связи

* **Пользователь <-> Языки**: M:N, т.к. один пользователь может выбрать несколько языков для изучения, и один язык может изучаться многими пользователями
* **Пользователь <-> Коллекции**: 1:N, т.к. один пользователь создает много словарей
* **Коллекции <-> Слова**: M:N, т.к. в одной коллекции может быть много слов и одно слово может быть в нескольких коллекциях
* **Упражнения <-> Слова**: M:N, т.к. в одном упражнении может быть много слов и одно слово может быть в нескольких упражнениях
* **Пользователь <-> Попытки**: 1:N, т.к. один пользователь делает много попыток прохождения упражнений
* **Упражнение <-> Попытки**: 1:N, т.к. может быть много попыток прохождения одного упражнения

### 4.3 ER-диаграмма

```plantuml
@startuml
!theme plain
hide circle
left to right direction

entity "User" as User {
  * ID : int
  --
  Nickname : varchar(255)
  Email : varchar(255)
  Hashed_password : varchar(255)
}

entity "Language" as Language {
  * ID : int
  --
  Name : varchar(255)
}

entity "Collection" as Collection {
  * ID : int
  --
  Name : varchar(255)
  Language ID : int
  Creator ID : int
}

entity "Word" as Word {
  * ID : int
  --
  Language ID : int
  Word : varchar(255)
  Translation : varchar(255)
  Transcription : varchar(255)
}

entity "ExerciseType" as ExerciseType {
  * ID : int
  --
  Name : varchar(100)
}

entity "Exercise" as Exercise {
  * ID : int
  --
  Exercise Type ID : int
  Exercise Name : varchar(255)
  Difficulty Level : varchar(255)
}

entity "Attempt" as Attempt {
  * ID : int
  --
  User ID : int
  Exercise ID : int
  Started At : datetime
  Completed At : datetime
  Score : int
}

' Junction tables for M:N relationships
entity "User_Language" as UserLanguage {
  * User ID : int
  * Language ID : int
}

entity "Collection_Word" as CollectionWord {
  * Collection ID : int
  * Word ID : int
}

entity "Exercise_Word" as ExerciseWord {
  * Exercise ID : int
  * Word ID : int
}

' Defining relationships
User ||--o{ UserLanguage
Language ||--o{ UserLanguage

User ||--o{ Collection
Collection }o--|| Language

Collection ||--o{ CollectionWord
Word ||--o{ CollectionWord

ExerciseType ||--o{ Exercise

Exercise ||--o{ ExerciseWord
Word ||--o{ ExerciseWord

User ||--o{ Attempt
Exercise ||--o{ Attempt
@enduml
```
Или вот магия  картиночек

![ER Diagram](er_diagramm.png)

### 4.4 SQL DDL скрипт модели данных

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

-- Создание таблицы Типы упражнений
CREATE TABLE exercise_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Создание таблицы Упражнения
CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    exercise_type_id INT NOT NULL,
    exercise_name VARCHAR(255) NOT NULL,
    difficulty_level VARCHAR(255),
    FOREIGN KEY (exercise_type_id) REFERENCES exercise_types(id) ON DELETE CASCADE
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
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    score INT CHECK (score >= 0 AND score <= 100),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);
```

### 4.5 Обоснование выбранных типов данных и структуры таблиц

#### Общая инфа:
*   **`SERIAL PRIMARY KEY`**: Используется для столбцов `id` во всех основных таблицах, обеспечивает автоматическое увеличение уникальных целочисленных идентификаторов.
*   **`INT`**: Применяется для всех внешних ключей (`_id`) и для полей, где ожидаются целочисленные значения (например, `result`).
*   **`VARCHAR(255)`**: Оптимальный выбор для строковых данных переменной длины. Длина 255 символов является достаточной для большинства таких полей.
*   **`UNIQUE NOT NULL`**: Применяется к полям, которые должны быть уникальными (например, `nickname`, `email` пользователя, `name` языка) и не могут быть пустыми, обеспечивая целостность данных.
*   **`NOT NULL`**: Используется для полей, которые обязательно должны содержать значение.
*   **`TIMESTAMP`**: Для хранения даты и времени с точностью до секунды.
*   **`ON DELETE CASCADE`**: При удалении записи из родительской таблицы, автоматически удаляются все связанные записи из дочерних таблиц. Это обеспечивает каскадное удаление и предотвращает "висячие" ссылки.

#### Обоснование по таблицам:

1.  **`users`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор пользователя.
    *   `nickname`: `VARCHAR(255) UNIQUE NOT NULL` – уникальный никнейм пользователя, обязателен.
    *   `email`: `VARCHAR(255) UNIQUE NOT NULL` – уникальный адрес электронной почты, обязателен для аутентификации.
    *   `hashed_password`: `VARCHAR(255) NOT NULL` – хранит хэш пароля пользователя. Длина 255 символов достаточна для большинства современных хэшей.

2.  **`languages`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор языка.
    *   `name`: `VARCHAR(255) UNIQUE NOT NULL` – уникальное название языка, обязателен.

3.  **`user_languages`** (Промежуточная таблица для M:N связи между `users` и `languages`)
    *   `user_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `users.id`.
    *   `language_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `languages.id`.
    *   `PRIMARY KEY (user_id, language_id)`: Композитный первичный ключ, обеспечивающий уникальность пары (пользователь, язык) и предотвращающий дублирование связей.
    *   `FOREIGN KEY ... ON DELETE CASCADE`: При удалении пользователя или языка, соответствующие записи в этой таблице будут удалены.

4.  **`collections`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор коллекции (словаря).
    *   `language_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `languages.id`. Указывает язык, к которому принадлежит коллекция. Обязателен.
    *   `creator_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `users.id`. Указывает пользователя, создавшего коллекцию. Обязателен.
    *   `name`: `VARCHAR(255) NOT NULL` – название коллекции, обязателен.

5.  **`words`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор слова/фразы.
    *   `language_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `languages.id`. Указывает язык слова. Обязателен.
    *   `word_text`: `VARCHAR(255) NOT NULL` – само слово или фраза, обязателен.
    *   `translation`: `VARCHAR(255) NOT NULL` – перевод слова/фразы, обязателен.
    *   `transcription`: `VARCHAR(255)` – транскрипция слова, необязательна.

6.  **`collection_words`** (Промежуточная таблица для M:N связи между `collections` и `words`)
    *   `collection_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `collections.id`.
    *   `word_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `words.id`.
    *   `PRIMARY KEY (collection_id, word_id)`: Композитный первичный ключ, обеспечивающий уникальность пары (коллекция, слово).
    *   `FOREIGN KEY ... ON DELETE CASCADE`: Каскадное удаление связей при удалении коллекции или слова.

7.  **`exercise_types`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор типа упражнения.
    *   `name`: `VARCHAR(100) UNIQUE NOT NULL` – уникальное название типа упражнения (например, 'flashcards', 'multiple_choice', 'typing'), обязательно.

8.  **`exercises`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор упражнения.
    *   `exercise_type_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `exercise_types.id`. Указывает тип упражнения. Обязателен.
    *   `exercise_name`: `VARCHAR(255) NOT NULL` – название упражнения.
    *   `difficulty_level`: `VARCHAR(255)` – уровень сложности упражнения, необязателен.

9.  **`exercise_words`** (Промежуточная таблица для M:N связи между `exercises` и `words`)
    *   `exercise_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `exercises.id`.
    *   `word_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `words.id`.
    *   `PRIMARY KEY (exercise_id, word_id)`: Композитный первичный ключ, обеспечивающий уникальность пары (упражнение, слово).
    *   `FOREIGN KEY ... ON DELETE CASCADE`: Каскадное удаление связей при удалении упражнения или слова.

10. **`attempts`**
    *   `id`: `SERIAL PRIMARY KEY` – уникальный идентификатор попытки.
    *   `user_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `users.id`. Указывает пользователя, совершившего попытку. Обязателен.
    *   `exercise_id`: `INT NOT NULL` – внешний ключ, ссылающийся на `exercises.id`. Указывает упражнение, для которого совершена попытка. Обязателен.
    *   `started_at`: `TIMESTAMP NOT NULL` – время начала попытки, обязательно, по умолчанию устанавливается на текущее время.
    *   `completed_at`: `TIMESTAMP` – время окончания попытки, необязательно (попытка может быть еще в процессе).
    *   `score`: `INT CHECK (score >= 0 AND score <= 100)` – результат попытки (баллов от 0 до 100), необязательно, может быть null до завершения попытки, с ограничением, что значение должно быть в диапазоне от 0 до 100.
    *   `FOREIGN KEY ... ON DELETE CASCADE`: Каскадное удаление попыток при удалении пользователя или упражнения.
