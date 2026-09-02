# Guía del repositorio

Informe en Markdown, exportado a PDF con Pandoc + XeLaTeX bajo formato APA 7.

## Requisitos

| Herramienta | Uso | Instalación |
| --- | --- | --- |
| Pandoc ≥ 3.10 | Markdown → LaTeX, citas, índice | `winget install JohnMacFarlane.Pandoc` |
| MiKTeX (XeLaTeX) | LaTeX → PDF | `winget install MiKTeX.MiKTeX` |
| `tex-gyre` | Fuente TeX Gyre Termes (Times para APA 7) | `mpm --install=tex-gyre` |

Abrir PowerShell dentro de la carpeta del proyecto clonado desde GitHub y ejecutar
el siguiente comando para descargar las dependencias:

```powershell
.\scripts\dependencies.ps1
```

Verifica los tres, instala solo lo que falte previa confirmación, y activa la
auto-instalación de paquetes de MiKTeX. Idempotente.

El PATH no se refresca en ventanas ya abiertas: tras instalar, abrir terminal nueva.
Si el script viene marcado como descargado: `Unblock-File .\scripts\dependencies.ps1`.

## Build

Abrir PowerShell dentro de la carpeta del proyecto clonado desde GitHub y ejecutar
el siguiente comando para generar el PDF:

```powershell
.\scripts\build.ps1 <av1|tb1|av2|tb2>
```

El argumento es obligatorio; sin él o con un valor fuera del conjunto, sale con
código 1. Determina el alcance de capítulos y el sufijo del nombre de archivo.

Salida: `dist/upc-pre-<periodo>-1acc0238-<nrc>-<startup>-report-<entrega>.pdf`

Invocación subyacente:

```
pandoc $Chapters
  --metadata-file=config/formato.yaml
  --include-in-header=config/apa7.tex
  --include-before-body=config/caratula.tex
  --citeproc --csl=config/apa.csl --bibliography=referencias.bib
  --pdf-engine=xelatex
  --top-level-division=section
  --resource-path=".;docs"
  -o dist/<nombre>.pdf
```

## Estructura

```
README.md              Registro de versiones, Collaboration Insights, índice,
                       Student Outcome, Objetivos SMART
docs/chapter_1..4.md   Capítulos I–IV
docs/closing.md        Conclusiones, Glosario, Bibliografía, Anexos
docs/images/           Assets; una subcarpeta por capítulo
referencias.bib        Fuentes en BibTeX
config/formato.yaml    Metadata de pandoc (idioma, papel, fuente, índice)
config/apa7.tex        Preámbulo LaTeX con las reglas APA 7
config/caratula.tex    Carátula (fragmento, no documento)
config/preview/        Envoltorio para previsualizar la carátula
config/apa.csl         Estilo de citación APA 7. No modificar.
scripts/               dependencies.ps1, build.ps1
```

## Convenciones de escritura

### Encabezados

Numeración manual dentro del título; `numbersections: false`.

```markdown
# Capítulo I: Presentación
## 1.1. Startup Profile
### 1.1.1. Descripción de la Startup
#### 1.1.1.1. Subnivel
```

`#` fuerza salto de página (`\section` redefinido en `apa7.tex`).
Índice a 3 niveles; los inferiores se renderizan pero no se listan.
Salto manual: `\newpage` en línea propia.

### Tablas

Solo tablas de tuberías. El writer LaTeX de pandoc **descarta el marcado HTML y
conserva el texto**: una `<table>` se renderiza como párrafos sueltos, sin error.
Igual con `<div align="center">`.

```markdown
| Versión | Fecha      | Autor |
| ------- | ---------- | ----- |
| AV1     | 02/04/2026 | Todos |
```

### Imágenes

Ruta relativa al `.md` que la referencia. `--resource-path=".;docs"` resuelve desde
la raíz al compilar; GitHub resuelve desde el archivo.

```markdown
![Context map del dominio](images/chapter_2/context-map.png){width=85%}
```

## Citas y bibliografía

1. Entrada en `referencias.bib`. La clave es el primer campo.

```bibtex
@software{macfarlane2026pandoc,
  author  = {MacFarlane, John},
  title   = {Pandoc: A universal document converter},
  version = {3.10},
  year    = {2026},
  url     = {https://pandoc.org}
}
```

| Tipo | Uso |
| --- | --- |
| `@book` | Libros |
| `@article` | Artículos de revista |
| `@software` | Herramientas. APA añade `[Computer software]` y la versión |
| `@misc` | Documentación web, estándares |

2. Citar en el texto:

| Sintaxis | Salida |
| --- | --- |
| `[@evans2003ddd]` | (Evans, 2003) |
| `[-@evans2003ddd]` | (2003) — para citas narrativas |
| `[@evans2003ddd, p. 45]` | (Evans, 2003, p. 45) |
| `[@a; @b]` | (Autor A, 2020; Autor B, 2021) |

3. Punto de inserción de la lista, en `docs/closing.md`:

```markdown
# Bibliografía

::: {#refs}
:::
```

Sin ese div, citeproc anexa la lista al final del documento, después de Anexos.
Las entradas no citadas no se emiten.

## Carátula

`config/caratula.tex` es un fragmento sin `\documentclass`; se inyecta con
`--include-before-body`.

Previsualización: abrir `config/preview/caratula-preview.tex` → `Ctrl+Alt+V`.
Recompila al guardar. El `% !TEX root` de `caratula.tex` apunta ahí, de modo que
`Ctrl+Alt+B` funciona editando cualquiera de los dos.

`\graphicspath{{docs/images/}{../../docs/images/}}` cubre los dos directorios de
trabajo: raíz (build) y `config/preview/` (previsualización).

Campos a editar: NRC, docente, equipo, proyecto, tabla de integrantes (orden
alfabético por apellido) y mes.

## Formato APA 7

Implementado en `config/apa7.tex`:

| Requisito | Mecanismo |
| --- | --- |
| Márgenes 1" | `geometry` |
| Interlineado 1.5 | `\onehalfspacing` |
| Sangría 0.5" primera línea | `\parindent` |
| Alineado a la izquierda con sangría | `ragged2e` + `\RaggedRightParindent` |
| Sin viudas ni huérfanas | `\widowpenalty` / `\clubpenalty` = 10000 |
| Número de página arriba a la derecha | `fancyhdr` |
| 5 niveles de encabezado | `titlesec` |
| Sangría francesa en referencias | `\cslhangindent` = 0.5in |
| Rótulo "Tabla" / "Figura" | `\renewcommand` sobre babel |

## Diagnóstico

| Mensaje | Causa | Acción |
| --- | --- | --- |
| `ERROR: no delivery given` | Falta el argumento | `build.ps1 av1` |
| `ERROR: xelatex is not installed` | MiKTeX ausente o PATH sin refrescar | `dependencies.ps1`, terminal nueva |
| `ERROR: these files are missing` | Falta un `$ConfigFiles` o capítulo | Crear el archivo listado |
| `Undefined control sequence` | Comando LaTeX inexistente | Ver línea indicada; suele faltar un `\usepackage` en `apa7.tex` |
| `The font ... cannot be found` | Falta `tex-gyre` | `mpm --install=tex-gyre` |
| `Cleaning failed: ... 'perl'` | LaTeX Workshop limpiando con latexmk | Ya resuelto: `clean.method: glob` en `.vscode/settings.json` |
| Tabla renderizada como párrafos | Tabla en HTML | Convertir a tuberías |
| `not checked for MiKTeX updates` | Aviso, no error | Consola de MiKTeX → Updates |
