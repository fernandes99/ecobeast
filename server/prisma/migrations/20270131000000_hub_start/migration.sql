-- O jogo abre no Hub, sem a ilha casa (.specs/hub-start/01-hub.md). Liora continua publicada e pode voltar a ser a casa pelo F2.

UPDATE "ecobeasts"."islands" SET "is_home" = false WHERE "is_home";
