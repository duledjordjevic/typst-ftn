#let format_strane = "a4"         // могуће вредности: iso-b5, a4
#let naslov = "Континуирана интеграција и испорука сервиса без серверских инстанци на AWS платформи"
#let autor = "Душан Ђорђевић"

// На енглеском
#let naslov_eng = "Continuous Integration and Continuous Delivery of serverless services on the AWS platform"
#let autor_eng = "Dušan Đorđević"

#let indeks = "SV 1/2021"

// Име и презиме ментора
#let mentor = "Мирослав Зарић"
// Звање: редовни професор, ванредни професор, доцент
#let mentor_zvanje = "редовни професор"

// Скинути коментаре са одговарајућих линија
#let studijski_program = "Софтверско инжењерство и информационе технологије"
//#let studijski_program = "Рачунарство и аутоматика"
#let stepen = "Основне академске студије"
//#let stepen = "Основне академске студије"

#let godina = [#datetime.today().year()]

#let kljucne_reci = "Континуирана интеграција и испорука, безсерверска архитектура, микросервиси, инфраструктура као код"
#let apstrakt = [
    Овај рад бави се дизајном и имплементацијом континуиране интеграције
    и испоруке у AWS окружењу, са циљем аутоматизације процеса изградње, тестирања и постављања апликација.
    Као пример практичне примене, коришћена је безсерверска streaming апликација
    над којом је примењен процес континуиране интеграције и испоруке ради илустрације интеграције појединих фаза процеса.
    Инфраструктура је дефинисана коришћењем AWS Cloud Development Kit (CDK) алата,
    док је процес континуиране интеграције и испоруке реализован помоћу AWS CodePipeline и CodeBuild
    сервиса. Резултат рада је поуздан и проширив процес испоруке који омогућава
    контролисано и безбедно постављање апликацијe у више окружења.
]

// На енглеском
#let kljucne_reci_eng = "CI/CD, serverless architecture, microservices, infrastructure as a code"
#let apstrakt_eng = [
    This thesis focuses on the design and implementation of a CI/CD pipeline in
    an AWS environment, aiming to automate the build, test, and deployment
    processes. As a practical use case, a serverless streaming application is
    used to demonstrate the operation and integration of individual CI/CD
    stages. The infrastructure is defined using the AWS Cloud Development Kit
    (CDK), while the CI/CD pipeline is implemented with AWS CodePipeline and
    CodeBuild services. The result is a reliable and extensible delivery process
    that enables controlled and secure multi-environment application deployment.
]

// TODO: Текст задатка добијате од ментора. Заменити доле #lorem(100) са текстом задатка.
#let zadatak = [
    Пројектовати и имплементирати CI/CD pipeline у AWS окружењу који омогућава аутоматизацију процеса изградње, тестирања и постављања serverless streaming апликације. Систем треба да подржи декларативно управљање инфраструктуром применом концепта Infrastructure as Code коришћењем AWS Cloud Development Kit (CDK) алата. Неопходно је реализовати CI/CD процес помоћу сервиса AWS CodePipeline и CodeBuild, са јасно дефинисаним фазама контроле квалитета, тестирања, ручног одобрења и постављања у више окружења. Решење треба да обезбеди поуздано, безбедно и прошириво постављање апликација.
]

// TODO: Датум одбране и чланове комисије добијате од ментора
#let datum_odbrane = "01.01.2025"
#let komisija_predsednik = "Петар Петровић"
#let komisija_predsednik_zvanje = "ванредни професор"
#let komisija_clan = "Марко Марковић"
#let komisija_clan_zvanje = "доцент"

// На енглеском уписати чланове на латиници
#let komisija_predsednik_eng = "Petar Petrović"
#let komisija_clan_eng = "Marko Marković"
#let mentor_eng = "Miroslav Zarić"


// Ово даље углавном не треба мењати.

#let zvanje_eng = (
     "редовни професор": "full professor",
     "ванредни професор": "assoc. professor",
     "доцент": "asist. professor",
)
#let komisija_predsednik_zvanje_eng = zvanje_eng.at(komisija_predsednik_zvanje)
#let komisija_clan_zvanje_eng = zvanje_eng.at(komisija_clan_zvanje)
#let mentor_zvanje_eng = zvanje_eng.at(mentor_zvanje)


#let vrsta_rada = if stepen == "Мастер академске студије" {
    "Дипломски - мастер рад"
} else {
    "Дипломски - бечелор рад"
}

#let oblast = "Електротехничко и рачунарско инжењерство"
#let oblast_eng = "Electrical and Computer Engineering"
#let disciplina = "Примењене рачунарске науке и информатика"
#let disciplina_eng = "Applied computer science and informatics"

#import "funkcije.typ": *
// Поглавља/страна/цитата/табела/слика/графика/прилога
#let fizicki_opis = physical()
