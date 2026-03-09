---
title: "Código que no es tuyo"
date: 2026-03-09T13:32:00+02:00
author: miniluz
# aliases: ["first"]
# showToc: true
draft: false
math: false
svg: false
---

Uno de los trabajos en grupo de mi universidad es de 18 personas, y bastantes de
mis compañeros están usando la IA para generación de código, mucho. La revisión
y corrección constante de lo que generan son tareas interminables para los que
supervisamos el código del proyecto.

Yo también he aprendido a usar IAs para generar código, y trabajo bastante con
ellas ahora. Sin embargo, los "product owners" del proyecto notamos una
diferencia clara entre el código y el trabajo que yo realizo y el suyo.

En gran parte es por mi conocimiento y habilidad, que como llevo más tiempo
programando es mayor. Yo entiendo un poco más de Springboot y cómo funcionan los
frameworks web que ellos, y por lo tanto sé dirigir mejor los planes e
identificar mejor los errores de las LLMs. Muchos de mis compañeros tienen menos
familiaridad con Springboot y cómo funciona por detrás, por lo que no tienen un
modelo mental tan claro, y ven algunas cosas como "magia". Si sigues los ritos
al hacer las cosas, sencillamente funciona.

Últimamente pienso que en gran parte el trabajo de un programador es cargar con
el peso cognitivo del proyecto. Tener un modelo mental del sistema entero. Este
modelo es el resultado inevitable de escribir el código tú mismo, construido con
cada error que te sale y que no entiendes. Mil momentos que te llevan a indagar
más en cómo funcionan las cosas. Lentamente vas eliminando la magia que aportan
los frameworks, hasta que el modelo incluye su funcionamiento interno, o al
menos su contrato y sus invariantes. Cuando generas código con IA, acabas con un
modelo mucho más superficial. Para intentar evitarlo, reviso el código que
genera la IA línea por línea. Pero no sé si es suficiente. Mi modelo mental del
código es bastante más débil de lo que sería si lo hubiera escrito yo.

Obviamente no sé de Springboot tanto como otros programadores, ni de cerca. Hay
muchas partes de Springboot que son magia para mí (Spring Security, etc.). Me
preocupa no estar aprendiéndolas, ya que la IA hace algo que funciona, y no
tengo que enfrentarme con ello. Y esto me genera cierta ansiedad. Sé qué decido
no aprender, pero no sé qué es lo que no aprendo.

Una solución sería entrar en el código y entenderlo a tal nivel que sabría línea
por línea qué implementar, y decirle a la IA que lo genere. Pero, haciendo eso,
¿por qué no escribirlo yo?

Lo que hacen algunos de mis compañeros definitivamente no es suficiente. Lo
genera la IA, lo revisan con pruebas que hace la IA, y ni eso se revisa en
detalle. Hacen el código, pero no cargan ellos con la carga cognitiva de
entenderlo en profundidad, de entender todo el flujo de los datos. Hacen el
código, pero no hacen su trabajo como programadores. No son responsables de ese
código. No llevan esa carga cognitiva. Los responsables acaban siendo los
revisores, si eso.

---

En contraste, hay un proyecto sobre el que tengo un modelo mental completo, y
sobre el que llevo toda la carga cognitiva solo: mi TFG. Estoy usando Embassy,
un framework muy poco mágico para plataformas embebidas. Todo el código, la
sincronización entre tareas, el flujo del control, lo hago yo. Soy capaz de
mentalizar completamente todo lo que ocurre en el sistema, con todo detalle.

Este es un trabajo en el que parto de cosas que existen y genero el código que
cumple con el propósito. Es un programa construido "bottom-up". Recientemente,
he visto casos de estudio sobre
[SQLite](https://www.youtube.com/watch?v=ZP7ef4eVnac) y
[LiChess](https://www.youtube.com/watch?v=7VSVfQcaxFY) y otros proyectos donde
los desarrolladores construyen lo que necesitan integrando librerías. Los casos
concluyen que lo vital para su éxito es que los desarrolladores tienen el modelo
mental completo en su cabeza, porque los construyeron "bottom-up".

En el trabajo en grupo, uso lo que incluye Springboot por defecto: JPA,
Liquibase, Spring Security, etc. Es un proyecto que se siente muy distinto,
porque hay partes de la codebase que no entiendo. Y no es únicamente porque es
código que no he tocado. Es porque siento la "magia" de Springboot. Usamos su
organización, sus sistemas, su inyección de dependencias... Incluye todo, y de
ahí sacamos lo que necesitamos, "top-down".

Pero en cierta medida esto es una ventaja para un trabajo con tanta gente: hay
únicamente una manera "correcta" de hacer las cosas, según su filosofía. Hay
menos maneras de tomar algo y reducirlo al producto que quieres, "top-down", que
de generarlo desde cero, "bottom-up".

Si mi TFG fuese proyecto de 18 personas, sería mucho más complicado crearlo
haciendo el código "bottom-up". A menos que se defina a mano una organización de
los archivos y de la lógica, de la filosofía, de la documentación de la API, de
manera apropiada para el desarrollo embebido. Y aun haciéndolo cada
desarrollador tendría que aprenderla.

Por esto no considero que los estudios de caso tengan razón, o no del todo. Hay
proyectos de tal tamaño, tanto del código como del equipo, que es imposible
tener todo el código en tu cabeza. Por eso es importante hacer APIs útiles,
contratos explícitos, supuestos e invariantes explícitos. Y los frameworks
"top-down" dan un punto común para esto. Sus APIs, contratos, supuestos e
invariantes son comunes entre aplicaciones, equipos y compañías.

---

Pero aún trabajando con equipos pequeños y centrados, Springboot se siente
ajeno, incluso en comparación con otros backends con estructura similar que he
montado desde cero. Gran parte de este sentimiento es que no entiendo Springboot
tanto como entiendo el sistema que monté en NestJS. Si lo hiciera, sospecho que
me gustaría más. Pero hay algo más profundo.

Y es que realmente, para mí, no es sobre si es "bottom-up" o "top-down". Es
sobre el control. Tanto la IA como Springboot me quitan ese sentimiento. Es lo
que tienen en común: SQLite, LiChess, y mi TFG son proyectos relativamente
pequeños de grupos pequeños. Son proyectos donde es posible que todos tengan un
modelo mental completo. Que todos tengan el control.

En proyectos grandes, esto es imposible. Quizá ni siquiera es necesario, pero
siento que lo es. Y no sé si es que tengo razón, o que mi cerebro tan solo no
quiere renunciar al consuelo que da el control.

Se promete que la generación de código con IA es el futuro de la programación.
He aprendido a usar las herramientas, y han multiplicado la velocidad a la que
programo. Pero no puedo evitar preguntarme si realmente estoy realizando mi
trabajo. ¿Es realmente el trabajo de un programador llevar la carga cognitiva, o
es lo que pienso para aferrarme al control, al sentimiento que me llevó a amar
programar? ¿Siento lo que siento por la IA, o por estar en un proyecto grande en
el que no controlo todo?

Quizá no es necesario que todos lleven la carga cognitiva. Pero creo que el
control y la responsabilidad siempre estarán en demanda, incluso en proyectos
grandes. Creo que siempre se necesitará gente que sepa lo suficiente para montar
un modelo mental completo. Ver los sistemas por lo que son, y no por su magia.
O, en cualquier caso, al menos es lo que yo busco.
