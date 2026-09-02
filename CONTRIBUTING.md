# Guía para contribuir al informe

El informe se escribe en Markdown y posteriormente se exporta a PDF siguiendo el
formato APA 7. Para automatizar ese proceso se utilizan dos herramientas: Pandoc y
XeLaTeX.

## Dependencias

| Herramienta | Uso |
| --- | --- |
| Pandoc | Conversión de Markdown a LaTeX (importante para poder seguir el formato APA 7) |
| MiKTeX (XeLaTeX) | De LaTeX a PDF |
| `tex-gyre` | Fuente TeX Gyre Termes (Times para APA 7) |

Antes de realizar cualquier compilación, es necesario que primero ejecutes
PowerShell en la raíz de la carpeta del proyecto de GitHub y corras el siguiente
comando:

```powershell
.\scripts\dependencies.ps1
```

Ese script verifica si las dependencias están instaladas y, previa confirmación,
instala las que falten. Si ya está todo, no hace nada.

> **Nota:** después de una instalación hay que abrir una terminal nueva. Windows no
> refresca el PATH en las ventanas que ya estaban abiertas.

## Compilación

Para compilar el proyecto y generar la documentación en PDF, ejecuta el siguiente
comando en la raíz de la carpeta del proyecto de GitHub:

```powershell
.\scripts\build.ps1 <av1|tb1|av2|tb2>
```

Es necesario agregar el parámetro especificando el tipo de entregable. Determina
qué capítulos entran en el documento y el nombre del archivo que se genera:

```
dist/upc-pre-<periodo>-1acc0238-<nrc>-<startup>-report-<entrega>.pdf
```

## Estructura

```
appmv/
├── README.md               Informe: registro de versiones, collaboration
│                           insights, índice, student outcome y objetivos SMART
├── CONTRIBUTING.md         Este archivo
├── references.bib          Fuentes bibliográficas en formato BibTeX
├── .gitignore              Excluye el PDF generado y los temporales de LaTeX
│
├── docs/                   Contenido del informe
│   ├── chapter_1.md        Capítulo I: Presentación
│   ├── chapter_2.md        Capítulo II: Requirements Development and Software Solution Design
│   ├── chapter_3.md        Capítulo III: Solution UI/UX Design
│   ├── chapter_4.md        Capítulo IV: Product Implementation & Validation
│   ├── closing.md          Conclusiones, glosario, bibliografía y anexos
│   └── images/             Diagramas y capturas
│       ├── upc_logo.png    Logo de la carátula
│       └── chapter_1..4/   Una carpeta por capítulo
│
├── config/                 Formato del documento. No se toca al escribir.
│   ├── format.yaml         Opciones de Pandoc: idioma, papel, fuente, índice
│   ├── apa7.tex            Reglas APA 7 en LaTeX
│   ├── cover.tex           Carátula según la plantilla del curso
│   ├── apa.csl             Estilo de citación APA 7. No modificar.
│   └── preview/            Envoltorio para previsualizar la carátula sin compilar el informe completo
│
├── scripts/
│   ├── dependencies.ps1    Verifica e instala Pandoc, MiKTeX y la fuente
│   └── build.ps1           Genera el PDF de la entrega indicada
│
├── dist/                   PDF generado. Ignorado por git.
└── .vscode/                Extensiones recomendadas y receta de XeLaTeX
```

## Commits

El historial es parte de la evidencia que se evalúa, así que **ningún commit debe
atribuir autoría a una herramienta de IA**. Hay dos controles:

- `.githooks/commit-msg` rechaza el commit en tu máquina si el mensaje contiene
  `Co-authored-by:` con Claude, Copilot, ChatGPT y similares. Lo activa
  `dependencies.ps1` con `git config core.hooksPath .githooks`.
- El workflow `commit-policy.yml` revisa los mensajes en cada push y cada Pull
  Request, por si alguien usó `--no-verify` o no configuró el hook.

Si un commit ya quedó con esa línea y todavía no lo subiste:

```powershell
git commit --amend
```

### Protección de ramas

`main` y `develop` rechazan los pushes directos: todo entra por Pull Request y con
el check `no-ai-authorship` en verde. Aplica también a los administradores.

Esa configuración vive en los ajustes del repositorio, no en sus archivos, así que
**no se copia al crear un repositorio nuevo a partir de este**. Para replicarla:

```powershell
.\scripts\protect-branches.ps1 <owner/repo>
```

Requiere que las dos ramas existan en el remoto y que el workflow haya corrido al
menos una vez, para que GitHub conozca el check.

## Convenciones de escritura

> **Es importante seguir estas convenciones para que la exportación final salga sin
> problemas.** Varias de ellas no producen ningún error al compilar: el PDF se
> genera igual, pero con el contenido mal formado.

### Encabezados

La numeración se escribe a mano, dentro del título. LaTeX no numera nada, para que
lo que salga en el PDF diga exactamente lo que pide el enunciado.

```markdown
# Capítulo I: Presentación
## 1.1. Startup Profile
### 1.1.1. Descripción de la Startup
#### 1.1.1.1. Subnivel
```

Cada `#` de primer nivel empieza en página nueva automáticamente. El índice muestra
tres niveles; los más profundos se renderizan pero no se listan. Para forzar un
salto de página, `\newpage` en una línea propia.

### Tablas

Solo tablas de tuberías. **Nunca `<table>` de HTML.**

```markdown
| Versión | Fecha      | Autor |
| ------- | ---------- | ----- |
| AV1     | 02/04/2026 | Todos |
```

Al exportar, Pandoc descarta el marcado HTML y conserva únicamente el texto: una
tabla en HTML se convierte en párrafos sueltos, sin estructura y sin ningún mensaje
de error. Lo mismo ocurre con `<div align="center">`, que pierde el centrado.

### Imágenes

La ruta se escribe relativa al archivo `.md` que la referencia. Así se ve tanto en
GitHub como en el PDF.

```markdown
![Context map del dominio](images/chapter_2/context-map.png){width=85%}
```

Cada imagen va en la carpeta de su capítulo. El logo y las fotos del equipo, en la
raíz de `docs/images/`.

### Contenido distinto en GitHub y en el PDF

El `README.md` necesita las dos cosas: una tabla de contenidos con enlaces para
navegar los `.md` en GitHub, y el índice real con números de página en el PDF. Se
resuelve con marcadores en comentarios HTML, que GitHub ignora y Pandoc sí lee.

```markdown
<!-- pdf:omit-start -->
Esto se ve en GitHub y no sale en el PDF.
<!-- pdf:omit-end -->

<!-- pdf:only
\tableofcontents
-->
```

Lo que va dentro de `pdf:only` se interpreta como Markdown, así que admite tanto
comandos de LaTeX (`\tableofcontents`) como bloques de Pandoc (`::: {#refs}`). Al
estar dentro de un comentario, en GitHub no se ve nada.

Lo procesa `config/pdf-only.lua`, que se pasa a Pandoc con `--lua-filter`.

> **Nota:** la tabla de contenidos con enlaces del README es manual. Si agregas o
> renombras un encabezado, hay que actualizar también ese enlace. El índice del PDF
> sí se genera solo.

### Citas y bibliografía

La lista de referencias se genera sola. No se escribe a mano.

**1.** Agregar la fuente a `references.bib`. En Google Scholar: botón de comillas →
BibTeX. La primera palabra de la entrada es la clave con la que se cita.

```bibtex
@book{evans2003ddd,
  author    = {Evans, Eric},
  title     = {Domain-Driven Design},
  publisher = {Addison-Wesley},
  year      = {2003}
}
```

Para herramientas de software se usa `@software` en lugar de `@book`: APA añade solo
la etiqueta `[Computer software]` y el número de versión.

**2.** Citarla en el texto.

| Sintaxis | Resultado |
| --- | --- |
| `[@evans2003ddd]` | (Evans, 2003) |
| `[-@evans2003ddd]` | (2003), para citas narrativas |
| `[@evans2003ddd, p. 45]` | (Evans, 2003, p. 45) |
| `[@clave1; @clave2]` | (Autor A, 2020; Autor B, 2021) |

**3.** Nada más. La entrada aparece en la bibliografía, ordenada alfabéticamente y
con sangría francesa.

Una fuente que no se cite en el texto no aparece en la bibliografía, y así debe ser:
APA solo lista lo que se cita.

En `docs/closing.md` hay un bloque que parece vacío y que **no se debe borrar**:

```markdown
# Bibliografía

<!-- pdf:only
::: {#refs}
:::
-->
```

Marca el punto donde se inserta la lista de referencias. Sin él, Pandoc la pega al
final de todo el documento, es decir después de los anexos.
