// Shared Zod schemas for Haven
import { z } from 'zod';

// Re-export zod for convenience
export { z };

// Household schemas
export const HouseholdIdSchema = z.string().uuid();

// User schemas  
export const UserIdSchema = z.string();

// Common response wrapper
export const ApiResponseSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    success: z.boolean(),
    data: dataSchema.optional(),
    error: z.string().optional(),
  });
