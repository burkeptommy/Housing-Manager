import { z } from 'zod';

export const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  password: z.string().min(8).max(100),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const homeSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  address: z.string().min(1).max(500),
  ownerId: z.string().uuid(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export const createHomeSchema = z.object({
  name: z.string().min(1).max(100),
  address: z.string().min(1).max(500),
});

export const roomTypeSchema = z.enum([
  'living_room',
  'bedroom',
  'bathroom',
  'kitchen',
  'garage',
  'office',
  'basement',
  'attic',
  'other',
]);

export const roomSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  homeId: z.string().uuid(),
  type: roomTypeSchema,
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export const createRoomSchema = z.object({
  name: z.string().min(1).max(100),
  homeId: z.string().uuid(),
  type: roomTypeSchema,
});

export const taskStatusSchema = z.enum(['pending', 'in_progress', 'completed', 'cancelled']);
export const taskPrioritySchema = z.enum(['low', 'medium', 'high', 'urgent']);

export const taskSchema = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  homeId: z.string().uuid(),
  roomId: z.string().uuid().optional(),
  status: taskStatusSchema,
  priority: taskPrioritySchema,
  dueDate: z.coerce.date().optional(),
  assigneeId: z.string().uuid().optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export const createTaskSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  homeId: z.string().uuid(),
  roomId: z.string().uuid().optional(),
  priority: taskPrioritySchema.default('medium'),
  dueDate: z.coerce.date().optional(),
  assigneeId: z.string().uuid().optional(),
});

export const updateTaskSchema = createTaskSchema.partial().extend({
  status: taskStatusSchema.optional(),
});

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

export type UserSchema = z.infer<typeof userSchema>;
export type CreateUserSchema = z.infer<typeof createUserSchema>;
export type LoginSchema = z.infer<typeof loginSchema>;
export type HomeSchema = z.infer<typeof homeSchema>;
export type CreateHomeSchema = z.infer<typeof createHomeSchema>;
export type RoomSchema = z.infer<typeof roomSchema>;
export type CreateRoomSchema = z.infer<typeof createRoomSchema>;
export type TaskSchema = z.infer<typeof taskSchema>;
export type CreateTaskSchema = z.infer<typeof createTaskSchema>;
export type UpdateTaskSchema = z.infer<typeof updateTaskSchema>;
export type PaginationSchema = z.infer<typeof paginationSchema>;
