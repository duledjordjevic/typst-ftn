#import "@preview/touying:0.6.1": *
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

= Континуирана интеграција и испорука сервиса без серверских инстанци на AWS платформи

Душан Ђорђевић \
\

Завршни рад
\
2025

== Мотивација и циљ


#slide[
  #set text(size: 23pt)

  #grid(
    columns: (1fr),
    column-gutter: 1em,
    [
      - аутоматизација процеса развоја и постављања _streaming_ апликације
      - елиминација ручних и грешкама подложних корака
      - омогућавање честих и поузданих испорука
      - рано откривање грешака кроз аутоматске провере
      - обезбеђивање конзистентности између окружења
      - дефинисање инфраструктуре као кода
    ]
  )
]

= Теоријске основе

== Безсерверска (енгл. _serverless_) архитектура

#slide[
  #grid(
    columns: (1fr), 

    [
      - нема трајно активне инфраструктуре
      - плаћање само за коришћене ресурсе
      - аутоматско скалирање
      - догађајно оријентисан модел
    ],
  )
]

#slide[ 
  #figure(
    image("./slike/serverless_vs_serverfull.png", width: 65%),
  )
]

== Континуирана интеграција и испорука (енгл._CI/CD_)


#slide[
  #set text(size: 18pt)

  #grid(
    columns: (1fr, 0.7fr), 
    rows: (auto, auto),
    column-gutter: 1em,

    [
      === Континуирана интеграција (_CI_)
      - често интегрисање измена
      - аутоматско грађење
      - јединични тестови
      - статичка анализа кода
    ],
    [
       === Континуирана испорука (_CD_)
      - аутоматско постављање
      - више окружења (_DEV_, _TEST_, _PROD_)
      - ручна одобрења
      - брз опоравак (_rollback_)
    ],
    grid.cell(
      colspan: 2,
      align(
        center,
        pad(
          right: 3cm,
          image("./slike/cicd.png", width: 40%)
        )
      )
    ),
  )
]

= Архитектура 

#figure(
    image("./slike/ci-cd-stack-horizontal.png", width: 90%),
)

= Имплементација система

== Технологије

#slide[
  #set text(size: 22pt)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,

    [
      - _AWS CDK_ (_TypeScript_) 
      - _AWS CLI_ 
      - _GitHub_ 
      - _SonarQube_ 
      - _pytest_ 
      - _Slack_ 
    ],
    image("./slike/tehnologije.png", width: 100%)
  )
]

== Структура пројекта

#slide[
  #set text(size: 18pt)

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,

    [
      #figure(
        ```
        infrastructure/
        ├── bin/
        │   └── infrastructure.ts
        ├── lib/
        │   ├── cicd-stack.ts
        │   ├── pipeline.ts
        │   └── stacks/
        ├── lambda/
        │   └── event-invoked/
        ├── test/unit/
        ├── cdk.json
        └── package.json
        ```
      )
    ],
    [
      - *bin\/* - улазна тачка _CDK_ апликације
      - *lib\/* - дефиниције _stack_-ова
      - *lambda\/* - _Lambda_ функције
      - *test\/unit\/* - јединични тестови
      - *cdk.json* - _CDK_ конфигурација
      - *package.json* - зависности
   ]
  )
]

== Креирање _CodePipeline_-а

#slide[
  #set text(size: 18pt)

  #figure(
  ```typescript
  const pipeline = new CodePipeline(this, 'Pipeline', {
      pipelineName: 'Pipeline',
      synth: new ShellStep('Synth', {
          input: CodePipelineSource.gitHub(
              'duledjordjevic/streamio', 
              'main'
          ),
          commands: [
              'cd infrastructure',
              'npm ci',
              'npx cdk synth',
          ],
          primaryOutputDirectory: 'infrastructure/cdk.out'
      })
  });
  ```
  )
]

== _SonarQube_ интеграција

#slide[
  #set text(size: 15pt)

  #figure(
  ```typescript
  const sonarToken = secretsmanager.Secret.fromSecretNameV2(
      this, 'SonarToken', 'sonarqube-token'  
  );

  const sonarQubeStep = new CodeBuildStep('SonarQube Analysis', {
      commands: [
          'export SONAR_SCANNER_VERSION=7.2.0.5079',
          // ... преузимање SonarQube Scanner-а
          'sonar-scanner -Dsonar.projectKey=... -Dsonar.token=$SONAR_TOKEN'
      ],
      buildEnvironment: {
          environmentVariables: {
              SONAR_TOKEN: {
                  type: BuildEnvironmentVariableType.SECRETS_MANAGER,
                  value: sonarToken.secretArn  
              }
          }
      }
  });
  ```
  )
]


== Дефинисање окружења
#slide[
  #set text(size: 15pt)

  #figure(
  ```typescript
  const devStage = pipeline.addStage(
      new PipelineStage(this, 'PipelineDevStage', { stageName: 'dev' })
  );
  devStage.addPre(sonarQubeStep);
  devStage.addPre(unitTestsStep);

  const qaStage = pipeline.addStage(
      new PipelineStage(this, 'PipelineQAStage', { stageName: 'qa' })
  );
  qaStage.addPre(new ManualApprovalStep('ApproveQA'));

  const prodStage = pipeline.addStage(
      new PipelineStage(this, 'PipelineProdStage', { stageName: 'prod' })
  );
  prodStage.addPre(new ManualApprovalStep('ApproveProd'));
  ```
  )
]

== Систем обавештавања

#slide[
  #set text(size: 18pt)
  
  === _EventBridge_ правила
  - праћење _CodePipeline_ догађаја (_STARTED_, _SUCCEEDED_, _FAILED_)
  - праћење _CodeBuild_ неуспеха
  - активирање _Lambda_ функција
  
  === Канали обавештавања
  - *_Slack_* - све промене стања _pipeline_-а, боја према статусу
  - *_Email_* - само критични неуспеси преко _SNS_ теме
]

= Закључак

#slide[
  #set text(size: 20pt)

  #grid(
    columns: (1fr, 1.0fr, 1.5fr),
    column-gutter: 1em,
    
    [      
      === Предности
      - аутоматизација процеса
      - доследност и поновљивост
      - брзо обавештавање о грешкама
      - лако праћење статуса
    ],

    [
      === Мане
      - зависност од AWS услуга
      - време извршавања _pipeline_-а
    ],

    [
      === Могућа унапређења
      - аутоматизовани интеграциони тестови у тест окружењу
      - додатне метрике и алармирање (_CloudWatch_, _X-Ray_\...)
      - _canary deployment_ стратегија
      - _blue-green deployment_
      - логовање и праћење (_ELK Stack_, _CloudWatch Logs_\...)
    ]
  )
]

= Хвала на пажњи

Питања? \
