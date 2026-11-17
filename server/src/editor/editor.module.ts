import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { BundleModule } from '../catalog/bundle/bundle.module.js';
import { IslandsModule } from '../islands/islands.module.js';
import { EditorGuard } from './editor.guard.js';
import { IslandsEditorController } from './islands-editor.controller.js';
import { IslandsEditorService } from './islands-editor.service.js';
import { MapGeneratorController } from './map-generator.controller.js';
import { NpcsEditorController } from './npcs-editor.controller.js';
import { NpcsEditorService } from './npcs-editor.service.js';
import { PropTypesEditorController } from './prop-types-editor.controller.js';
import { PropTypesEditorService } from './prop-types-editor.service.js';
import { SkillsEditorController } from './skills-editor.controller.js';
import { SkillsEditorService } from './skills-editor.service.js';

@Module({
  imports: [AuthModule, BundleModule, IslandsModule],
  controllers: [
    IslandsEditorController,
    MapGeneratorController,
    NpcsEditorController,
    PropTypesEditorController,
    SkillsEditorController,
  ],
  providers: [
    IslandsEditorService,
    NpcsEditorService,
    PropTypesEditorService,
    SkillsEditorService,
    EditorGuard,
  ],
})
export class EditorModule {}
