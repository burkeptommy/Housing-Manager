import { Module, Global, DynamicModule, Logger } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

export const FIREBASE_APP = 'FIREBASE_APP';

@Global()
@Module({})
export class FirebaseModule {
  private static readonly logger = new Logger(FirebaseModule.name);

  static forRoot(): DynamicModule {
    const firebaseProvider = {
      provide: FIREBASE_APP,
      inject: [ConfigService],
      useFactory: (configService: ConfigService): admin.app.App => {
        const projectId = configService.get<string>('FIREBASE_PROJECT_ID');
        const clientEmail = configService.get<string>('FIREBASE_CLIENT_EMAIL');
        const privateKey = configService.get<string>('FIREBASE_PRIVATE_KEY');

        // If running in GCP with default credentials
        if (!projectId && !clientEmail && !privateKey) {
          this.logger.log('Initializing Firebase with application default credentials');
          if (admin.apps.length === 0) {
            return admin.initializeApp();
          }
          return admin.app();
        }

        // Use explicit credentials
        if (projectId && clientEmail && privateKey) {
          this.logger.log(`Initializing Firebase for project: ${projectId}`);
          if (admin.apps.length === 0) {
            return admin.initializeApp({
              credential: admin.credential.cert({
                projectId,
                clientEmail,
                // Handle escaped newlines in private key
                privateKey: privateKey.replace(/\\n/g, '\n'),
              }),
            });
          }
          return admin.app();
        }

        // Fallback: try default credentials anyway
        this.logger.warn('Firebase credentials not fully configured, attempting default credentials');
        if (admin.apps.length === 0) {
          return admin.initializeApp();
        }
        return admin.app();
      },
    };

    return {
      module: FirebaseModule,
      imports: [ConfigModule],
      providers: [firebaseProvider],
      exports: [firebaseProvider],
    };
  }
}
