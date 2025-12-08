import { PrismaService } from '../../prisma';

export interface PaginationParams {
  page?: number;
  pageSize?: number;
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export abstract class BaseRepository {
  constructor(protected readonly prisma: PrismaService) {}

  protected paginate<T>(
    data: T[],
    total: number,
    { page = 1, pageSize = 20 }: PaginationParams
  ): PaginatedResult<T> {
    return {
      data,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  protected getPaginationParams({ page = 1, pageSize = 20 }: PaginationParams) {
    return {
      skip: (page - 1) * pageSize,
      take: pageSize,
    };
  }
}
