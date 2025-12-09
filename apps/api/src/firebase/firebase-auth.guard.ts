import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Inject,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import * as admin from 'firebase-admin';
import { FIREBASE_APP } from './firebase.module';
import { PrismaService } from '../prisma';
import { IS_PUBLIC_KEY } from '../auth/decorators/public.decorator';

export interface AuthenticatedRequest extends Request {
  user: AuthPayload;
  household?: {
    id: string;
    name: string;
    subscriptionPlan: string;
    subscriptionStatus: string;
  };
  householdMembership?: {
    id: string;
    role: string;
    status: string;
  };
}

export interface AuthPayload {
  userId: string;
  firebaseUid: string;
  email: string;
  role: string;
  householdId: string | null;
  householdRole: string | null;
  memberships: Array<{
    householdId: string;
    role: string;
    status: string;
    householdName: string;
  }>;
}

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(FirebaseAuthGuard.name);

  constructor(
    @Inject(FIREBASE_APP) private readonly firebaseApp: admin.app.App,
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if route is public
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization header');
    }

    const idToken = authHeader.substring(7);

    try {
      // Verify Firebase ID token
      const decodedToken = await this.firebaseApp.auth().verifyIdToken(idToken);

      // Look up or create user
      const user = await this.findOrCreateUser(decodedToken);

      // Load household memberships
      const memberships = await this.prisma.householdMember.findMany({
        where: {
          userId: user.id,
          status: 'ACTIVE',
        },
        include: {
          household: {
            select: {
              id: true,
              name: true,
              subscriptionPlan: true,
              subscriptionStatus: true,
            },
          },
        },
      });

      // Get primary household (first active membership or null)
      const primaryMembership = memberships[0];

      // Build auth payload
      const authPayload: AuthPayload = {
        userId: user.id,
        firebaseUid: user.firebaseUid!,
        email: user.email,
        role: user.role,
        householdId: primaryMembership?.householdId ?? null,
        householdRole: primaryMembership?.role ?? null,
        memberships: memberships.map((m) => ({
          householdId: m.householdId,
          role: m.role,
          status: m.status,
          householdName: m.household.name,
        })),
      };

      // Attach to request
      request.user = authPayload;

      // Also maintain backward compatibility with legacy format
      // Some existing guards/services expect this format
      (request as any).auth = {
        userId: user.id,
        householdId: primaryMembership?.householdId ?? null,
        roles: memberships.map((m) => m.role),
      };

      return true;
    } catch (error) {
      this.logger.error('Firebase auth error:', error);
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private async findOrCreateUser(decodedToken: admin.auth.DecodedIdToken) {
    const { uid, email, name, picture } = decodedToken;

    if (!email) {
      throw new UnauthorizedException('Email is required');
    }

    // Try to find by Firebase UID first
    let user = await this.prisma.user.findUnique({
      where: { firebaseUid: uid },
    });

    if (user) {
      // Update last login
      await this.prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });
      return user;
    }

    // Try to find by email (for migrating existing users)
    user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (user) {
      // Link Firebase UID to existing user
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          firebaseUid: uid,
          lastLoginAt: new Date(),
          emailVerified: decodedToken.email_verified ?? false,
          emailVerifiedAt: decodedToken.email_verified ? new Date() : null,
          avatarUrl: user.avatarUrl || picture,
        },
      });
      return user;
    }

    // Create new user
    this.logger.log(`Creating new user for Firebase UID: ${uid}`);
    user = await this.prisma.user.create({
      data: {
        firebaseUid: uid,
        email,
        displayName: name || email.split('@')[0],
        firstName: name?.split(' ')[0] || null,
        lastName: name?.split(' ').slice(1).join(' ') || null,
        avatarUrl: picture,
        emailVerified: decodedToken.email_verified ?? false,
        emailVerifiedAt: decodedToken.email_verified ? new Date() : null,
        lastLoginAt: new Date(),
      },
    });

    return user;
  }
}
