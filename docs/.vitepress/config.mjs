import { defineConfig } from 'vitepress'
import { mermaidPlugin } from './plugins/vitepress-mermaid/index.js'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  description: 'Research documentation for Cartesian 2D TSE and gSlider-TSE sequence development with Pulseq, explicit platform integration, transparent MATLAB reconstruction, and layered scientific validation.',
  base: '/tse-pulseq-matlab/',
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ['meta', { name: 'theme-color', content: '#6366f1' }],
  ],
  markdown: {
    math: true,
    config(md) {
      md.use(mermaidPlugin)
    },
  },
  themeConfig: {
    siteTitle: 'TSE Pulseq',
    nav: [
      {
        text: 'Guide',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Installation', link: '/installation' },
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Architecture', link: '/concepts-overview' },
        ],
      },
      {
        text: 'Theory',
        items: [
          { text: 'Symbols & notation', link: '/theory/symbols' },
          { text: 'TSE signal & echo-train model', link: '/theory/tse-echo-train' },
          { text: 'Phase encoding & effective TE', link: '/theory/phase-encoding' },
          { text: 'gSlider & TRAPS', link: '/guide/gslider-traps' },
        ],
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence generation', link: '/sequence-generation' },
          { text: 'Parameter reference', link: '/parameter-reference' },
          { text: 'Portability boundary', link: '/platform-integration' },
          { text: 'Siemens 7 T LIN & ICE', link: '/phase-encoding-and-ice' },
        ],
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Reconstruction workflow', link: '/reconstruction' },
          { text: 'Echo corrections', link: '/guide/echo-corrections' },
          { text: 'Image-domain denoising', link: '/guide/denoising' },
          { text: 'Frozen comparison protocol', link: '/validation/reconstruction-protocol' },
        ],
      },
      {
        text: 'Validation',
        items: [
          { text: 'Scientific validation strategy', link: '/validation/scientific-validation' },
          { text: 'Validation & safety', link: '/validation-and-safety' },
          { text: 'Siemens 7 T phantom SOP', link: '/staged-phantom-validation' },
          { text: 'Performance & benchmarking', link: '/validation/performance-benchmarking' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'API overview', link: '/reference/' },
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Reconstruction API', link: '/reference/reconstruction-api' },
          { text: 'Reproducibility & citation', link: '/reproducibility' },
          { text: 'Literature references', link: '/references' },
        ],
      },
      {
        text: 'Support',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Developer guide', link: '/developer-guide' },
          { text: 'GitHub repository', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' },
        ],
      },
    ],
    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Installation', link: '/installation' },
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Architecture', link: '/concepts-overview' },
        ],
      },
      {
        text: 'Theory',
        items: [
          { text: 'Symbols & notation', link: '/theory/symbols' },
          { text: 'TSE signal & echo-train model', link: '/theory/tse-echo-train' },
          { text: 'Phase encoding & effective TE', link: '/theory/phase-encoding' },
          { text: 'gSlider & TRAPS', link: '/guide/gslider-traps' },
        ],
      },
      {
        text: 'Sequence Design',
        items: [
          { text: 'Sequence generation', link: '/sequence-generation' },
          { text: 'Parameter reference', link: '/parameter-reference' },
          { text: 'Portability boundary', link: '/platform-integration' },
          { text: 'Siemens 7 T LIN & ICE', link: '/phase-encoding-and-ice' },
        ],
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Reconstruction workflow', link: '/reconstruction' },
          { text: 'Echo phase & magnitude correction', link: '/guide/echo-corrections' },
          { text: 'Image-domain denoising', link: '/guide/denoising' },
          { text: 'Reconstruction protocol', link: '/validation/reconstruction-protocol' },
        ],
      },
      {
        text: 'Validation & Performance',
        items: [
          { text: 'Scientific validation strategy', link: '/validation/scientific-validation' },
          { text: 'Validation & safety', link: '/validation-and-safety' },
          { text: 'Siemens 7 T phantom SOP', link: '/staged-phantom-validation' },
          { text: 'Performance & benchmarking', link: '/validation/performance-benchmarking' },
        ],
      },
      {
        text: 'Reference',
        collapsed: false,
        items: [
          { text: 'API overview', link: '/reference/' },
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Reconstruction API', link: '/reference/reconstruction-api' },
          { text: 'Reproducibility & citation', link: '/reproducibility' },
          { text: 'Literature references', link: '/references' },
        ],
      },
      {
        text: 'Support',
        collapsed: true,
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Developer guide', link: '/developer-guide' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' },
    ],
    search: {
      provider: 'local',
    },
    outline: {
      level: [2, 3],
      label: 'On this page',
    },
    editLink: {
      pattern: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab/edit/vitepress-style/docs/:path',
      text: 'Edit this page on GitHub',
    },
    docFooter: {
      prev: 'Previous page',
      next: 'Next page',
    },
    footer: {
      message: 'Research software: portable Pulseq acquisition design, explicit platform integration, transparent reconstruction, and evidence-layered validation.',
      copyright: 'TSE Pulseq contributors',
    },
  },
})
