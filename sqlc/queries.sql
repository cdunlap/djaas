-- name: GetRandomJoke :one
SELECT id, setup, punchline, category, created_at, updated_at
FROM jokes
ORDER BY RANDOM()
LIMIT 1;

-- name: SearchJokes :one
SELECT id, setup, punchline, category, created_at, updated_at
FROM jokes
WHERE setup ILIKE '%' || $1 || '%'
   OR punchline ILIKE '%' || $1 || '%'
ORDER BY RANDOM()
LIMIT 1;

-- name: GetJokeByCategory :one
SELECT id, setup, punchline, category, created_at, updated_at
FROM jokes
WHERE category = $1
ORDER BY RANDOM()
LIMIT 1;

-- name: GetJokeByCategoryAndSearch :one
SELECT id, setup, punchline, category, created_at, updated_at
FROM jokes
WHERE category = $1
  AND (setup ILIKE '%' || $2 || '%' OR punchline ILIKE '%' || $2 || '%')
ORDER BY RANDOM()
LIMIT 1;

-- name: CreateJoke :one
INSERT INTO jokes (setup, punchline, category)
VALUES ($1, $2, $3)
RETURNING id, setup, punchline, category, created_at, updated_at;

-- name: GetJokeByID :one
SELECT id, setup, punchline, category, created_at, updated_at
FROM jokes
WHERE id = $1;
