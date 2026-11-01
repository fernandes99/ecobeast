-- A taxa de captura passa a ir de 0 a 100. A restrição é escrita à mão, e o Prisma não a acompanha.
ALTER TABLE "ecobeasts"."species"
  DROP CONSTRAINT "species_capture_rate_check",
  ADD CONSTRAINT "species_capture_rate_check" CHECK ("capture_rate" BETWEEN 0 AND 100);
