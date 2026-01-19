import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type TransactionType =
  // Housing
  | 'mortgage' | 'rent' | 'hoa' | 'propertyTax'
  // Insurance
  | 'homeInsurance' | 'autoInsurance' | 'healthInsurance' | 'lifeInsurance' | 'petInsurance' | 'insurance'
  // Utilities
  | 'electricity' | 'gas' | 'water' | 'sewer' | 'trash' | 'oil' | 'propane'
  // Telecom
  | 'internet' | 'cable' | 'cellPhone' | 'landline'
  // Streaming & Subscriptions
  | 'streaming' | 'music' | 'gaming' | 'software' | 'news' | 'amazon' | 'warehouse' | 'mealKit' | 'petFood'
  // Fitness & Wellness
  | 'gym' | 'fitnessApp' | 'clubMembership'
  // Vehicles
  | 'carPayment' | 'carLease' | 'parking' | 'tolls' | 'carRegistration'
  // Loans & Debt
  | 'studentLoan' | 'personalLoan' | 'heloc' | 'creditCard'
  // Family & Kids
  | 'schoolTuition' | 'college529' | 'childcare' | 'nanny' | 'kidsActivities'
  // Home Services
  | 'landscaping' | 'pool' | 'pestControl' | 'cleaning' | 'windowWashing' | 'gutterCleaning'
  | 'security' | 'snowRemoval' | 'hvacService' | 'plumbing' | 'electrical' | 'homeWarranty'
  // Storage
  | 'storage'
  // Charitable
  | 'charity'
  // Other
  | 'other';

interface AnalyzedTransaction {
  type: TransactionType;
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

  // Complete merchant patterns for ALL possible household bills
  private patterns: Record<string, RegExp[]> = {
    // ==================== HOUSING ====================
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
      /guild\s*mortgage/i,
      /loandepot/i,
      /better\s*mortgage/i,
      /crosscountry/i,
      /homepoint/i,
      /planet\s*home/i,
      /fairway/i,
      /guaranteed\s*rate/i,
      /movement\s*mortgage/i,
      /united\s*wholesale/i,
    ],
    rent: [
      /rent\s*payment/i,
      /apartments\.com/i,
      /zillow.*rent/i,
      /avail.*rent/i,
      /cozy.*rent/i,
      /rentcafe/i,
      /appfolio/i,
      /buildium/i,
      /property.*management/i,
    ],
    hoa: [
      /hoa|homeowner.*assoc/i,
      /condo.*assoc/i,
      /property.*assoc/i,
      /community.*assoc/i,
      /maintenance\s*fee/i,
    ],
    propertyTax: [
      /property\s*tax/i,
      /county\s*tax/i,
      /town\s*of.*tax/i,
      /city\s*of.*tax/i,
      /tax\s*collector/i,
      /assessor/i,
    ],

    // ==================== INSURANCE ====================
    homeInsurance: [
      /state\s*farm/i,
      /allstate/i,
      /liberty\s*mutual/i,
      /travelers/i,
      /nationwide/i,
      /farmers\s*ins/i,
      /usaa/i,
      /amica/i,
      /hartford/i,
      /chubb/i,
      /american\s*family/i,
      /erie\s*insurance/i,
      /auto.*owners/i,
      /safeco/i,
      /homesite/i,
      /lemonade/i,
      /hippo/i,
      /branch\s*insurance/i,
    ],
    autoInsurance: [
      /geico/i,
      /progressive/i,
      /esurance/i,
      /root\s*insurance/i,
      /metromile/i,
    ],
    healthInsurance: [
      /anthem/i,
      /united.*health|uhc|unitedhealthcare/i,
      /cigna/i,
      /aetna/i,
      /kaiser/i,
      /humana/i,
      /bcbs|blue.*cross|blue.*shield/i,
      /oscar.*health/i,
      /centene/i,
      /molina/i,
      /ambetter/i,
      /bright.*health/i,
      /clover.*health/i,
      /devoted.*health/i,
      /medicare/i,
      /medicaid/i,
    ],
    lifeInsurance: [
      /northwestern\s*mutual/i,
      /new\s*york\s*life/i,
      /mass\s*mutual|massmutual/i,
      /prudential.*life/i,
      /metlife/i,
      /lincoln\s*financial/i,
      /principal\s*financial/i,
      /transamerica/i,
      /aflac/i,
      /guardian\s*life/i,
      /haven\s*life/i,
      /ladder.*life/i,
      /bestow/i,
      /ethos\s*life/i,
    ],
    petInsurance: [
      /healthy\s*paws/i,
      /embrace.*pet/i,
      /trupanion/i,
      /nationwide.*pet/i,
      /pets\s*best/i,
      /figo/i,
      /lemonade.*pet/i,
      /spot.*pet/i,
      /pumpkin.*pet/i,
    ],

    // ==================== UTILITIES ====================
    electricity: [
      /eversource/i,
      /united\s*illuminating|^ui\s/i,
      /con\s*edison|coned/i,
      /pseg|pse&g/i,
      /national\s*grid/i,
      /duke\s*energy/i,
      /dominion\s*energy/i,
      /xcel\s*energy/i,
      /aep|american\s*electric/i,
      /southern\s*company/i,
      /entergy/i,
      /firstenergy/i,
      /ppl\s*electric/i,
      /exelon/i,
      /comed/i,
      /peco/i,
      /baltimore\s*gas/i,
      /pg&e|pacific\s*gas/i,
      /sce|socal\s*edison/i,
      /sdge|san\s*diego\s*gas/i,
      /florida\s*power/i,
      /fpl\s/i,
      /georgia\s*power/i,
      /puget\s*sound/i,
      /avista/i,
      /rocky\s*mountain\s*power/i,
      /pacificorp/i,
      /consumers\s*energy/i,
      /dte\s*energy/i,
      /centerpoint/i,
      /oncor/i,
      /evergy/i,
      /ameren/i,
      /alliant\s*energy/i,
      /we\s*energies/i,
      /nv\s*energy/i,
      /tucson\s*electric/i,
      /el\s*paso\s*electric/i,
      /cleco/i,
      /black\s*hills/i,
      /midamerican/i,
    ],
    gas: [
      /eversource.*gas/i,
      /southern\s*ct\s*gas/i,
      /cng|connecticut\s*natural/i,
      /yankee\s*gas/i,
      /atmos\s*energy/i,
      /nicor\s*gas/i,
      /peoples\s*gas/i,
      /spire\s*energy/i,
      /southwest\s*gas/i,
      /washington\s*gas/i,
      /new\s*jersey\s*natural/i,
      /south\s*jersey\s*gas/i,
      /columbia\s*gas/i,
      /centerpoint.*gas/i,
      /piedmont\s*natural/i,
      /northwest\s*natural/i,
      /cascade\s*natural/i,
      /puget.*natural/i,
      /intermountain\s*gas/i,
      /questar\s*gas/i,
      /national\s*fuel/i,
      /berkshire\s*gas/i,
      /liberty\s*utilities.*gas/i,
      /unitil.*gas/i,
      /bay\s*state\s*gas/i,
    ],
    water: [
      /aquarion/i,
      /american\s*water/i,
      /ct\s*water|connecticut\s*water/i,
      /aqua\s*america/i,
      /california\s*water/i,
      /san\s*jose\s*water/i,
      /golden\s*state\s*water/i,
      /middlesex\s*water/i,
      /artesian\s*water/i,
      /york\s*water/i,
      /sjw\s*group/i,
      /essential\s*utilities/i,
      /water\s*service/i,
      /water\s*dept/i,
      /municipal\s*water/i,
      /city.*water/i,
      /town.*water/i,
      /water\s*utility/i,
      /water\s*authority/i,
    ],
    sewer: [
      /sewer/i,
      /wastewater/i,
      /sanitation/i,
      /sewerage/i,
    ],
    trash: [
      /waste\s*management/i,
      /republic\s*services/i,
      /waste.*connections/i,
      /casella/i,
      /advanced\s*disposal/i,
      /waste.*industries/i,
      /gfl\s*environmental/i,
      /rumpke/i,
      /waste\s*pro/i,
      /recology/i,
      /town.*trash|town.*waste/i,
      /city.*trash|city.*waste/i,
      /garbage/i,
      /refuse/i,
      /sanitation.*dept/i,
    ],
    oil: [
      /heating\s*oil/i,
      /fuel\s*oil/i,
      /oil\s*delivery/i,
      /petroleum/i,
      /petro\s*home/i,
      /dead\s*river/i,
      /sprague/i,
      /mirabito/i,
      /global\s*partners/i,
      /rymes/i,
      /eastern\s*propane.*oil/i,
      /shipley\s*energy/i,
      /brickman.*oil/i,
      /superior.*oil/i,
      /meenan\s*oil/i,
      /griffith\s*energy/i,
      /foster\s*fuels/i,
      /valley\s*oil/i,
      /bottini\s*fuel/i,
      /main\s*care\s*energy/i,
    ],
    propane: [
      /propane/i,
      /amerigas/i,
      /ferrellgas/i,
      /suburban\s*propane/i,
      /blue\s*rhino/i,
      /paraco/i,
      /thompson\s*gas/i,
      /chs\s*propane/i,
      /eastern\s*propane/i,
      /hocon\s*gas/i,
    ],

    // ==================== TELECOM ====================
    internet: [
      /comcast|xfinity/i,
      /verizon.*fios|fios/i,
      /at&t.*internet|att.*internet/i,
      /spectrum|charter/i,
      /optimum|altice/i,
      /cox\s*communications/i,
      /frontier\s*communications/i,
      /centurylink|lumen/i,
      /windstream/i,
      /mediacom/i,
      /suddenlink/i,
      /wow\s*internet/i,
      /rcn\s/i,
      /astound/i,
      /earthlink/i,
      /hughesnet/i,
      /viasat/i,
      /starlink/i,
      /t-mobile.*home/i,
      /google\s*fiber/i,
      /ziply\s*fiber/i,
      /consolidated\s*communications/i,
      /metronet/i,
      /breezeline/i,
      /atlantic\s*broadband/i,
    ],
    cable: [
      /directv|direct\s*tv/i,
      /dish\s*network/i,
      /youtube\s*tv/i,
      /hulu.*live/i,
      /sling\s*tv/i,
      /fubo/i,
      /philo/i,
    ],
    cellPhone: [
      /t-mobile/i,
      /verizon\s*wireless/i,
      /at&t\s*wireless|att\s*wireless|at&t\s*mobility/i,
      /sprint/i,
      /mint\s*mobile/i,
      /visible/i,
      /google\s*fi/i,
      /us\s*cellular/i,
      /cricket/i,
      /metro\s*by\s*t-mobile|metropcs/i,
      /boost\s*mobile/i,
      /straight\s*talk/i,
      /consumer\s*cellular/i,
      /ting/i,
      /republic\s*wireless/i,
      /xfinity\s*mobile/i,
      /spectrum\s*mobile/i,
    ],
    landline: [
      /landline/i,
      /home\s*phone/i,
      /voip/i,
      /ooma/i,
      /vonage/i,
      /magicjack/i,
    ],

    // ==================== STREAMING & SUBSCRIPTIONS ====================
    streaming: [
      /netflix/i,
      /hulu(?!\s*live)/i,
      /disney.*plus|disney\+/i,
      /hbo.*max|^max\s/i,
      /paramount.*plus|paramount\+/i,
      /peacock/i,
      /apple\s*tv|apple\s*one/i,
      /amazon.*video|prime\s*video/i,
      /discovery.*plus|discovery\+/i,
      /espn.*plus|espn\+/i,
      /showtime/i,
      /starz/i,
      /crunchyroll/i,
      /curiosity\s*stream/i,
      /mubi/i,
      /criterion/i,
    ],
    music: [
      /spotify/i,
      /apple\s*music/i,
      /amazon\s*music/i,
      /youtube\s*music|youtube\s*premium/i,
      /pandora/i,
      /tidal/i,
      /deezer/i,
      /soundcloud/i,
      /audible/i,
      /sirius.*xm/i,
    ],
    gaming: [
      /xbox.*live|xbox.*game\s*pass/i,
      /playstation.*plus|playstation.*now/i,
      /nintendo.*online/i,
      /ea\s*play/i,
      /ubisoft/i,
      /steam/i,
      /epic\s*games/i,
    ],
    software: [
      /microsoft\s*365|office\s*365/i,
      /adobe/i,
      /dropbox/i,
      /google\s*one|google\s*workspace/i,
      /icloud/i,
      /evernote/i,
      /notion/i,
      /slack/i,
      /zoom/i,
      /lastpass/i,
      /1password/i,
      /nordvpn/i,
      /expressvpn/i,
      /norton/i,
      /mcafee/i,
      /grammarly/i,
      /canva/i,
      /squarespace/i,
      /wix/i,
      /shopify/i,
      /quickbooks/i,
      /turbotax/i,
      /intuit/i,
    ],
    news: [
      /new\s*york\s*times|nytimes/i,
      /wall\s*street\s*journal|wsj/i,
      /washington\s*post/i,
      /the\s*athletic/i,
      /bloomberg/i,
      /economist/i,
      /financial\s*times/i,
      /barrons/i,
      /medium/i,
      /substack/i,
      /patreon/i,
    ],
    amazon: [
      /amazon\s*prime(?!\s*video)/i,
      /prime\s*membership/i,
      /amazon\s*fresh/i,
      /whole\s*foods/i,
    ],
    warehouse: [
      /costco/i,
      /sam.*club/i,
      /bj.*wholesale/i,
    ],
    mealKit: [
      /hello\s*fresh/i,
      /blue\s*apron/i,
      /home\s*chef/i,
      /factor/i,
      /freshly/i,
      /daily\s*harvest/i,
      /sunbasket/i,
      /green\s*chef/i,
      /gobble/i,
      /dinnerly/i,
      /every\s*plate/i,
      /hungryroot/i,
      /tovala/i,
    ],
    petFood: [
      /chewy/i,
      /petco/i,
      /petsmart/i,
      /farmer.*dog/i,
      /nom\s*nom/i,
      /ollie/i,
      /just\s*food.*dogs/i,
      /bark\s*box/i,
    ],

    // ==================== FITNESS & WELLNESS ====================
    gym: [
      /planet\s*fitness/i,
      /la\s*fitness/i,
      /24\s*hour\s*fitness/i,
      /equinox/i,
      /ymca|ywca/i,
      /orangetheory/i,
      /crossfit/i,
      /lifetime\s*fitness/i,
      /gold.*gym/i,
      /anytime\s*fitness/i,
      /crunch\s*fitness/i,
      /blink\s*fitness/i,
      /esporta/i,
      /retro\s*fitness/i,
      /world\s*gym/i,
      /snap\s*fitness/i,
      /athletic\s*club/i,
      /soul\s*cycle/i,
      /barry.*bootcamp/i,
      /f45/i,
      /pure\s*barre/i,
      /core\s*power/i,
      /yoga.*works/i,
    ],
    fitnessApp: [
      /peloton/i,
      /mirror/i,
      /tonal/i,
      /tempo/i,
      /beachbody/i,
      /daily\s*burn/i,
      /fitbit\s*premium/i,
      /apple\s*fitness/i,
      /strava/i,
      /calm/i,
      /headspace/i,
      /noom/i,
      /weight\s*watchers|ww\s/i,
    ],
    clubMembership: [
      /country\s*club/i,
      /golf\s*club/i,
      /tennis\s*club/i,
      /swim\s*club/i,
      /beach\s*club/i,
      /yacht\s*club/i,
    ],

    // ==================== VEHICLES ====================
    carPayment: [
      /toyota\s*financial/i,
      /honda\s*financial/i,
      /ford\s*credit/i,
      /ally\s*(auto|financial)/i,
      /capital\s*one\s*auto/i,
      /chase\s*auto/i,
      /bmw\s*financial/i,
      /mercedes.*financial/i,
      /gm\s*financial/i,
      /chrysler\s*capital/i,
      /hyundai\s*motor\s*finance/i,
      /kia\s*finance/i,
      /nissan\s*motor/i,
      /subaru\s*motors\s*finance/i,
      /vw\s*credit|volkswagen\s*credit/i,
      /audi\s*financial/i,
      /porsche\s*financial/i,
      /lexus\s*financial/i,
      /acura\s*financial/i,
      /mazda\s*financial/i,
      /santander.*auto/i,
      /td\s*auto/i,
      /citizens\s*auto/i,
      /pnc\s*auto/i,
      /exeter\s*finance/i,
      /westlake\s*financial/i,
      /credit\s*acceptance/i,
      /carmax\s*auto/i,
      /carvana/i,
      /vroom/i,
    ],
    carLease: [
      /lease\s*payment/i,
      /us\s*bank.*lease/i,
      /ally.*lease/i,
    ],
    parking: [
      /parking/i,
      /spothero/i,
      /parkwhiz/i,
      /bestparking/i,
      /parkme/i,
      /garage\s*rent/i,
    ],
    tolls: [
      /ez.*pass|ezpass/i,
      /fastrak/i,
      /sunpass/i,
      /i-pass|ipass/i,
      /k-tag/i,
      /pike\s*pass/i,
      /good\s*to\s*go/i,
      /peach\s*pass/i,
      /txtag/i,
      /toll.*road/i,
      /turnpike/i,
    ],

    // ==================== LOANS & DEBT ====================
    studentLoan: [
      /nelnet/i,
      /navient/i,
      /mohela/i,
      /aidvantage/i,
      /great\s*lakes/i,
      /fedloan|fed\s*loan/i,
      /dept.*education/i,
      /sallie\s*mae/i,
      /sofi.*student/i,
      /earnest/i,
      /laurel\s*road/i,
      /commonbond/i,
      /college\s*ave/i,
      /discover.*student/i,
      /citizens.*student/i,
    ],
    personalLoan: [
      /sofi.*personal/i,
      /marcus|goldman.*sachs/i,
      /lightstream/i,
      /upstart/i,
      /prosper/i,
      /lending\s*club/i,
      /best\s*egg/i,
      /payoff/i,
      /avant/i,
      /upgrade/i,
      /happy\s*money/i,
    ],
    heloc: [
      /heloc/i,
      /home\s*equity/i,
      /figure.*heloc/i,
    ],
    creditCard: [
      /chase.*credit|chase.*card/i,
      /amex|american\s*express/i,
      /capital\s*one.*card/i,
      /citi.*card|citibank.*card/i,
      /discover.*card/i,
      /bank\s*of\s*america.*card/i,
      /wells\s*fargo.*card/i,
      /us\s*bank.*card/i,
      /barclays/i,
      /synchrony/i,
      /apple\s*card/i,
    ],

    // ==================== FAMILY & KIDS ====================
    schoolTuition: [
      /tuition/i,
      /school.*payment/i,
      /academy/i,
      /montessori/i,
      /preparatory/i,
      /private\s*school/i,
      /catholic\s*school/i,
      /christian\s*school/i,
      /hebrew\s*school/i,
      /waldorf/i,
    ],
    college529: [
      /529\s*plan/i,
      /college\s*savings/i,
      /fidelity.*529/i,
      /vanguard.*529/i,
      /ny\s*saves/i,
      /utah.*educational/i,
    ],
    childcare: [
      /daycare/i,
      /preschool/i,
      /childcare|child\s*care/i,
      /kindercare/i,
      /bright\s*horizons/i,
      /primrose\s*schools/i,
      /goddard\s*school/i,
      /learning\s*experience/i,
      /lightbridge/i,
      /kiddie\s*academy/i,
      /la\s*petite/i,
      /tutor\s*time/i,
      /care\.com/i,
      /sittercity/i,
      /urbansitter/i,
    ],
    nanny: [
      /nanny/i,
      /au\s*pair/i,
      /cultural\s*care/i,
      /aupaircare/i,
      /breedlove/i,
      /gtm\s*payroll/i,
      /homepayhq/i,
      /payroll.*nanny/i,
    ],
    kidsActivities: [
      /little\s*league/i,
      /ayso|soccer.*assoc/i,
      /ymca.*youth/i,
      /karate|martial\s*arts|taekwondo/i,
      /dance\s*academy|ballet/i,
      /music\s*lesson|piano\s*lesson|guitar\s*lesson/i,
      /swim\s*lesson/i,
      /gymboree/i,
      /my\s*gym/i,
      /the\s*little\s*gym/i,
      /kumon/i,
      /mathnasium/i,
      /sylvan/i,
      /tutoring|tutor/i,
      /camp/i,
      /scouts|boy\s*scout|girl\s*scout/i,
    ],

    // ==================== HOME SERVICES ====================
    landscaping: [
      /landscap/i,
      /lawn\s*(care|service|maint)/i,
      /trugreen/i,
      /scotts.*lawn/i,
      /sunday\s*lawn/i,
      /weed\s*man/i,
      /spring.*green/i,
      /ryan.*lawn/i,
      /lawn\s*doctor/i,
      /grounds.*guys/i,
      /brickman/i,
      /brightview/i,
      /yellowstone/i,
      /davey\s*tree/i,
      /bartlett\s*tree/i,
      /tree.*service/i,
      /arborist/i,
      /mowing/i,
      /grass\s*cutting/i,
      /yard\s*work/i,
    ],
    pool: [
      /pool\s*(service|supply|care|cleaning|maintenance)/i,
      /leslie.*pool/i,
      /pinch\s*a\s*penny/i,
      /pool\s*corp/i,
      /america.*pool/i,
      /pool.*spa/i,
    ],
    pestControl: [
      /orkin/i,
      /terminix/i,
      /pest\s*(control|service|management)/i,
      /rentokil/i,
      /truly\s*nolen/i,
      /western\s*pest/i,
      /ehrlich/i,
      /arrow\s*exterminat/i,
      /home\s*team\s*pest/i,
      /aptive/i,
      /bulwark/i,
      /mosquito\s*joe/i,
      /mosquito\s*squad/i,
      /exterminator/i,
    ],
    cleaning: [
      /maid|merry\s*maids|molly\s*maid/i,
      /cleaning\s*service/i,
      /house.*clean/i,
      /the\s*maids/i,
      /two\s*maids/i,
      /maidpro/i,
      /handy/i,
      /tidy/i,
    ],
    windowWashing: [
      /window.*wash|window.*clean/i,
      /fish\s*window/i,
    ],
    gutterCleaning: [
      /gutter/i,
      /leaf\s*filter/i,
      /leafguard/i,
    ],
    security: [
      /adt/i,
      /vivint/i,
      /simplisafe/i,
      /ring.*protect/i,
      /nest.*aware/i,
      /brinks/i,
      /frontpoint/i,
      /abode/i,
      /cove.*security/i,
      /scout.*alarm/i,
      /link\s*interactive/i,
      /protect\s*america/i,
      /alarm\.com/i,
    ],
    snowRemoval: [
      /snow.*remov/i,
      /snow.*plow/i,
      /ice.*removal/i,
      /winter.*service/i,
    ],
    hvacService: [
      /hvac/i,
      /heating.*cooling/i,
      /air.*condition.*service/i,
      /furnace.*service/i,
      /carrier/i,
      /trane/i,
      /lennox/i,
      /rheem/i,
      /goodman/i,
      /one\s*hour.*heating/i,
      /service\s*experts/i,
    ],
    plumbing: [
      /plumber|plumbing/i,
      /roto.*rooter/i,
      /mr\.*rooter/i,
      /benjamin\s*franklin\s*plumb/i,
      /rescue\s*rooter/i,
    ],
    electrical: [
      /electrician|electrical\s*service/i,
      /mister\s*sparky/i,
      /mr\.*electric/i,
    ],
    homeWarranty: [
      /american\s*home\s*shield/i,
      /choice\s*home\s*warranty/i,
      /select\s*home\s*warranty/i,
      /first\s*american\s*home/i,
      /home\s*warranty.*america/i,
      /ahs\s*warranty/i,
      /2-10.*warranty/i,
      /hwa\s*home/i,
      /landmark\s*home/i,
      /total\s*protect/i,
      /cinch\s*home/i,
    ],

    // ==================== STORAGE ====================
    storage: [
      /public\s*storage/i,
      /extra\s*space/i,
      /cubesmart/i,
      /life\s*storage/i,
      /u-haul.*storage/i,
      /uncle\s*bob/i,
      /iron\s*mountain/i,
      /storage.*unit/i,
      /self.*storage/i,
      /mini.*storage/i,
    ],

    // ==================== CHARITABLE ====================
    charity: [
      /donation/i,
      /charity/i,
      /foundation/i,
      /red\s*cross/i,
      /united\s*way/i,
      /salvation\s*army/i,
      /goodwill/i,
      /habitat.*humanity/i,
      /st\.*jude/i,
      /make.*wish/i,
      /wounded\s*warrior/i,
      /aspca/i,
      /humane\s*society/i,
      /npr|public\s*radio/i,
      /pbs/i,
      /church/i,
      /synagogue/i,
      /mosque/i,
      /tithe|tithing/i,
    ],
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
        ['landscaping', 'pool', 'pestControl', 'cleaning', 'security', 'snowRemoval',
         'hvacService', 'plumbing', 'electrical', 'windowWashing', 'gutterCleaning',
         'homeWarranty', 'storage', 'gym', 'childcare', 'streaming', 'music',
         'gaming', 'software', 'news', 'amazon', 'warehouse', 'mealKit', 'petFood'].includes(
          item.type,
        )
      ) {
        try {
          const category = this.mapTypeToCategory(item.type);
          const frequency = this.mapFrequencyToEnum(item.frequency);

          // Find existing bill for this provider
          const existingBill = await this.prisma.comprehensiveBill.findFirst({
            where: {
              householdId,
              category,
              name: item.provider,
            },
          });

          if (existingBill) {
            await this.prisma.comprehensiveBill.update({
              where: { id: existingBill.id },
              data: {
                amount: item.amount,
                frequency,
              },
            });
          } else {
            await this.prisma.comprehensiveBill.create({
              data: {
                householdId,
                category,
                name: item.provider,
                description: this.getServiceName(item.type),
                amount: item.amount,
                frequency,
                status: 'ACTIVE',
                currentAutopay: false,
              },
            });
          }
        } catch (err) {
          this.logger.warn(`Failed to save bill for ${item.type}: ${err}`);
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
  ): TransactionType {
    const name = merchant.toLowerCase();

    for (const [type, patterns] of Object.entries(this.patterns)) {
      for (const pattern of patterns) {
        if (pattern.test(name)) {
          return type as TransactionType;
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

  private getServiceName(type: TransactionType): string {
    const names: Record<TransactionType, string> = {
      // Housing
      mortgage: 'Mortgage Payment',
      rent: 'Rent Payment',
      hoa: 'HOA Fees',
      propertyTax: 'Property Tax',
      // Insurance
      homeInsurance: 'Home Insurance',
      autoInsurance: 'Auto Insurance',
      healthInsurance: 'Health Insurance',
      lifeInsurance: 'Life Insurance',
      petInsurance: 'Pet Insurance',
      insurance: 'Insurance',
      // Utilities
      electricity: 'Electric Bill',
      gas: 'Gas Bill',
      water: 'Water Bill',
      sewer: 'Sewer Bill',
      trash: 'Trash Collection',
      oil: 'Heating Oil',
      propane: 'Propane',
      // Telecom
      internet: 'Internet Service',
      cable: 'Cable/TV Service',
      cellPhone: 'Cell Phone',
      landline: 'Home Phone',
      // Streaming & Subscriptions
      streaming: 'Streaming Service',
      music: 'Music Service',
      gaming: 'Gaming Subscription',
      software: 'Software Subscription',
      news: 'News Subscription',
      amazon: 'Amazon Prime',
      warehouse: 'Warehouse Membership',
      mealKit: 'Meal Kit Service',
      petFood: 'Pet Food/Supplies',
      // Fitness & Wellness
      gym: 'Gym Membership',
      fitnessApp: 'Fitness App',
      clubMembership: 'Club Membership',
      // Vehicles
      carPayment: 'Car Payment',
      carLease: 'Car Lease',
      parking: 'Parking',
      tolls: 'Tolls',
      carRegistration: 'Car Registration',
      // Loans & Debt
      studentLoan: 'Student Loan',
      personalLoan: 'Personal Loan',
      heloc: 'HELOC Payment',
      creditCard: 'Credit Card Payment',
      // Family & Kids
      schoolTuition: 'School Tuition',
      college529: 'College 529 Savings',
      childcare: 'Childcare',
      nanny: 'Nanny/Au Pair',
      kidsActivities: 'Kids Activities',
      // Home Services
      landscaping: 'Lawn & Landscaping',
      pool: 'Pool Service',
      pestControl: 'Pest Control',
      cleaning: 'House Cleaning',
      windowWashing: 'Window Washing',
      gutterCleaning: 'Gutter Cleaning',
      security: 'Security Monitoring',
      snowRemoval: 'Snow Removal',
      hvacService: 'HVAC Service',
      plumbing: 'Plumbing Service',
      electrical: 'Electrical Service',
      homeWarranty: 'Home Warranty',
      // Storage
      storage: 'Storage Unit',
      // Charitable
      charity: 'Charitable Donation',
      // Other
      other: 'Other',
    };
    return names[type] || type;
  }

  private mapTypeToCategory(type: TransactionType): string {
    const mapping: Record<string, string> = {
      // Housing
      mortgage: 'MORTGAGE',
      rent: 'RENT',
      hoa: 'HOA',
      propertyTax: 'PROPERTY_TAX',
      // Insurance
      homeInsurance: 'HOME_INSURANCE',
      autoInsurance: 'AUTO_INSURANCE',
      healthInsurance: 'HEALTH_INSURANCE',
      lifeInsurance: 'LIFE_INSURANCE',
      petInsurance: 'PET_INSURANCE',
      insurance: 'INSURANCE',
      // Utilities
      electricity: 'ELECTRIC',
      gas: 'GAS',
      water: 'WATER',
      sewer: 'SEWER',
      trash: 'TRASH',
      oil: 'OIL',
      propane: 'PROPANE',
      // Telecom
      internet: 'INTERNET',
      cable: 'CABLE_TV',
      cellPhone: 'CELL_PHONE',
      landline: 'PHONE',
      // Subscriptions
      streaming: 'STREAMING',
      music: 'SUBSCRIPTION',
      gaming: 'SUBSCRIPTION',
      software: 'SOFTWARE',
      news: 'SUBSCRIPTION',
      amazon: 'MEMBERSHIP',
      warehouse: 'MEMBERSHIP',
      mealKit: 'MEAL_KIT',
      petFood: 'PET_SUPPLIES',
      // Fitness
      gym: 'GYM_MEMBERSHIP',
      fitnessApp: 'FITNESS',
      clubMembership: 'CLUB_MEMBERSHIP',
      // Vehicles
      carPayment: 'CAR_PAYMENT',
      carLease: 'CAR_LEASE',
      parking: 'PARKING',
      tolls: 'TOLLS',
      carRegistration: 'CAR_REGISTRATION',
      // Loans
      studentLoan: 'STUDENT_LOAN',
      personalLoan: 'PERSONAL_LOAN',
      heloc: 'HELOC',
      creditCard: 'CREDIT_CARD',
      // Family
      schoolTuition: 'TUITION',
      college529: 'SAVINGS_529',
      childcare: 'CHILDCARE',
      nanny: 'NANNY',
      kidsActivities: 'KIDS_ACTIVITIES',
      // Home Services
      landscaping: 'LAWN_LANDSCAPE',
      pool: 'POOL_SERVICE',
      pestControl: 'PEST_CONTROL',
      cleaning: 'HOUSE_CLEANING',
      windowWashing: 'WINDOW_WASHING',
      gutterCleaning: 'GUTTER_CLEANING',
      security: 'SECURITY_MONITORING',
      snowRemoval: 'SNOW_REMOVAL',
      hvacService: 'HVAC_SERVICE',
      plumbing: 'PLUMBING',
      electrical: 'ELECTRICAL',
      homeWarranty: 'HOME_WARRANTY',
      // Storage
      storage: 'STORAGE',
      // Charitable
      charity: 'CHARITABLE',
    };
    return mapping[type] || 'OTHER_BILL';
  }

  private mapFrequencyToEnum(
    freq: 'monthly' | 'quarterly' | 'annually' | 'one-time',
  ): 'MONTHLY' | 'QUARTERLY' | 'ANNUAL' | 'ONE_TIME' {
    const mapping: Record<string, 'MONTHLY' | 'QUARTERLY' | 'ANNUAL' | 'ONE_TIME'> = {
      monthly: 'MONTHLY',
      quarterly: 'QUARTERLY',
      annually: 'ANNUAL',
      'one-time': 'ONE_TIME',
    };
    return mapping[freq] || 'MONTHLY';
  }
}
