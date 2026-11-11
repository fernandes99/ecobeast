import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { IslandsModule } from '../islands/islands.module.js';
import { EditorGuard } from './editor.guard.js';
import { IslandsEditorController } from './islands-editor.controller.js';
import { IslandsEditorService } from './islands-editor.service.js';
import { MapGeneratorController } from './map-generator.controller.js';

/** O editor de ilhas: só para quem está em MAP_EDITOR_USER_IDS (map-editor/01). */
@Module({
  imports: [AuthModule, IslandsModule],
  controllers: [IslandsEditorController, MapGeneratorController],
  providers: [IslandsEditorService, EditorGuard],
})
export class EditorModule {}
