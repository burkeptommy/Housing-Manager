import { UserRole } from '@prisma/client';

export class UserResponseDto {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string | null;
  avatarUrl: string | null;
  role: UserRole;
  emailVerified: boolean;
  createdAt: Date;
}

export class HouseholdResponseDto {
  id: string;
  name: string;
  description: string | null;
  role: string;
}

export class AuthResponseDto {
  user: UserResponseDto;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export class TokenResponseDto {
  accessToken: string;
  expiresIn: number;
}

export class MeResponseDto {
  user: UserResponseDto;
  households: HouseholdResponseDto[];
}
