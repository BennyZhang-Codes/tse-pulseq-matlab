<template>
  <figure class="tse-mermaid">
    <div ref="diagramEl" class="tse-mermaid__canvas" />
    <pre v-if="error" class="tse-mermaid__error"><code>{{ source }}</code></pre>
  </figure>
</template>

<script>
let globalMermaidRenderSerial = 0
</script>

<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { useData } from 'vitepress'
import mermaid from 'mermaid'

const props = defineProps({
  code: { type: String, required: true },
})

const { isDark } = useData()
const diagramEl = ref(null)
const error = ref('')
const source = computed(() => decodeURIComponent(props.code))

function keepDiagramReadable(container) {
  const svg = container?.querySelector('svg')
  if (!svg) return

  // Mermaid diagrams with only a few nodes can have a very small natural
  // viewBox and otherwise render like thumbnails. Enlarge only those small
  // diagrams; wide diagrams retain their natural size and remain horizontally
  // scrollable in the figure container.
  const viewBox = svg.viewBox?.baseVal
  const naturalWidth = viewBox?.width || 0
  if (naturalWidth > 0 && naturalWidth < 620) {
    svg.style.setProperty('width', '620px', 'important')
  } else {
    svg.style.setProperty('width', 'auto', 'important')
  }
  svg.style.setProperty('max-width', 'none', 'important')
  svg.style.setProperty('height', 'auto', 'important')
}

async function renderDiagram() {
  if (!diagramEl.value) return

  await nextTick()
  error.value = ''
  diagramEl.value.innerHTML = ''

  const dark = isDark.value
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    theme: 'base',
    themeVariables: dark
      ? {
          background: 'transparent',
          primaryColor: '#24243c',
          primaryTextColor: '#eef2ff',
          primaryBorderColor: 'transparent',
          lineColor: '#a5b4fc',
          secondaryColor: '#2b2342',
          tertiaryColor: '#17313a',
          clusterBkg: 'transparent',
          clusterBorder: 'transparent',
          edgeLabelBackground: 'transparent',
        }
      : {
          background: 'transparent',
          primaryColor: '#f7f7ff',
          primaryTextColor: '#28233e',
          primaryBorderColor: 'transparent',
          lineColor: '#7c3aed',
          secondaryColor: '#f5f3ff',
          tertiaryColor: '#ecfeff',
          clusterBkg: 'transparent',
          clusterBorder: 'transparent',
          edgeLabelBackground: 'transparent',
        },
    themeCSS: `
      .node rect, .node polygon, .node path, .cluster rect {
        stroke: none !important;
        stroke-width: 0 !important;
      }
      .node rect { rx: 11px; ry: 11px; }
      .nodeLabel, .edgeLabel {
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      .nodeLabel { font-size: 15px; line-height: 1.3; }
      .nodeLabel p { margin: 0 !important; line-height: 1.3 !important; }
      .edgeLabel { font-size: 14px; }
      .edgePath path { stroke-width: 1.4px; }
      .flowchart-link { stroke-linecap: round; stroke-linejoin: round; }
    `,
    flowchart: {
      curve: 'basis',
      htmlLabels: true,
      nodeSpacing: 46,
      rankSpacing: 54,
      padding: 16,
      wrappingWidth: 210,
    },
  })

  const id = `tse-mermaid-${++globalMermaidRenderSerial}`

  try {
    const { svg, bindFunctions } = await mermaid.render(id, source.value)
    if (!diagramEl.value) return
    diagramEl.value.innerHTML = svg
    bindFunctions?.(diagramEl.value)
    keepDiagramReadable(diagramEl.value)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : String(cause)
  }
}

onMounted(renderDiagram)
watch([source, isDark], renderDiagram)
</script>

<style scoped>
.tse-mermaid {
  margin: 1.5rem 0 2rem;
  padding: .75rem 0;
  overflow-x: auto;
  overscroll-behavior-inline: contain;
  border: 0;
  background: transparent;
}

.tse-mermaid__canvas {
  display: flex;
  width: max-content;
  min-width: 100%;
  justify-content: center;
  align-items: center;
  background: transparent;
}

.tse-mermaid__canvas :deep(svg) {
  display: block;
  width: auto !important;
  max-width: none !important;
  height: auto !important;
  overflow: visible;
  background: transparent !important;
}

.tse-mermaid__error {
  margin: 0;
  white-space: pre-wrap;
  color: var(--vp-c-danger-1);
  background: transparent;
}

@media (max-width: 700px) {
  .tse-mermaid { padding: .55rem 0; }
  .tse-mermaid__canvas { justify-content: flex-start; }
}
</style>
