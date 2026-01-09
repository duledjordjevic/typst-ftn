#show raw.where(block: true): set text(size: 8pt)

= Имплементација

У овом поглављу детаљно је описана имплементација _CI/CD pipeline_-а за _streaming_ апликацију, укључујући конфигурацију _AWS_ сервиса, дефинисање инфраструктуре као кода, имплементацију система обавештавања и интеграцију алата за контролу квалитета кода.

== Структура пројекта и _CDK_ апликација

Пројекат је организован као _AWS CDK_ апликација, при чему је инфраструктурни код имплементиран у програмском језику _TypeScript_. Оваква организација омогућава поновљивост, лакше конфигурисање и лакше одржавање _CI/CD pipeline_-а.

=== Организација пројекта

Пројекат је организован у следећу структуру приказану на листингу @tbl:proj-structure:

#figure(
```
infrastructure/
├── bin /
│   └── infrastructure.ts.      // Улазна тачка пројекта
├── lib/
│   ├── cicd-stack.ts           // CI/CD pipeline дефиниција
│   ├── pipeline-stage.ts       // Stage за постављање
│   └── stacks/                 // Апликациони stack-ови
│   └── constructs/             // Апликациони конструкти
├── lambda/
│   └── event-invoked/
│       ├── cicd-notifier.py    // Email notifier Lambda
│       └── cicd-slack-notifier.py // Slack notifier Lambda
├── test/
│   └── unit/                   // Јединични тестови
├── cdk.json                    // CDK конфигурација
└── package.json                // Node.js зависности
```,
  caption: [Структура пројекта.]
)<tbl:proj-structure>


=== Иницијализација _CDK_ апликације

Листинг @lst:infrastructure приказује улазну тачку _CDK_ апликације која креира `CicdStack`:

#figure(
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { CicdStack } from '../lib/cicd-stack';

const app = new cdk.App();

new CicdStack(app, 'CicdStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
  },
});

app.synth();
```,
  caption: [Иницијализација _CDK_ апликације.]
)<lst:infrastructure>

== Имплементација _CI/CD Pipeline Stack_-а

Централна компонента система је `CicdStack` класа која дефинише комплетан _CI/CD pipeline_ користећи _AWS CDK_ конструкте за креирање _CodePipeline_ и _CodeBuild_ ресурса.

Листинг @lst:cicd-class приказује заглавље `CicdStack` класе, која наслеђује `cdk.Stack` класу и представља логичку целину за дефинисање _pipeline_ инфраструктуре. Конструктор класе прима основне параметре неопходне за иницијализацију _stack_-а, након чега се у наставку дефинишу појединачне фазе и кораци _pipeline_-а.

#figure(
```typescript 
export class CicdStack extends cdk.Stack {
    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);
        // ...
```,
    caption: []
)<lst:cicd-class>

=== Креирање _CodePipeline_-а

Листинг @lst:codepipeline приказује креирање _pipeline_-а са дефиницијом извора кода и фазе синтезе:

#figure(
```typescript
const pipeline = new CodePipeline(this, 'Pipeline', {
    pipelineName: 'Pipeline',
    synth: new ShellStep('Synth', {
        input: CodePipelineSource.gitHub(
            'duledjordjevic/streamio', 
            'develop'
        ),
        commands: [
            'cd infrastructure',
            'npm ci',
            'npx cdk synth',
        ],
        primaryOutputDirectory: 'infrastructure/cdk.out'
    })
});
```,
  caption: [Креирање _CodePipeline_-а са _GitHub_ извором]
)<lst:codepipeline>

_CodePipeline_ конструкт аутоматски генерише _AWS CodePipeline_ ресурс који укључује фазе за преузимање кода, синтезу _CloudFormation_ шаблона и самоажурирање _pipeline_-а.

Извор кода конфигурисан је као _GitHub_ репозиторијум са гране `develop`, чиме се омогућава аутоматско покретање _pipeline_-а при свакој промени кода у дефинисаној развојној грани.

Фаза синтезе извршава `cdk synth` команду, којом се TypeScript дефиниције инфраструктуре трансформишу у _CloudFormation_ шаблоне. На овај начин обезбеђује се да је инфраструктура као код увек репродуктивна и верзионисана заједно са апликационим изворним кодом.

=== Интеграција _SonarQube_ анализе

_SonarQube_ анализа имплементирана је као `CodeBuildStep` који се извршава пре постављања у развојно окружење. Конфигурација анализе приказана је на листингу @lst:sonarqube.

Током извршавања _CodeBuild_ корака, у радном окружењу се динамички преузима и распакује алат `sonar-scanner`. Након распакивања, путања до извршне датотеке додаје се у системску променљиву `PATH`, што омогућава једноставно покретање алата у наставку процеса.

Сам процес анализе иницира се командом `sonar-scanner`, којом се врши локална анализа изворног кода у оквиру _CodeBuild_ окружења. Анализа обухвата проверу квалитета кода, откривање потенцијалних грешака, безбедносних рањивости и одступања од дефинисаних правила. Резултати анализе се након тога шаљу ка _SonarQube_ серверу, где се централизовано обрађују и приказују кориснику.

Аутентификација према _SonarQube_ платформи реализована је коришћењем приступног токена (`SONAR_TOKEN`). Овај токен се безбедно чува у сервису _AWS Secrets Manager_ и током извршавања _CodeBuild_ пројекта динамички се умета као променљива окружења. На овај начин се избегава чување осетљивих података у изворном коду или конфигурационим датотекама, чиме се постиже усклађеност са најбољим безбедносним праксама.

У случају да дефинисани услови _quality gate_-а нису испуњени, pipeline се прекида, чиме се спречава да код који не задовољава задате стандарде буде даље постављен у циљно окружење.

#show raw.where(block: true): set text(size: 7pt)

#figure(
```typescript
const sonarToken = secretsmanager.Secret.fromSecretNameV2(this, 'SonarToken', 'sonarqube-token');
const sonarQubeStep = new CodeBuildStep('SonarQube Analysis', {
    commands: [
        'curl --create-dirs -sSLo $HOME/.sonar/sonar-scanner.zip $SONAR_SCANNER_URL',
        'unzip -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/',
        'export PATH=$SONAR_SCANNER_HOME/bin:$PATH',

        'sonar-scanner ' +
        '-Dsonar.projectKey=$SONAR_PROJECT_KEY ' +
        '-Dsonar.organization=$SONAR_ORGANIZATION ' +
        '-Dsonar.sources=. ' +
        '-Dsonar.host.url=$SONAR_HOST_URL ' +
        '-Dsonar.token=$SONAR_TOKEN ' +
        '-Dsonar.qualitygate.wait=true ' +
        '-Dsonar.ws.timeout=300'
    ],
    buildEnvironment: {
        environmentVariables: {
            SONAR_TOKEN: {
                type: cdk.aws_codebuild.BuildEnvironmentVariableType.SECRETS_MANAGER,
                value: sonarToken.secretArn  
            }, 
            SONAR_SCANNER_URL: { 
                value: 'https://binaries.sonarsource.com/Distribution/sonar-scanner-cli-7.2.0.5079-linux-x64.zip' 
            },
            SONAR_SCANNER_HOME: { value: '/root/.sonar/sonar-scanner-7.2.0.5079-linux-x64' },
            SONAR_PROJECT_KEY: { value: 'duledjordjevic_streamio' },
            SONAR_ORGANIZATION: { value: 'duledjordjevic' },
            SONAR_HOST_URL: { value: 'https://sonarcloud.io' }
        }
    }
});
```,
  caption: [Конфигурација _SonarQube_ анализе.],
)<lst:sonarqube>


#show raw.where(block: true): set text(size: 8pt)

=== Интеграција јединичних тестова

Јединични тестови се извршавају паралелно са _SonarQube_ анализом. Листинг @lst:unit-tests приказује _CodeBuildStep_ у коме се извршавају јединични тестови:

#figure(
```typescript
devStage.addPre(new CodeBuildStep('unit tests', {
    commands: [
        'cd infrastructure/test/unit',
        'pip install -r requirements.txt',   
        'pytest -q test_upload_url.py',
    ],
     buildEnvironment: {
        environmentVariables: {
            MOVIES_BUCKET: { value: 'streamio-movies-bucket' },
            METADATA_TABLE: { value: 'StreamioMetadata' },
            // остале променљиве....
        }
    }
}));
```,
  caption: [Интеграција јединичних тестова у _pipeline_.]
)<lst:unit-tests>

Тестови су написани у _Python_-у користећи _pytest_ радни оквир и симулирају развојно _AWS_ окружење постављањем одговарајућих променљивих окружења.

// #pagebreak()

=== Дефинисање _deployment_ фаза

_Pipeline_ укључује три окружења (развојно, тестно и продукционо) са различитим нивоима контроле. Свако окружење представља засебан _AWS_ налог или изоловану групу ресурса. Листинг @lst:deployment-stages приказује дефиницију свих фаза:

#figure(
```typescript
// Развојно окружење - аутоматско постављање
const devStage = pipeline.addStage(
    new PipelineStage(this, 'PipelineDevStage', {
        stageName: 'dev'
    })
);

devStage.addPre(sonarQubeStep);
devStage.addPre(unitTestsStep);

// Тестно окружење - са ручним одобрењем
const qaStage = pipeline.addStage(
    new PipelineStage(this, 'PipelineQAStage', {
        stageName: 'qa'
    })
);
qaStage.addPre(new cdk.pipelines.ManualApprovalStep('ApproveQA'));

// Продукционо окружење - са ручним одобрењем
const prodStage = pipeline.addStage(
    new PipelineStage(this, 'PipelineProdStage', {
        stageName: 'prod'
    })
);
prodStage.addPre(new cdk.pipelines.ManualApprovalStep('ApproveProd'));
```,
  caption: [Дефинисање _deployment_ фаза.]
)<lst:deployment-stages>

Метода `addPre()` додаје кораке који се извршавају пре постављања у одређено окружење. Када се више корака дода помоћу `addPre()`, они се извршавају паралелно, чиме се убрзава процес. `ManualApprovalStep` креира паузу за ручну проверу и одобрење, при чему овлашћена особа прегледа промене преко _AWS_ конзоле пре наставка _pipeline_-а.

Развојно окружење се аутоматски ажурира након успешних провера квалитета (_SonarQube_ и јединични тестови), док тестно и продукционо окружење захтевају ручно одобрење како би се обезбедила додатна контрола над променама.

#pagebreak()

== Имплементација система обавештавања

Систем обавештавања омогућава тиму да прати статус _pipeline_-а у реалном времену преко _Slack_-а и имејла. Овај систем је критичан за брзу реакцију на проблеме.

=== _EventBridge_ правила за детекцију догађаја

_AWS EventBridge_ прати промене у _AWS_ сервисима и покреће акције на основу унапред дефинисаних правила. У овој имплементацији, правила су конфигурисана да детектују промене у _CodePipeline_ и _CodeBuild_ сервисима. Листинг @lst:eventbridge приказује дефиницију _EventBridge_ правила:

#figure(
```typescript
new events.Rule(this, 'CodePipelineFailedRule', {
    description: 'Notify on failed pipeline executions',
    eventPattern: {
        source: ['aws.codepipeline'],
        detailType: ['CodePipeline Pipeline Execution State Change'],
        detail: {
            state: ['FAILED'],
            pipeline: ['Pipeline'],              
        },
    },
    targets: [new targets.LambdaFunction(notifierFn)],
});

new events.Rule(this, 'CodeBuildFailedRule', {
    description: 'Notify on failed codebuild builds',
    eventPattern: {
        source: ['aws.codebuild'],
        detailType: ['CodeBuild Build State Change'],
        detail: {
            'build-status': ['FAILED']
        },
    },
    targets: [new targets.LambdaFunction(notifierFn)],
});
```,
  caption: [_EventBridge_ правила за детекцију неуспеха.]
)<lst:eventbridge>

Параметар `eventPattern` дефинише филтер који одређује који догађаји ће активирати правило. Одвојена правила за _CodePipeline_ и _CodeBuild_ обезбеђују да тим буде обавештен о неуспесима на свим нивоима _CI/CD_ процеса, јер неуспеси у _CodeBuild_ фазама не морају увек означити неуспех целог _pipeline_-а.

=== _Slack_ интеграција

_Slack_ обавештења имплементирана су помоћу _webhook_ механизма. _Webhook URL_ се безбедно чува у _AWS Secrets Manager_-у уместо у изворном коду, чиме се спречава изложеност осетљивих података. _Lambda_ функција добија дозволу за читање помоћу `grantRead()` методе, која аутоматски креира одговарајућу _IAM_ политику. Када _EventBridge_ детектује релевантан догађај, активира _Lambda_ функцију која форматира и шаље поруку у _Slack_ канал. Листинг @lst:slack-integration приказује _Slack_ интеграцију са _pipeline_-ом:

#figure(
```typescript
const slackWebhookUrl = secretsmanager.Secret.fromSecretNameV2(
    this, 
    'slackWebhookUrl', 
    'slack-webhook-url'
);

const slackNotifier = new lambda.Function(this, 'SlackNotifier', {
    runtime: lambda.Runtime.PYTHON_3_11,
    handler: 'cicd-slack-notifier.handler',
    timeout: cdk.Duration.seconds(20),
    code: lambda.Code.fromAsset( 
        path.join(__dirname, '../lambda/event-invoked')
    ),
    environment: {
        SLACK_WEBHOOK_URL: slackWebhookUrl.secretValue.unsafeUnwrap()
    }
});

slackWebhookUrl.grantRead(slackNotifier);
```,
  caption: [_Slack_ интеграција помоћу _webhook_ механизма.]
)<lst:slack-integration>


=== Имејл обавештења

Имејл обавештења користе _SNS_ сервис за дистрибуцију порука. Листинг @lst:email-notifications приказује интеграцију имејл обавештења:

#figure(
```typescript
const emailNotifyTopic = new sns.Topic(this, 
    'PipelineNotificationsTopic', {
    displayName: 'Pipeline notifications (streamio)',
    topicName: 'streamio-pipeline-notifications',
});

emailNotifyTopic.addSubscription(
    new subs.EmailSubscription('djordjevicdusan24@gmail.com')
);

const notifierFn = new lambda.Function(this, "NotifierFn", {
    runtime: lambda.Runtime.PYTHON_3_11,
    handler: 'cicd-notifier.handler',
    code: lambda.Code.fromAsset(
        path.join(__dirname, '../lambda/event-invoked')
    ),
    environment: {
        TARGET_TOPIC: emailNotifyTopic.topicArn
    }
});

emailNotifyTopic.grantPublish(notifierFn);
```,
  caption: [Интеграција имејл обавештења преко _SNS_ теме.]
)<lst:email-notifications>

_SNS_ тема служи као централна тачка за дистрибуцију порука, омогућавајући да више претплатника прима исте поруке. _Lambda_ функција добија дозволу за објављивање порука на _SNS_ тему помоћу `grantPublish()` методе. Систем користи две одвојене _Lambda_ функције: _Slack_ обавештења шаљу се за све промене стања _pipeline_-а (покретање, успех, неуспех), док се имејл обавештења шаљу само за неуспехе.


