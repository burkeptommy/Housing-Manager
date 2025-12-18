import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ProjectCategory } from '@prisma/client';
import { ProjectTemplateDto, ListTemplatesQueryDto } from '../dto';

@Injectable()
export class ProjectTemplateService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * List project templates, optionally filtered by category
   */
  async listTemplates(query: ListTemplatesQueryDto): Promise<ProjectTemplateDto[]> {
    const templates = await this.prisma.projectTemplate.findMany({
      where: {
        ...(query.category ? { category: query.category } : {}),
        ...(query.activeOnly !== false ? { isActive: true } : {}),
      },
      orderBy: [
        { category: 'asc' },
        { sortOrder: 'asc' },
        { name: 'asc' },
      ],
    });

    return templates.map(this.mapToDto);
  }

  /**
   * Get a single template by ID
   */
  async getTemplate(id: string): Promise<ProjectTemplateDto | null> {
    const template = await this.prisma.projectTemplate.findUnique({
      where: { id },
    });

    if (!template) return null;
    return this.mapToDto(template);
  }

  /**
   * Get templates grouped by category for wizard display
   */
  async getTemplatesByCategory(): Promise<Record<ProjectCategory, ProjectTemplateDto[]>> {
    const templates = await this.prisma.projectTemplate.findMany({
      where: { isActive: true },
      orderBy: [
        { category: 'asc' },
        { sortOrder: 'asc' },
      ],
    });

    const grouped = {} as Record<ProjectCategory, ProjectTemplateDto[]>;

    for (const template of templates) {
      if (!grouped[template.category]) {
        grouped[template.category] = [];
      }
      grouped[template.category].push(this.mapToDto(template));
    }

    return grouped;
  }

  /**
   * Get category options for the wizard
   */
  getCategoryOptions(): Array<{ value: ProjectCategory; label: string; description: string }> {
    return [
      { value: 'BATHROOM_REMODEL', label: 'Bathroom Remodel', description: 'Update your bathroom from simple refresh to full renovation' },
      { value: 'KITCHEN_REMODEL', label: 'Kitchen Remodel', description: 'Transform your kitchen space' },
      { value: 'DECK_PATIO', label: 'Deck & Patio', description: 'Create outdoor living spaces' },
      { value: 'LANDSCAPING', label: 'Landscaping', description: 'Enhance your outdoor areas' },
      { value: 'ROOF', label: 'Roofing', description: 'Roof replacement or major repairs' },
      { value: 'WINDOWS_DOORS', label: 'Windows & Doors', description: 'Replace or upgrade windows and doors' },
      { value: 'FLOORING', label: 'Flooring', description: 'Install new floors throughout your home' },
      { value: 'PAINTING', label: 'Painting', description: 'Interior and exterior painting' },
      { value: 'HVAC', label: 'HVAC', description: 'Heating and cooling system work' },
      { value: 'ELECTRICAL', label: 'Electrical', description: 'Electrical upgrades and repairs' },
      { value: 'PLUMBING', label: 'Plumbing', description: 'Plumbing repairs and upgrades' },
      { value: 'ADDITION', label: 'Home Addition', description: 'Add new space to your home' },
      { value: 'BASEMENT', label: 'Basement', description: 'Finish or renovate your basement' },
      { value: 'GARAGE', label: 'Garage', description: 'Garage construction or renovation' },
      { value: 'FENCE', label: 'Fencing', description: 'Install or replace fencing' },
      { value: 'POOL', label: 'Pool', description: 'Pool installation or renovation' },
      { value: 'SOLAR', label: 'Solar', description: 'Solar panel installation' },
      { value: 'SMART_HOME', label: 'Smart Home', description: 'Home automation and smart devices' },
      { value: 'EXTERIOR_SIDING', label: 'Exterior Siding', description: 'Siding replacement or repair' },
      { value: 'OTHER', label: 'Other', description: 'Other home improvement projects' },
    ];
  }

  private mapToDto(template: any): ProjectTemplateDto {
    return {
      id: template.id,
      slug: template.slug,
      category: template.category,
      name: template.name,
      description: template.description,
      baseMaterialCost: Number(template.baseMaterialCost),
      laborHoursPerSqFt: template.laborHoursPerSqFt ? Number(template.laborHoursPerSqFt) : undefined,
      baseLaborRate: Number(template.baseLaborRate),
      complexityFactors: template.complexityFactors as Record<string, number> | undefined,
      minSqFt: template.minSqFt,
      maxSqFt: template.maxSqFt,
      estimatedDaysMin: template.estimatedDaysMin,
      estimatedDaysMax: template.estimatedDaysMax,
      inspirationImages: template.inspirationImages,
      isActive: template.isActive,
      sortOrder: template.sortOrder,
    };
  }
}
