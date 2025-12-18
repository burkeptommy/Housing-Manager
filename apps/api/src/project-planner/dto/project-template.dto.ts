import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ProjectCategory } from '@prisma/client';

export class ProjectTemplateDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  slug: string;

  @ApiProperty({ enum: ProjectCategory })
  category: ProjectCategory;

  @ApiProperty()
  name: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiProperty()
  baseMaterialCost: number;

  @ApiPropertyOptional()
  laborHoursPerSqFt?: number;

  @ApiProperty()
  baseLaborRate: number;

  @ApiPropertyOptional()
  complexityFactors?: Record<string, number>;

  @ApiPropertyOptional()
  minSqFt?: number;

  @ApiPropertyOptional()
  maxSqFt?: number;

  @ApiPropertyOptional()
  estimatedDaysMin?: number;

  @ApiPropertyOptional()
  estimatedDaysMax?: number;

  @ApiProperty({ type: [String] })
  inspirationImages: string[];

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  sortOrder: number;
}

export class ListTemplatesQueryDto {
  @ApiPropertyOptional({ enum: ProjectCategory })
  category?: ProjectCategory;

  @ApiPropertyOptional({ default: true })
  activeOnly?: boolean;
}
