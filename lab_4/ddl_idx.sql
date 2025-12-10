CREATE INDEX idx_user_languages_user_id ON user_languages (user_id);
CREATE INDEX idx_user_languages_language_id ON user_languages (language_id);

CREATE INDEX idx_collections_language_id ON collections (language_id);
CREATE INDEX idx_collections_creator_id ON collections (creator_id);
CREATE INDEX idx_collections_name ON collections (name);

CREATE INDEX idx_words_language_id ON words (language_id);
CREATE INDEX idx_words_word_text ON words (word_text);
CREATE INDEX idx_words_translation ON words (translation);

CREATE INDEX idx_collection_words_collection_id ON collection_words (collection_id);
CREATE INDEX idx_collection_words_word_id ON collection_words (word_id);

CREATE INDEX idx_exercises_exercise_type_id ON exercises (exercise_type_id);
CREATE INDEX idx_exercises_exercise_name ON exercises (exercise_name);
CREATE INDEX idx_exercises_difficulty_level ON exercises (difficulty_level);

CREATE INDEX idx_exercise_words_exercise_id ON exercise_words (exercise_id);
CREATE INDEX idx_exercise_words_word_id ON exercise_words (word_id);

CREATE INDEX idx_attempts_user_id ON attempts (user_id);
CREATE INDEX idx_attempts_exercise_id ON attempts (exercise_id);
CREATE INDEX idx_attempts_started_at ON attempts (started_at);
CREATE INDEX idx_attempts_completed_at ON attempts (completed_at);
CREATE INDEX idx_attempts_score ON attempts (score);

-- составные индексы для более специфичных запросов
CREATE INDEX idx_attempts_user_exercise_score ON attempts (user_id, exercise_id, score DESC);
CREATE INDEX idx_collections_language_creator ON collections (language_id, creator_id);
