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

-- name: GetTagsForJoke :many
SELECT t.name
FROM tags t
INNER JOIN joke_tags jt ON t.id = jt.tag_id
WHERE jt.joke_id = $1
ORDER BY t.name;

-- name: GetJokeByTags :one
SELECT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
FROM jokes j
WHERE j.id IN (
    SELECT DISTINCT jt.joke_id
    FROM joke_tags jt
    INNER JOIN tags t ON jt.tag_id = t.id
    WHERE t.name = ANY($1::text[])
)
ORDER BY RANDOM()
LIMIT 1;

-- name: GetJokeByTagsAndCategory :one
SELECT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
FROM jokes j
WHERE j.category = $2
  AND j.id IN (
    SELECT DISTINCT jt.joke_id
    FROM joke_tags jt
    INNER JOIN tags t ON jt.tag_id = t.id
    WHERE t.name = ANY($1::text[])
)
ORDER BY RANDOM()
LIMIT 1;

-- name: GetJokeByTagsAndSearch :one
SELECT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
FROM jokes j
WHERE j.id IN (
    SELECT DISTINCT jt.joke_id
    FROM joke_tags jt
    INNER JOIN tags t ON jt.tag_id = t.id
    WHERE t.name = ANY($1::text[])
)
  AND (j.setup ILIKE '%' || $2 || '%' OR j.punchline ILIKE '%' || $2 || '%')
ORDER BY RANDOM()
LIMIT 1;

-- name: GetJokeByAllFilters :one
SELECT j.id, j.setup, j.punchline, j.category, j.created_at, j.updated_at
FROM jokes j
WHERE j.category = $2
  AND j.id IN (
    SELECT DISTINCT jt.joke_id
    FROM joke_tags jt
    INNER JOIN tags t ON jt.tag_id = t.id
    WHERE t.name = ANY($1::text[])
)
  AND (j.setup ILIKE '%' || $3 || '%' OR j.punchline ILIKE '%' || $3 || '%')
ORDER BY RANDOM()
LIMIT 1;

-- name: GetAllTags :many
SELECT name
FROM tags
ORDER BY name ASC;

-- name: CreateTag :one
INSERT INTO tags (name)
VALUES ($1)
ON CONFLICT (name) DO NOTHING
RETURNING id, name, created_at;

-- name: GetTagByName :one
SELECT id, name, created_at
FROM tags
WHERE name = $1;

-- name: AddJokeTag :exec
INSERT INTO joke_tags (joke_id, tag_id)
VALUES ($1, $2)
ON CONFLICT (joke_id, tag_id) DO NOTHING;
