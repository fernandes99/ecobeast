-- skill-editor/03: o alvo "Meu time" (um Ecobeast do próprio lado, o autor incluído) e o Banho de Sol nele.
INSERT INTO "ecobeasts"."skill_targets" ("id", "slug", "name") VALUES (4, 'ally', 'Meu time');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_targets"', 'id'), GREATEST((SELECT max("id") FROM "ecobeasts"."skill_targets"), (SELECT last_value FROM "ecobeasts"."skill_targets_id_seq")));
UPDATE "ecobeasts"."skills" SET "skill_target_id" = 4 WHERE "slug" = 'banho_de_sol';
