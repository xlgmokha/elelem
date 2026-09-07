# Documentation Website

As a **user discovering elelem**, I want comprehensive documentation on a website, so that I can learn how to configure and use elelem effectively.

As a **plugin author**, I want documentation with examples, so that I can extend elelem for my workflows.

## SYNOPSIS

Create a minimal, fast documentation website with no JavaScript or cookies.

## DESCRIPTION

Build a static documentation site that serves as the primary reference for elelem.
The site should have a man-page-style minimal aesthetic - clean, fast, focused on content.

### Content Structure

```
/                     # Overview, what is elelem
/getting-started/     # Installation, first run, basic usage
/workflow/            # Plan → Design → Build → Review → Verify loop
/configuration/       # Config files, environment variables, XDG paths
/modes/               # Detailed explanation of each mode
  /plan/
  /design/
  /build/
  /review/
  /verify/
/plugins/             # Plugin system overview
  /authoring/         # How to write plugins
  /examples/          # Example plugins with explanations
/mcp/                 # MCP integration guide
/reference/           # Command reference, tool schemas
```

### Design Principles

- **No JavaScript** - Content works without JS
- **No cookies** - No tracking, no consent banners
- **Fast** - Minimal CSS, no frameworks
- **Accessible** - Semantic HTML, good contrast, works with screen readers
- **Unix aesthetic** - Clean, monospace-friendly, man-page inspired

### Workflow Diagram

Include the development workflow prominently:

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  PLAN   │ → │ DESIGN  │ → │  BUILD  │ → │ REVIEW  │ → │ VERIFY  │ → done
│ draft   │   │ ready   │   │designing│   │building │   │reviewing│
│         │   │         │   │→building│   │→reviewing│  │→verifying│
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
 Interview     Research      Execute       Code          Smoke test
 stories       create tasks  tasks         review        demo
```

## SEE ALSO

* [ ] https://www.mokhan.ca/ - Style reference
* [ ] Existing README.md content to migrate

## Research (Design Phase)

- [ ] Evaluate static site generators (Hugo, Zola, Eleventy, plain HTML+Make)
- [ ] Determine hosting approach (self-hosted server)
- [ ] Design information architecture
- [ ] Create minimal CSS theme

## Tasks

* [ ] TBD (filled in design mode)

## Acceptance Criteria

* [ ] Site builds with no JavaScript dependencies in output
* [ ] Site includes no cookies or tracking
* [ ] Site loads in < 1 second on slow connections
* [ ] All pages pass WAVE accessibility checker
* [ ] Getting started guide enables new user to run elelem
* [ ] Plugin authoring guide includes working example
* [ ] Workflow diagram is prominently displayed
* [ ] Site renders well on mobile (responsive, no horizontal scroll)
* [ ] Site works with JavaScript disabled
* [ ] All code examples are syntax highlighted (CSS only, no JS)
