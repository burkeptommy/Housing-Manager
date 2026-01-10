import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface AnalyzedTransaction {
  type:
    | 'mortgage'
    | 'insurance'
    | 'electricity'
    | 'gas'
    | 'water'
    | 'sewer'
    | 'oil'
    | 'propane'
    | 'internet'
    | 'cable'
    | 'landscaping'
    | 'pool'
    | 'pest-control'
    | 'cleaning'
    | 'security'
    | 'other';
  provider: string;
  amount: number;
  frequency: 'monthly' | 'quarterly' | 'annually' | 'one-time';
  confidence: number;
  transactionIds: string[];
}

@Injectable()
export class TransactionAnalyzerService {
  private readonly logger = new Logger(TransactionAnalyzerService.name);

  constructor(private prisma: PrismaService) {}

  // Merchant name patterns for categorization
  private patterns: Record<string, RegExp[]> = {
    mortgage: [
      /quicken|rocket\s*mortgage/i,
      /wells\s*fargo.*mtg|wells\s*fargo.*mortgage/i,
      /chase.*mortgage|jpmorgan.*mtg/i,
      /bank\s*of\s*america.*mtg|boa.*mortgage/i,
      /us\s*bank.*mortgage/i,
      /pnc.*mortgage/i,
      /citizens.*mortgage/i,
      /mr\s*cooper/i,
      /pennymac/i,
      /freedom\s*mortgage/i,
      /loancare/i,
      /nationstar/i,
      /caliber\s*home/i,
      /newrez/i,
    ],
    insurance: [
      /state\s*farm/i,
      /allstate/i,
      /geico/i,
      /progressive/i,
      /liberty\s*mutual/i,
      /travelers/i,
      /nationwide/i,
      /farmers\s*ins/i,
      /usaa/i,
      /amica/i,
      /hartford/i,
      /chubb/i,
    ],
    electricity: [
      /eversource/i,
      /united\s*illuminating|^ui\s/i,
      /con\s*edison|coned/i,
      /pseg|pse&g/i,
      /national\s*grid/i,
      /duke\s*energy/i,
    ],
    gas: [
      /eversource.*gas/i,
      /southern\s*ct\s*gas/i,
      /cng|connecticut\s*natural/i,
      /yankee\s*gas/i,
    ],
    water: [/aquarion/i, /american\s*water/i, /ct\s*water|connecticut\s*water/i],
    oil: [
      /oil|fuel|petroleum|energy.*oil/i,
      /petro/i,
      /dead\s*river/i,
      /sprague/i,
      /mirabito/i,
    ],
    propane: [/propane/i, /amerigas/i, /ferrellgas/i, /suburban\s*propane/i],
    internet: [
      /comcast|xfinity/i,
      /verizon.*fios|fios/i,
      /at&t|att.*internet/i,
      /spectrum|charter/i,
      /optimum|altice/i,
    ],
    landscaping: [/landscap/i, /lawn\s*(care|service|maint)/i, /trugreen/i],
    pool: [/pool\s*(service|supply|care|cleaning)/i, /leslie.*pool/i],
    'pest-control': [/orkin/i, /terminix/i, /pest\s*(control|service)/i],
    cleaning: [/maid|merry\s*maids|molly\s*maid/i, /cleaning\s*service/i],
    security: [/adt/i, /vivint/i, /simplisafe/i, /ring.*protect/i],
  };

  async analyzeTransactions(
    householdId: string,
    transactions: any[],
  ): Promise<AnalyzedTransaction[]> {
    const analyzed: AnalyzedTransaction[] = [];
    const groupedByMerchant: Record<string, any[]> = {};

    // Group transactions by merchant
    for (const tx of transactions) {
      const merchantKey = this.normalizeMerchant(tx.merchant_name || tx.name);
      if (!merchantKey) continue;

      if (!groupedByMerchant[merchantKey]) {
        groupedByMerchant[merchantKey] = [];
      }
      groupedByMerchant[merchantKey].push(tx);
    }

    // Analyze each merchant group
    for (const [merchant, txs] of Object.entries(groupedByMerchant)) {
      const type = this.categorizeTransaction(merchant, txs[0]);
      if (type === 'other') continue;

      const amounts = txs.map((t) => Math.abs(t.amount));
      const avgAmount = amounts.reduce((a, b) => a + b, 0) / amounts.length;
      const frequency = this.detectFrequency(txs);

      analyzed.push({
        type,
        provider: this.cleanMerchantName(merchant),
        amount: Math.round(avgAmount * 100) / 100,
        frequency,
        confidence: this.calculateConfidence(type, txs, avgAmount),
        transactionIds: txs.map((t) => t.transaction_id),
      });
    }

    this.logger.log(
      `Analyzed ${transactions.length} transactions, found ${analyzed.length} categorized items`,
    );
    return analyzed;
  }

  async applyAnalysisToHousehold(
    householdId: string,
    analysis: AnalyzedTransaction[],
  ) {
    const updates: any = {
      plaidDataAnalyzed: true,
    };

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredDataGaps: true },
    });

    let dataGaps = (household?.alfredDataGaps as string[]) || [];
    dataGaps = dataGaps.filter((g) => g !== 'plaid_analysis_pending');

    for (const item of analysis) {
      if (item.confidence < 0.6) continue;

      switch (item.type) {
        case 'mortgage':
          updates.mortgageProvider = item.provider;
          updates.mortgageMonthlyPayment = item.amount;
          updates.mortgageDetectedAt = new Date();
          break;

        case 'insurance':
          updates.insuranceProvider = item.provider;
          updates.insurancePaymentAmount = item.amount;
          updates.insurancePaymentFreq = item.frequency;
          updates.insuranceDetectedAt = new Date();
          break;

        case 'electricity':
          updates.electricityProvider = item.provider;
          updates.electricityConfirmed = true;
          break;

        case 'gas':
          updates.gasProvider = item.provider;
          updates.gasConfirmed = true;
          break;

        case 'water':
          updates.waterProvider = item.provider;
          updates.waterSource = 'municipal';
          updates.waterSourceConfirmed = true;
          dataGaps = dataGaps.filter((g) => g !== 'water_source');
          break;

        case 'oil':
          updates.heatingFuelProvider = item.provider;
          dataGaps = dataGaps.filter((g) => g !== 'oil_provider');
          break;

        case 'propane':
          updates.heatingFuelProvider = item.provider;
          dataGaps = dataGaps.filter((g) => g !== 'propane_provider');
          break;

        case 'internet':
          updates.internetProvider = item.provider;
          break;

        case 'cable':
          updates.cableProvider = item.provider;
          break;
      }

      // Create comprehensive bills for service providers
      if (
        ['landscaping', 'pool', 'pest-control', 'cleaning', 'security'].includes(
          item.type,
        )
      ) {
        try {
          await this.prisma.comprehensiveBill.upsert({
            where: {
              householdId_type_provider: {
                householdId,
                type: this.mapTypeToCategory(item.type),
                provider: item.provider,
              },
            },
            create: {
              householdId,
              type: this.mapTypeToCategory(item.type),
              provider: item.provider,
              description: this.getServiceName(item.type),
              amount: item.amount,
              frequency: this.mapFrequencyToEnum(item.frequency),
              source: 'PLAID_DETECTED',
              status: 'ACTIVE',
              isAutoPay: false,
            },
            update: {
              amount: item.amount,
              frequency: this.mapFrequencyToEnum(item.frequency),
            },
          });
        } catch (err) {
          this.logger.warn(`Failed to upsert bill for ${item.type}: ${err}`);
        }
      }
    }

    // Infer no water bill = likely well
    const hasWaterBill = analysis.some((a) => a.type === 'water');
    if (!hasWaterBill && !updates.waterSourceConfirmed) {
      if (!dataGaps.includes('water_source_no_bill')) {
        dataGaps.push('water_source_no_bill');
      }
    }

    // Infer no sewer bill = likely septic
    const hasSewerBill = analysis.some((a) => a.type === 'sewer');
    if (!hasSewerBill) {
      if (!dataGaps.includes('sewer_type_no_bill')) {
        dataGaps.push('sewer_type_no_bill');
      }
    }

    updates.alfredDataGaps = dataGaps;

    await this.prisma.household.update({
      where: { id: householdId },
      data: updates,
    });

    this.logger.log(
      `Applied analysis to household ${householdId}, updated fields: ${Object.keys(updates).join(', ')}`,
    );

    return analysis;
  }

  // Helper methods
  private normalizeMerchant(name: string): string {
    return (name || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private cleanMerchantName(merchant: string): string {
    return merchant
      .split(' ')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }

  private categorizeTransaction(
    merchant: string,
    tx: any,
  ): AnalyzedTransaction['type'] {
    const name = merchant.toLowerCase();

    for (const [type, patterns] of Object.entries(this.patterns)) {
      for (const pattern of patterns) {
        if (pattern.test(name)) {
          return type as AnalyzedTransaction['type'];
        }
      }
    }

    return 'other';
  }

  private detectFrequency(transactions: any[]): AnalyzedTransaction['frequency'] {
    if (transactions.length < 2) return 'one-time';

    const dates = transactions.map((t) => new Date(t.date).getTime()).sort();
    let totalDays = 0;
    for (let i = 1; i < dates.length; i++) {
      totalDays += (dates[i] - dates[i - 1]) / (1000 * 60 * 60 * 24);
    }
    const avgDays = totalDays / (dates.length - 1);

    if (avgDays <= 35) return 'monthly';
    if (avgDays <= 100) return 'quarterly';
    if (avgDays <= 400) return 'annually';
    return 'one-time';
  }

  private calculateConfidence(
    type: string,
    transactions: any[],
    avgAmount: number,
  ): number {
    let confidence = 0.5;

    if (transactions.length >= 6) confidence += 0.2;
    else if (transactions.length >= 3) confidence += 0.1;

    const amounts = transactions.map((t) => Math.abs(t.amount));
    const avg = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = Math.sqrt(
      amounts.reduce((sum, n) => sum + Math.pow(n - avg, 2), 0) / amounts.length,
    );

    if (variance < 10) confidence += 0.15;
    else if (variance < 50) confidence += 0.05;

    if (['mortgage', 'electricity', 'gas'].includes(type)) {
      confidence += 0.1;
    }

    return Math.min(confidence, 0.95);
  }

  private getServiceName(type: string): string {
    const names: Record<string, string> = {
      landscaping: 'Lawn & Landscaping',
      pool: 'Pool Service',
      'pest-control': 'Pest Control',
      cleaning: 'House Cleaning',
      security: 'Security Monitoring',
    };
    return names[type] || type;
  }

  private mapTypeToCategory(type: string): string {
    const mapping: Record<string, string> = {
      landscaping: 'SERVICE',
      pool: 'SERVICE',
      'pest-control': 'SERVICE',
      cleaning: 'SERVICE',
      security: 'SERVICE',
    };
    return mapping[type] || 'OTHER';
  }

  private mapFrequencyToEnum(
    freq: 'monthly' | 'quarterly' | 'annually' | 'one-time',
  ): string {
    const mapping: Record<string, string> = {
      monthly: 'MONTHLY',
      quarterly: 'QUARTERLY',
      annually: 'ANNUALLY',
      'one-time': 'ONE_TIME',
    };
    return mapping[freq] || 'MONTHLY';
  }
}
