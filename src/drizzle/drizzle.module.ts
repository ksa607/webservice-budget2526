import { Logger, Module, OnModuleDestroy } from '@nestjs/common';
import {
  type DatabaseProvider,
  DrizzleAsyncProvider,
  drizzleProvider,
  InjectDrizzle,
} from './drizzle.provider';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import path from 'node:path';

@Module({
  providers: [...drizzleProvider],
  exports: [DrizzleAsyncProvider],
})
export class DrizzleModule implements OnModuleDestroy {
  private readonly logger = new Logger(DrizzleModule.name);
  constructor(@InjectDrizzle() private readonly db: DatabaseProvider) {}

  async onModuleInit() {
    this.logger.log('⏳ Running migrations...');
    // 👇 3
    await migrate(this.db, {
      migrationsFolder: path.resolve(__dirname, '../../migrations'),
    });
    this.logger.log('✅ Migrations completed!');
  }
  async onModuleDestroy() {
    await this.db.$client.end();
  }
}
