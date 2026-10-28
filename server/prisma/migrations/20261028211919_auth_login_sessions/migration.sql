-- CreateEnum
CREATE TYPE "login_status" AS ENUM ('pending', 'complete', 'failed');

-- CreateTable
CREATE TABLE "auth_login_sessions" (
    "id" UUID NOT NULL,
    "poll_secret_hash" TEXT NOT NULL,
    "code_verifier" TEXT NOT NULL,
    "status" "login_status" NOT NULL DEFAULT 'pending',
    "opened" BOOLEAN NOT NULL DEFAULT false,
    "access_token" TEXT,
    "refresh_token" TEXT,
    "expires_in" INTEGER,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auth_login_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "auth_login_sessions_expires_at_idx" ON "auth_login_sessions"("expires_at");
