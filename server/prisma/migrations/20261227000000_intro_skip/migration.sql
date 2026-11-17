-- Quem já tem um Ecobeast pula a introdução de Liora (.specs/liora-intro/architecture.md#as-contas-antigas).

INSERT INTO "ecobeasts"."player_story_marks" ("player_id", "mark")
SELECT DISTINCT "player_id", 'introducao_pulada' FROM "ecobeasts"."creature_instances"
ON CONFLICT DO NOTHING;
