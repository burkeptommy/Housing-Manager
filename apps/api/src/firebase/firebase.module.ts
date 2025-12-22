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
        const emulatorHost = configService.get<string>('FIREBASE_AUTH_EMULATOR_HOST');

        // Check if using emulator
        if (emulatorHost) {
          this.logger.log(`Using Firebase Auth Emulator at ${emulatorHost}`);
          // Set the environment variable for Firebase Admin SDK
          process.env.FIREBASE_AUTH_EMULATOR_HOST = emulatorHost;

          if (admin.apps.length === 0) {
            return admin.initializeApp({
              projectId: configService.get<string>('FIREBASE_PROJECT_ID') || 'demo-project',
            });
          }
          return admin.app();
        }

        // Try to use FIREBASE_SERVICE_ACCOUNT JSON first (Cloud Run style)
        const serviceAccountJson = configService.get<string>('FIREBASE_SERVICE_ACCOUNT');
        if (serviceAccountJson) {
          try {
            const serviceAccount = JSON.parse(serviceAccountJson);
            this.logger.log(`Initializing Firebase from service account JSON for project: ${serviceAccount.project_id}`);
            if (admin.apps.length === 0) {
              return admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
              });
            }
            return admin.app();
          } catch (e) {
            this.logger.error('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', e);
          }
        }

        // Try individual environment variables
        const projectId = configService.get<string>('FIREBASE_PROJECT_ID');
        const clientEmail = configService.get<string>('FIREBASE_CLIENT_EMAIL');
        const privateKey = configService.get<string>('FIREBASE_PRIVATE_KEY');

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

        // Fallback: try application default credentials (works on GCP)
        this.logger.log('Initializing Firebase with application default credentials');
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
