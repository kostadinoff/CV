// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [АВТОБИОГРАФИЯ],
  authors: (
    ( name: [Костадин Рангелов Костадинов],
      affiliation: [],
      email: [] ),
    ),
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Лични данни
<лични-данни>
`Дата на раждане`

- 1992-04-01
- гр. Пловдив, България

#horizontalrule

= Образование
<образование>
`Декември 2021 - До момента`

- Редовен докторант | Катедра „Социална медицина и обществено здраве“ | МУ-Пловдив | „Здравни политики в областта на редките тумори“

`Октомври 2024 - До момента`

- Магистър „Статистическо бизнес консултиране“ | Стопанска академия „Димитър А. Ценов“ гр. Свищов

`Октомври 2021 - Септември 2022 г.`

- Магистър „Икономика и финанси“ | Стопански факултет | Софийски университет „Климент Охридски“

`Октомври 2017 - Септември 2019 г.`

- Магистър „Обществено здраве и здравен мениджмънт“ | Факултет по обществено здраве | МУ-Пловдив

`Септември 2012 - Декември 2017 г.`

- Магистър „Медицина“ | Медицински факултет | МУ-Пловдив

#horizontalrule

= Трудов стаж
<трудов-стаж>
`Октомври 2024 - До момента`

- МУ-Пловдив | Млад учен - изследовател R1 | Изследователска група (ИГ) 3.1.5 – „Здраве и качество на живот в зелена и устойчива околна среда“ | „Програма за стратегически изследвания и иновации за развитие на МУ-Пловдив“ | Договор: BG-RRP-2.004-0007-C01 от 31.12.2022 г.

`Април 2022 - До момента`

- Специализант "Социална медицина и организация на здравеопазването и фармацията" | МУ-Пловдив

`Септември 2021 - До момента`

- МУ-Пловдив | Асистент висше училище | Учебно-практически занятия по дисциплините медицинска етика; биостатистика; социална медицина и обществено здраве

`Декември 2020 - До момента`

- СБАЛХБ „Медикус Алфа“ ЕООД | Лекар-ординатор | Здравеопазване | Болнична и извънболнична медицинска помощ

`Декември 2017 - Март 2020 г.`

- УМБАЛ „Пловдив“ АД | Лекар специализант | Здравеопазване | Болнична медицинска помощ

#horizontalrule

== Участие в неправителствени организации
<участие-в-неправителствени-организации>
`2021 - До момента`

- Лекарска мрежа „Въздух за здраве“

`2011 - 2017 г.`

- Студентски съвет | Председател | Председател на ОС

`2012 - 2017 г.`

- Асоциация на студентите по медицина в България | Председател на контролен съвет | Секретар

#horizontalrule

= Лични умения и компетентности
<лични-умения-и-компетентности>
== Преподавателска дейност
<преподавателска-дейност>
- Зимен семестър 2021/22 г. Биостатистика | Медицинска етика | Обществено дентално здраве

- Летен семестър 2021/22 г. Социална медицина и обществено здраве

- Зимен семестър 2022/23 г. Биостатистика | Медицинска етика | Обществено дентално здраве

- Летен семестър 2022/23 г. Социална медицина и обществено здраве

- Зимен семестър 2023/24 г. Биостатистика | Медицинска етика | Обществено дентално здраве | Дизайн на клиничните изпитвания неинтервенционните проучвания

- Летен семестър 2023/24 г. Социална медицина и обществено здраве

- Зимен семестър 2024/25 г. Биостатистика | Медицинска етика | Обществено дентално здраве | Дизайн на клиничните изпитвания неинтервенционните проучвания

== Езикови
<езикови>
`Български език` (майчин)

`Английски език`

- First Certificate in English (FCE) - Cambridge English Language Assessment | Reading C1 | Writing B2 | Use of English C1 | Listening B2 | Speaking C1

== Социални
<социални>
Академична и преподавателска дейност в мултикултурна среда със студенти по медицина и дентална медицина. Курсове за следдипломно обучение с участници от всички континенти. Активно участие в социални и благотворителни проекти на неправителствени организации. Допълнителна професионална квалификация в Ирландия, Германия, Гърция, Австрия, Финландия.

== Компютърни умения
<компютърни-умения>
`Програмни езици и инструменти`

- #emph[Data analysis] #strong[R] | Python | SPSS | SAS | STATA | Orange | Jamovi | JASP | QGIS

- #emph[Други] #strong[Linux];; R studio; MySQL; Latex; VS code; html; CSS; Quarto; Pandoc; Microsoft 365; Google Workspace

== Други
<други>
- Свидетелство за управление на МПС | кат. В

#horizontalrule

= Членство в професионални и научни организации
<членство-в-професионални-и-научни-организации>
== Национални
<национални>
`от 2016 г.` Младежко научно дружество „Асклепий“ | Член на управителен съвет мандат 2024-2026 г.

`от 2017 г.` Български лекарски съюз

`от 2017 г.` Дружество на кардиолозите в България

`от 2020 г.` Българско научно дружество по обществено здраве

`от 2020 г.` Българската асоциация по обществено здраве

`от 2016 г.` Сдружение на обучители и изследователи в България по обща медицина

`от 2020 г.` Асоциация за социални изследвания и приложни изследователски практики

== Международни
<международни>
`от 2020 г.` Европейска асоциация по обществено здраве

`от 2022 г.` Световна федерация на асоциациите по обществено здраве (WFPHA)

#horizontalrule

= Публикации
<публикации>
#block[

] <refs>

#horizontalrule

= Проектна дейност
<проектна-дейност>
== Университетски проекти
<университетски-проекти>
`Септември 2021 г.`

- „Бърза микробиологична диагноза на генитални инфекции при жени и мъже – сравнителен анализ” № НО-03/2020 (НО-Р-8445). Научноизследователски проект, финансиран по Наредба на МОН от 01.01.2017 г. за условията и реда за планиране, разпределение и разходване на средствата, отпускани целево от държавния бюджет за присъщата на висшите училища научна или художествено-творческа дейност.

`Септември 2022 г.`

- „Антимикробна активност на каналопълнежните средства за лечение на ендодонтска инфекция на временни зъби“ Докторантски и постдокторантски проекти ДПДП 04/01.09.2021

`Септември 2023 г.`

- „Проучване на връзката между некултивируемите и трудно култивируеми микроорганизми с фертилната функция на мъже със симтоматични и асимптоматични инфекции на долен урогенитален тракт“ Вътреуниверситетски проект No: НО-17/2023

`Октомври 2023 г.`

- „Сравнително проучване върху съвременни микробиологични методи за бърза етиологична диагностика на уроинфекции“ Докторантски и постдокторантски проекти ДПДП 10/2023

== Национални проекти
<национални-проекти>
`Април 2021 г.`

- Национална научна програма „Млади учени и постдокторанти“ | Министерство на образованието и науката

`Октомври 2024 г.`

- Изследователска група (ИГ) 3.1.5 – „Здраве и качество на живот в зелена и устойчива околна среда“ | „Програма за стратегически изследвания и иновации за развитие на МУ-Пловдив“ | Договор: BG-RRP-2.004-0007-C01 от 31.12.2022 г.

`Септември 2024 г.`

- Национална научна програма „Млади учени и постдокторанти - 2“ | Министерство на образованието и науката | BG05M2OP001-2.009-0025

`Октомври 2024 г.`

== Международни проекти
<международни-проекти>
`Март - Май 2020 г.`

- „Интердисциплинарност, мултикултурализъм и работа с пациента в нестандартна ситуация в контекста на провеждане на дидактични занимания в областта на медицинските науки и здравните науки в Симулационни медицински центрове“ | проект № 2019-1-PL01-KA203-065205 | Програма Еразъм Key Action 2: Cooperation for innovation and the exchange of good practices KA 203: Strategic partnerships for higher education

`Септември 2021 г. - Септември 2022 г.`

- Screen4Care | Shortening the path to rare disease diagnosis by using newborn genetic screening and digital technologies | Innovative Medicines Initiative 2 | Joint Undertaking (JU) under grant agreement No 101034427

`Февруари 2022 г. - Декември 2024 г.`

- Safe4Child | "Caring for Violent Children Safely in Child Psychiatric and Residential Units" | Erasmus+ Programme | Key Action 2 | Agreement No.~2021-1-FI01-KA220-HED-000032106

`Април 2023 г. - Декември 2023 г.`

- W\@S | "Developing Multi-Professional Higher Education for Promoting Mental Health and Well-Being in Schools" | Project Reference: 2020-1-FI01-KA203-066521

`2018 - 2019 г.`

- Клинично проучване | ApoA-I Event reducinG in Ischemic Syndromes II (AEGIS II) | Координатор

`2024 - 2026 г.`

- AFFIRMO | Atrial Fibrillation Integrated Approach in Frail, Multimorbid, and Polymedicated Older People | Монитор | European Union’s Horizon 2020 research and innovation programme | Grant agreement 899871

#horizontalrule

= Участия в конгреси
<участия-в-конгреси>
== Национални
<национални-1>
`27-29 септември 2019 г.`

- 11-та научна среща-обучение на СОИБОМ | #emph[„Пътят на пациента със сърдечно-съдови заболявания“] | Орална презентация |„#emph[Клиничен случай на клапно предсърдно мъждене];“ | #strong[Костадинов К.]

`28 ноември 2020 г.`

- Виртуален конгресен център „Редки болести и лекарства сираци” | #emph[#link("https://youtu.be/R_UbvDcyTxs")[„Придобита тромботична тромбоцитопенична пурпура по пътя на предизвикателствата“];] | #strong[Костадинов К.]

`09-11 март 2021 г.`

- Конференцията Наука и Младост 2021

+ #link("https://www.asclepius.bg/images/nm2021/%D0%9F%D0%A0%D0%9E%D0%93%D0%A0%D0%90%D0%9C%D0%90-%D0%9D%D0%90%D0%A3%D0%9A%D0%90-%D0%98-%D0%9C%D0%9B%D0%90%D0%94%D0%9E%D0%A1%D0%A2-2021.pdf")[„#emph[Промяна в хранителните навици и поведение по време на противоепидемичните мерки, наложени по повод COVID 19];“] | Пленарна лекция | Хубенова М, #strong[Костадинов К];, Мандова В

+ #link("https://www.asclepius.bg/images/nm2021/%D0%9F%D0%A0%D0%9E%D0%93%D0%A0%D0%90%D0%9C%D0%90-%D0%9D%D0%90%D0%A3%D0%9A%D0%90-%D0%98-%D0%9C%D0%9B%D0%90%D0%94%D0%9E%D0%A1%D0%A2-2021.pdf")[„#emph[Промяна в физическата активност в условията на противоепидемични мерки];“] Пленарна лекция | #strong[Костадинов К.] Хубенова М. Мандова В.

+ #emph[#link("https://asclepius.bg/cnm/wp-content/uploads/2022/05/Sbornik-Nauka-i-Mladost-2021.pdf")[„Oral health self-assessment among haemophilia families“];] | Victoria Mandova, #strong[Kostadin Kostadinov];, Rumen Stefanov

`13-14 май 2021 г.`

- XIV-та национална научно-техническа конференция с чуждестранно участие “Екология и здраве“ | #emph[#link("https://hst.bg/ECOLOGY%20AND%20HEALTH%202021.pdf")[„Съвременен микробиологичен и молекулно-биологичен скрининг на генитални инфекции при симптоматични небременни жени“];] | Ели Христозова, Зоя Рачковска, Тихомир Дерменджиев, Мариана Мурджева, Вида Георгиева, Екатерина Учикова, #strong[Костадин Костадинов] | МУ Пловдив“

`14-16 септември 2021 г.`

- XVIII национален конгрес по клинична микробиология и инфекции на българската асоциация на микробиолозите | #emph[„Бърз молекулно-биологичен скрининг за вагинална кандидоза при симптоматични жени“] | Христозова Е., Рачковска , Георгиева В., Дерменджиев Т., #strong[Костадинов К.];, Влахова М., Учикова Е. ,Мурджева М. | Постер

`15-16 септември 2022 г.`

- XX Юбилеен национален конгрес по клинична микробиология и инфекции на българската асоциация на микробиолозите

+ #emph[#link("https://www.bam-bg.net/images/documents/3Posters.pdf")[„Проучване уретралния микробиом с androflor screen при мъже с неспециф ична генитална симптоматика в условия на covid-19 пандемия“];] | E. Христозова, Т. Дерменджиев, З. Рачковска, В. Георгиева, #strong[К. Костадинов];, Ц. Павлов, М. Мурджева | в Сборник с научни трудове

+ #emph[#link("https://www.bam-bg.net/images/documents/2Abstracts.pdf")[„Omicron – успокоение или предизвикателство?“];] | М. Атанасова, Н. Корсун, Р. Комитова, #strong[К. Костадинов];, И. Алексиев, Р. Райчева, И. Иванов, Л. Гломб, Ц.Петкова, Л. Джоглова | вкл. в Сборник с научни трудове

`30 септември - 01 октомври 2022 г.`

- Четвърта национална конференция по епидемиология | „Инфекциозните заболявания в България- проблеми и перспективи” | #link("http://bulepid.org/_upload2018/PROGRAMA%202022-pre-final%20-%20Copy.pdf")[#emph[„Ковид-19 в България и влияние на ваксините върху хоспитализацията, смъртността и леталитета“];] | А. Кеворкян, #strong[К. Костадинов];, В. Рангелова, Р. Райчева, А. Кунчев, А. Сербезова

`19-21 април 2024 г.`

- Конференцията Наука и Младост 2021 | #emph[#link("https://asclepius.bg/cnm/wp-content/uploads/2024/04/SY-DMS-2024-abstracts-web.pdf")[Assessment of antimicrobial susceptibility of staphylococcus aureus nasal isolates from preclinical medical students at the medical university of Plovdiv];] | Aras Budak, #strong[Kostadin Kostadinov];, Radoslav Tashev, Eli Hristozova

`27-29 септември 2024 г.`

- Шеста национална конференция по епидемиология | „Предизвикателства в превенцията на инфекциозните болести” | #link("http://bulepid.org/_upload2018/PROGRAMA%202024-final.pdf")[#emph[„Оценка на професионални рискови екзпозиции и степента на прилагане на стандартни предпазни средства сред медицински персонал“];] | Велина Стоева, Христиана Бацелова, #strong[Костадин Костадинов];, Кирил Атлиев

`27-28 септември 2024 г.`

- Седма научна конференция с международно участие | „Общественото здраве: поглед към бъдещето” | #link("https://publisher.mu-plovdiv.bg/wp-content/uploads/published-online/public-health-conf/2024/abstract-book.html#p=56")[#emph[„Повишаване на грижите ориентирани към пациента, чрез симулационно обучение с очила за виртуална реалност“];] | Гергана Петрова, #strong[Костадин Костадинов];, Валентина Лалова, Светла Иванова

`10-13 oктомври 2024 г.`

- XVIII Национален конгрес по кардиология | #link("https://www.bgcardio.org/storage/app/media/uploaded-files/XVIII%20Congress%20program_web.pdf")[#emph[„Роля на въздушното замърсяване в генезата на ССЗ“];] | #strong[Костадин Костадинов] | гр. Пловдив

`10-11 oктомври 2024 г.`

- Научната конференция „Околна среда и здраве: социо-технически бариери и перспективи за издигане на качеството на живот на човешките колективи.” | #link("https://hiddeneurope-jeanmonnet.uni-plovdiv.net/2024/10/%d0%bf%d1%80%d0%be%d0%b3%d1%80%d0%b0%d0%bc%d0%b0-%d0%bd%d0%b0-%d0%bd%d0%b0%d1%83%d1%87%d0%bd%d0%b0%d1%82%d0%b0-%d0%ba%d0%be%d0%bd%d1%84%d0%b5%d1%80%d0%b5%d0%bd%d1%86%d0%b8%d1%8f-%d0%be%d0%ba/")[„Изследвания върху връзката на замърсяването на въздуха и характеристиките на градската среда със здравето на населението“];| доц. д-р Ангел Джамбов, #strong[ас. д-р Костадин Костадинов];, проф. Донка Димитрова | ПУ „Паисий Хилендарски“ | гр. Пловдив

== Международни
<международни-1>
`20 - 23 октомври 2022 г.`

- Joint Forum: 12th South-East European Conference and 32st Annual Assembly of IMAB. | #emph[„Antimicrobical activity of root canal filling materials for endodonic treatment in primary dentition“] | Maria Shindova, Eli Hristozova, Plamen Katsarov, Michael Onov, #strong[Kostadin Kostadinov];, Vasko Toplev, Ani Belcheva

`15 - 18 април 2023 г.`

- 33-rd European Congress of Clinical Microbiology and Infectious Diseases | #emph[„Impact of COVID-19 vaccines – data from Bulgaria“] | Ani Kevorkyan, #strong[Kostadin Kostadinov];, Vania Rangelova, Ralitsa Raycheva , Angel Kunchev

`4-11 март 2023 г.`

- 41th European Winter Conference on brain research (EWCBR) | #emph[Immunological reactivity under acute and chronic stress. Where are we? Experience in Bulgariа.] | M. Ivanovska, T. Kalfova, P. Gаrdjeva, #strong[\K. Kostadinov];, M. Murdjeva

`14 септември 2023 г.`

- Webinar | EU Health Technology Assessment Regulation | The role and involvement of Cancer Patients | #emph[Landscape of Bulgarian HTA regulations] | #strong[Kostadinov K];. Belgium.

`Май 2023 г.`

- ISPOR 2023 | Boston, MA, USA | #link("https://www.ispor.org/heor-resources/presentations-database/presentation/intl2023-3665/126756")[#emph[The Price of Innovation – Oncology Treatments Expenditures: Case from Bulgaria];] | Raycheva R, #strong[Kostadinov K]

`Ноември 2023 г.`

- ISPOR Europe 2022 | Vienna, Austria | #link("https://www.ispor.org/heor-resources/presentations-database/presentation/euro2022-3565/120960")[#emph[Delay of Innovative Oncology Treatments - Case From Bulgaria];] | Raycheva R, #strong[Kostadinov K]

`13-15 ноември 2024 г.`

- 17th European Public Health Conference 2024 | #link("https://ephconference.eu/app/programme/programme.php?d=displays")[DV.24 - Mapping the Policy Alternatives for Rare Cancer] | #strong[Kostadinov K];, Hristozova E, Musurova N, Iskrov G, Stefanov R

#horizontalrule

= Квалификации
<квалификации>
`24-25 септември 2011 г.`

- Медицински университет Пловдив | „Спешна помощ в медицината“ | гр. Пловдив

`22-23 ноември 2012 г.`

- Национална програма за превенция и контрол на ХИВ и сексуално предавани инфекции в Република България 2008-2015г. | Обучение „Лечение и грижи за хора, живеещи с ХИВ/СПИН и намаляване на стигмата и дискриминацията“ | гр. Пловдив

`16 декември 2012 г.`

- Токуда болница София | Обучение „Основни хирургически умения“ | гр. София

`20-21 октомври 2014 г.`

- Програма финансирана от Глобалния фонд за борба срещу СПИН, туберкулоза и малария | Обучение „Диагностика, грижи и лечение на хора живеещи с ХИВ/СПИН (ХЖХС) за нуждите на ПФГФ“ | гр. Пловдив

`24-28 април 2017 г.`

- Национален институт по радиобиология и радиационна защита | Обучение „Медицинско осигуряване при радиационни, ядрени аварии и тероризъм аварийна готовност“ | гр. София

`10 ноември 2017 г.`

- Национална кардиологична болница | Курс „Ехокардиографска оценка на сърдечна функция“ | гр. София

`1-2 декември 2017 г.`

- Critical appraisal course | гр. София | Обучение „Evidence-based medicine“ | гр. София | Narinder Gosall & Gurpal Gosall

`19-20 октомври 2018 г.`

- Първо училище по ехокардиография | Обучение „Въведение в ехокадиографската диагностика“ | гр. София

`22-23 февруари 2019 г.`

- Второ училище по ехокардиография | Обучение „Ехографска оценка на вродени и придобити сърдечносъдови заболявания“ | гр. София

`24-25 октомври 2019 г.`

- Трето училище по ехокардиография | Обучение „Нови ехографски методи в кардиологията“ | гр. София

`Февруари 2020 г.`

- Следдипломно обучение | „Promoters of advanced oncogenetics open online training and multimedia raise awareness on multidisciplinary assessment of patients and their families at risk of hereditary or familial cancer“ | HOPE How Oncogenetics Predicts & Educates Erasmus+ program.2018-1-RO01-KA202-049189

`Март 2020 г.`

- English for academic purposes | Ирина Митърчева, дф | Департамент по езиково обучение (ДЕСО) | МУ-Пловдив

- Езикови въпроси на научния и медицински текст | Департамент по езиково обучение (ДЕСО) | МУ-Пловдив | Доц. Милиева, дф

`22-26 март 2021 г.`

- Курс | Биостатистика с IBM SPSS Statistics for Windows, Version 22.0 | Докторантско училище | МУ-Пловдив

`Юни 2021 г.`

- Интензивн специализиран курс | „Академично писане, изработване на кохранови системни ревюта“ | Договор КП – 06-ДК1/6 от 29.03.2021 г. | „COVID-19 HUB – Информация, иновации и имплементация на интегративни научни разработки“, финансиран по конкурс, свързан с пандемията от COVID-19 | Фонд „Научни изследвания“ | Министерство на образованието и науката

`Септември - Декември 2021 г.`

- Курс „Мащинно самоубочение“ Machine Learning | СофтУни

`10-15 октомври 2022 г.`

- Open Medical Institute (OMI) Seminar | „Economic Evaluation in Healthcare“ | Maastricht University program | Salzburg, Austria

`Януари - Март 2023 г.`

- Introduction to Bayesian Data Analysis | Teaching Team: Prof.~Dr.~Shravan Vasishth, Dr.~Anna Laurinavichyute | University of Potsdam, Germany | openHPI program | Certificate of completion

`03 - 09 декември 2023 г.`

- Open Medical Institute (OMI) Seminar | „Public Health Strategy - I“ | Maastricht University program | Salzburg, Austria, | Certificate of excellent presentation

`Април 2024 - До момента`

- #link("https://openaq.org/about/people/kostadin-kostadinov/")[OpenAQ Community Ambassador Program];. | The OpenAQ program includes a comprehensive curriculum on ambient air pollution, air quality monitoring, data transparency, data access, data analysis, participatory research and community engagement | Certificate of completion

`26 май - 01 юни 2024 г.`

- Open Medical Institute (OMI) Seminar | „Public Health Strategy - II“ | Maastricht University program | Salzburg, Austria, Certificate of excellent presentation

`Септември 2024`

- Курс | National Aeronautics and Space Administration | Washington, D.C, US | „Open Science“ | Certificate of Completion

`Октомври 2024 г. - До момента`

- Следдипломно обучение „Сексология и сексопатология“ | МУ-Пловдив | Отдел СДО

 
  
#set bibliography(style: "plos-medicine.csl") 


#bibliography("referencelist.bib")

