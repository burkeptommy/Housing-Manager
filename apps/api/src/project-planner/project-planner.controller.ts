import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { PrismaService } from '../prisma';
import {
  ProjectTemplateService,
  EstimationService,
  ProjectIdeaService,
  CommunityIntelligenceService,
  RecommendationService,
} from './services';
import {
  ListTemplatesQueryDto,
  CalculateEstimateDto,
  CreateProjectIdeaDto,
  UpdateProjectIdeaDto,
  ProgressProjectIdeaDto,
  ListProjectIdeasQueryDto,
  ConvertToWorkOrderDto,
  CreateRecommendationRequestDto,
  ListRecommendationRequestsQueryDto,
  UpdateRecommendationRequestStatusDto,
  SubmitVendorSuggestionDto,
  SuggestionFeedbackDto,
} from './dto';

@ApiTags('project-planner')
@Controller('project-planner')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class ProjectPlannerController {
  constructor(
    private readonly templateService: ProjectTemplateService,
    private readonly estimationService: EstimationService,
    private readonly projectIdeaService: ProjectIdeaService,
    private readonly communityIntelligenceService: CommunityIntelligenceService,
    private readonly recommendationService: RecommendationService,
    private readonly prisma: PrismaService,
  ) {}

  // ==================== Templates ====================

  @Get('templates')
  @ApiOperation({ summary: 'List project templates by category' })
  async listTemplates(@Query() query: ListTemplatesQueryDto) {
    return this.templateService.listTemplates(query);
  }

  @Get('templates/by-category')
  @ApiOperation({ summary: 'Get templates grouped by category' })
  async getTemplatesByCategory() {
    return this.templateService.getTemplatesByCategory();
  }

  @Get('templates/categories')
  @ApiOperation({ summary: 'Get category options for wizard' })
  getCategoryOptions() {
    return this.templateService.getCategoryOptions();
  }

  @Get('templates/:id')
  @ApiOperation({ summary: 'Get template details' })
  async getTemplate(@Param('id') id: string) {
    return this.templateService.getTemplate(id);
  }

  // ==================== Estimation ====================

  @Post('estimate')
  @ApiOperation({ summary: 'Calculate project estimate' })
  async calculateEstimate(@Request() req, @Body() dto: CalculateEstimateDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.estimationService.calculateEstimate(dto, householdId);
  }

  @Get('regional-multiplier')
  @ApiOperation({ summary: 'Get regional cost multiplier for user location' })
  async getRegionalMultiplier(@Request() req) {
    const household = await this.prisma.household.findFirst({
      where: {
        members: { some: { id: req.user.uid } },
      },
      select: { h3Index: true },
    });
    return this.estimationService.getRegionalMultiplier(household?.h3Index);
  }

  // ==================== Project Ideas ====================

  @Post('ideas')
  @ApiOperation({ summary: 'Create a new project idea' })
  async createIdea(@Request() req, @Body() dto: CreateProjectIdeaDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.create(req.user.uid, householdId, dto);
  }

  @Get('ideas')
  @ApiOperation({ summary: 'List project ideas (pipeline view)' })
  async listIdeas(@Request() req, @Query() query: ListProjectIdeasQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.list(householdId, query);
  }

  @Get('ideas/stats')
  @ApiOperation({ summary: 'Get pipeline stats for household' })
  async getPipelineStats(@Request() req) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.getPipelineStats(householdId);
  }

  @Get('ideas/:id')
  @ApiOperation({ summary: 'Get project idea details' })
  async getIdea(@Request() req, @Param('id') id: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.getById(id, householdId);
  }

  @Patch('ideas/:id')
  @ApiOperation({ summary: 'Update project idea' })
  async updateIdea(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: UpdateProjectIdeaDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.update(id, householdId, dto);
  }

  @Post('ideas/:id/progress')
  @ApiOperation({ summary: 'Progress idea to new status' })
  async progressIdea(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: ProgressProjectIdeaDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.progressStatus(id, householdId, dto.status);
  }

  @Post('ideas/:id/convert')
  @ApiOperation({ summary: 'Convert idea to work order' })
  async convertToWorkOrder(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: ConvertToWorkOrderDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.projectIdeaService.convertToWorkOrder(id, householdId, dto);
  }

  @Delete('ideas/:id')
  @ApiOperation({ summary: 'Archive project idea' })
  async archiveIdea(@Request() req, @Param('id') id: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    await this.projectIdeaService.archive(id, householdId);
    return { success: true };
  }

  // ==================== Community Intelligence ====================

  @Post('ideas/:id/generate-suggestions')
  @ApiOperation({ summary: 'Generate system vendor suggestions for idea' })
  async generateSuggestions(@Request() req, @Param('id') id: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    // Verify access
    await this.projectIdeaService.getById(id, householdId);
    return this.communityIntelligenceService.generateSystemSuggestions(id);
  }

  @Get('ideas/:id/suggestions')
  @ApiOperation({ summary: 'Get all suggestions for project idea' })
  async getSuggestions(@Request() req, @Param('id') id: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.recommendationService.getSuggestionsForIdea(id, householdId);
  }

  @Get('ideas/:id/inspiration')
  @ApiOperation({ summary: 'Get neighbor inspiration for project category' })
  async getInspiration(
    @Request() req,
    @Param('id') id: string,
    @Query('limit') limit?: number,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    const idea = await this.projectIdeaService.getById(id, householdId);
    return this.communityIntelligenceService.getNeighborInspiration(
      householdId,
      idea.category,
      limit,
    );
  }

  @Get('vendor-signals')
  @ApiOperation({ summary: 'Get vendors with social signals' })
  async getVendorSignals(@Request() req, @Query('category') category?: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.communityIntelligenceService.getVendorSocialSignals(
      req.user.uid,
      householdId,
      category as any,
    );
  }

  // ==================== Recommendation Requests ====================

  @Post('ideas/:id/ask-community')
  @ApiOperation({ summary: 'Create a community ask for recommendations' })
  async createRecommendationRequest(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: Omit<CreateRecommendationRequestDto, 'projectIdeaId'>,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.recommendationService.createRequest(req.user.uid, householdId, {
      ...dto,
      projectIdeaId: id,
    });
  }

  @Get('requests')
  @ApiOperation({ summary: 'List my recommendation requests' })
  async listMyRequests(
    @Request() req,
    @Query() query: ListRecommendationRequestsQueryDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.recommendationService.listMyRequests(householdId, query);
  }

  @Get('requests/nearby')
  @ApiOperation({ summary: 'Get nearby community asks from neighbors' })
  async getNearbyRequests(@Request() req) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.recommendationService.getNearbyRequests(householdId);
  }

  @Patch('requests/:id/status')
  @ApiOperation({ summary: 'Update recommendation request status' })
  async updateRequestStatus(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: UpdateRecommendationRequestStatusDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.recommendationService.updateRequestStatus(id, householdId, dto.status);
  }

  @Post('requests/:id/suggest')
  @ApiOperation({ summary: 'Submit vendor suggestion for a request' })
  async submitSuggestionForRequest(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: Omit<SubmitVendorSuggestionDto, 'recommendationRequestId'>,
  ) {
    return this.recommendationService.submitSuggestion(req.user.uid, {
      ...dto,
      recommendationRequestId: id,
    });
  }

  @Post('suggestions/:id/feedback')
  @ApiOperation({ summary: 'Mark suggestion as helpful or not' })
  async submitSuggestionFeedback(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: SuggestionFeedbackDto,
  ) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    await this.recommendationService.submitFeedback(id, householdId, dto);
    return { success: true };
  }

  // ==================== Helpers ====================

  private async getActiveHouseholdId(userId: string): Promise<string> {
    const membership = await this.prisma.householdMember.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
      },
      select: { householdId: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!membership) {
      throw new Error('No active household found');
    }

    return membership.householdId;
  }
}
