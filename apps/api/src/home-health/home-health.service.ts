import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface HealthFactor {
  category: string;
  name: string;
  impact: number; // positive or negative points
  status: 'positive' | 'negative' | 'neutral';
  description: string;
  recommendation?: string;
}

export interface HomeHealthScore {
  score: number;
  maxScore: number;
  grade: 'Excellent' | 'Good' | 'Fair' | 'Needs Attention' | 'Critical';
  factors: HealthFactor[];
  recommendations: string[];
}

@Injectable()
export class HomeHealthService {
  private readonly logger = new Logger(HomeHealthService.name);

  constructor(private prisma: PrismaService) {}

  async calculateHealthScore(householdId: string): Promise<HomeHealthScore> {
    const factors: HealthFactor[] = [];
    let score = 100; // Start at 100, deduct for issues

    try {
      // Get all relevant data
      const [maintenanceTasks, approvalRequests, documents, household] =
        await Promise.all([
          this.prisma.maintenanceTask.findMany({ where: { householdId } }),
          this.prisma.approvalRequest
            .findMany({ where: { householdId } })
            .catch(() => []),
          this.prisma.document.findMany({ where: { householdId } }).catch(() => []),
          this.prisma.household.findUnique({
            where: { id: householdId },
            include: { homeProfile: true },
          }),
        ]);

      // === MAINTENANCE FACTORS ===
      const overdueTasks = maintenanceTasks.filter((t) => t.status === 'OVERDUE');
      const upcomingTasks = maintenanceTasks.filter(
        (t) => t.status === 'UPCOMING' || t.status === 'SCHEDULED' || t.status === 'DUE_SOON',
      );
      const completedTasks = maintenanceTasks.filter((t) => t.status === 'COMPLETED');

      if (overdueTasks.length > 0) {
        const deduction = Math.min(overdueTasks.length * 5, 25); // Max 25 point deduction
        score -= deduction;
        factors.push({
          category: 'Maintenance',
          name: 'Overdue Tasks',
          impact: -deduction,
          status: 'negative',
          description: `${overdueTasks.length} maintenance task${overdueTasks.length > 1 ? 's are' : ' is'} overdue`,
          recommendation: `Complete overdue tasks: ${overdueTasks.slice(0, 3).map((t) => t.title).join(', ')}`,
        });
      } else {
        factors.push({
          category: 'Maintenance',
          name: 'No Overdue Tasks',
          impact: 5,
          status: 'positive',
          description: 'All maintenance tasks are up to date',
        });
        score = Math.min(score + 5, 100);
      }

      // Check for critical maintenance categories
      const criticalCategories = ['HVAC', 'PLUMBING', 'ELECTRICAL', 'ROOF_GUTTER', 'SAFETY'];
      const lastYearDate = new Date();
      lastYearDate.setFullYear(lastYearDate.getFullYear() - 1);

      for (const category of criticalCategories) {
        const categoryTasks = completedTasks.filter(
          (t) =>
            t.category === category &&
            t.completedAt &&
            new Date(t.completedAt) > lastYearDate,
        );

        if (categoryTasks.length === 0) {
          const hasCategoryTasks = maintenanceTasks.some((t) => t.category === category);
          if (hasCategoryTasks || category === 'HVAC' || category === 'SAFETY') {
            score -= 3;
            factors.push({
              category: 'Maintenance',
              name: `${this.formatCategory(category)} Service`,
              impact: -3,
              status: 'negative',
              description: `No ${this.formatCategory(category).toLowerCase()} maintenance completed in the past year`,
              recommendation: `Schedule ${this.formatCategory(category).toLowerCase()} inspection or service`,
            });
          }
        }
      }

      // === APPROVAL FACTORS ===
      const pendingApprovals = approvalRequests.filter((a) => a.status === 'PENDING');
      const urgentApprovals = pendingApprovals.filter(
        (a) => a.priority === 'HIGH' || a.priority === 'URGENT',
      );

      if (urgentApprovals.length > 0) {
        score -= urgentApprovals.length * 3;
        factors.push({
          category: 'Approvals',
          name: 'Urgent Pending Approvals',
          impact: -urgentApprovals.length * 3,
          status: 'negative',
          description: `${urgentApprovals.length} urgent approval${urgentApprovals.length > 1 ? 's' : ''} waiting`,
          recommendation: 'Review and respond to urgent approvals',
        });
      }

      if (pendingApprovals.length > 5) {
        score -= 5;
        factors.push({
          category: 'Approvals',
          name: 'Backlog',
          impact: -5,
          status: 'negative',
          description: `${pendingApprovals.length} pending approvals need attention`,
          recommendation: 'Review pending approvals to prevent maintenance delays',
        });
      }

      // === SEASONAL FACTORS ===
      const currentMonth = new Date().getMonth() + 1;

      // Winter prep (Sept-Nov)
      if ([9, 10, 11].includes(currentMonth)) {
        const winterTasks = ['furnace', 'heating', 'winterize', 'chimney', 'insulation'];
        const hasWinterPrep = completedTasks.some(
          (t) =>
            winterTasks.some((w) => t.title.toLowerCase().includes(w)) &&
            t.completedAt &&
            new Date(t.completedAt) > new Date(new Date().getFullYear(), 6, 1),
        );

        if (!hasWinterPrep) {
          score -= 5;
          factors.push({
            category: 'Seasonal',
            name: 'Winter Preparation',
            impact: -5,
            status: 'negative',
            description: 'No winter preparation tasks completed this fall',
            recommendation: 'Schedule furnace service, chimney sweep, and winterization',
          });
        }
      }

      // Spring prep (March-May)
      if ([3, 4, 5].includes(currentMonth)) {
        const springTasks = ['ac', 'cooling', 'gutter', 'roof inspection', 'spring'];
        const hasSpringPrep = completedTasks.some(
          (t) =>
            springTasks.some((s) => t.title.toLowerCase().includes(s)) &&
            t.completedAt &&
            new Date(t.completedAt) > new Date(new Date().getFullYear(), 0, 1),
        );

        if (!hasSpringPrep) {
          score -= 5;
          factors.push({
            category: 'Seasonal',
            name: 'Spring Preparation',
            impact: -5,
            status: 'negative',
            description: 'No spring preparation tasks completed',
            recommendation: 'Schedule AC service, gutter cleaning, and roof inspection',
          });
        }
      }

      // === DOCUMENT FACTORS ===
      const hasDocuments = documents.length > 0;

      if (!hasDocuments) {
        factors.push({
          category: 'Documents',
          name: 'Document Vault',
          impact: -2,
          status: 'negative',
          description: 'No documents uploaded to the vault',
          recommendation: 'Upload important documents like insurance policies, warranties, and home records',
        });
        score -= 2;
      } else {
        factors.push({
          category: 'Documents',
          name: 'Document Vault Active',
          impact: 2,
          status: 'positive',
          description: `${documents.length} document${documents.length > 1 ? 's' : ''} stored in vault`,
        });
      }

      // === POSITIVE FACTORS ===
      if (upcomingTasks.length > 0) {
        factors.push({
          category: 'Maintenance',
          name: 'Proactive Planning',
          impact: 3,
          status: 'positive',
          description: `${upcomingTasks.length} maintenance task${upcomingTasks.length > 1 ? 's' : ''} scheduled`,
        });
        score = Math.min(score + 3, 100);
      }

      if (completedTasks.length >= 5) {
        factors.push({
          category: 'Maintenance',
          name: 'Maintenance History',
          impact: 5,
          status: 'positive',
          description: `${completedTasks.length} tasks completed - great track record!`,
        });
        score = Math.min(score + 5, 100);
      }

      // === CALCULATE GRADE ===
      score = Math.max(0, Math.min(100, score));

      let grade: HomeHealthScore['grade'];
      if (score >= 90) grade = 'Excellent';
      else if (score >= 75) grade = 'Good';
      else if (score >= 60) grade = 'Fair';
      else if (score >= 40) grade = 'Needs Attention';
      else grade = 'Critical';

      // Generate top recommendations
      const recommendations = factors
        .filter((f) => f.status === 'negative' && f.recommendation)
        .sort((a, b) => a.impact - b.impact) // Most negative first
        .slice(0, 5)
        .map((f) => f.recommendation!);

      return {
        score,
        maxScore: 100,
        grade,
        factors,
        recommendations,
      };
    } catch (error) {
      this.logger.error('Error calculating health score:', error);
      return {
        score: 75,
        maxScore: 100,
        grade: 'Good',
        factors: [],
        recommendations: ['Unable to calculate detailed health score'],
      };
    }
  }

  private formatCategory(category: string): string {
    const formats: Record<string, string> = {
      HVAC: 'HVAC',
      PLUMBING: 'Plumbing',
      ELECTRICAL: 'Electrical',
      ROOF_GUTTER: 'Roof & Gutter',
      SAFETY: 'Safety',
    };
    return formats[category] || category;
  }
}
