import { defineConfig } from 'vitepress'
import { mermaidPlugin } from './plugins/vitepress-mermaid/index.js'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  description: 'Engineering documentation for an open-source Cartesian 2D TSE and gSlider-TSE Pulseq implementation, including sequence construction, platform integration, MATLAB reconstruction, validation and method provenance.',
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
        text: 'Getting Started',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Installation', link: '/installation' },
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Repository Architecture', link: '/concepts-overview' },
        ],
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence Implementation', link: '/sequence-generation' },
          { text: 'TSE Echo Train', link: '/theory/tse-echo-train' },
          { text: 'Phase Encoding & Acceleration', link: '/theory/phase-encoding' },
          { text: 'gSlider-TSE & TRAPS', link: '/guide/gslider-traps' },
          { text: 'Parameter Reference', link: '/parameter-reference' },
          { text: 'Platform Integration', link: '/platform-integration' },
        ],
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Functions, Principles & Options', link: '/reconstruction' },
          { text: 'Optional Echo Correction', link: '/guide/echo-corrections' },
          { text: 'Optional Denoising', link: '/guide/denoising' },
          { text: 'Reconstruction Protocol', link: '/validation/reconstruction-protocol' },
        ],
      },
      {
        text: 'Validation & Safety',
        items: [
          { text: 'Validation Strategy', link: '/validation/scientific-validation' },
          { text: 'Validation & Safety', link: '/validation-and-safety' },
          { text: 'Performance & Benchmarking', link: '/validation/performance-benchmarking' },
        ],
      },
      { text: 'TO DO', link: '/todo' },
      {
        text: 'Reference',
        items: [
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Dependencies & Method Provenance', link: '/reference/provenance' },
          { text: 'Symbols & Notation', link: '/theory/symbols' },
          { text: 'Reproducibility & Citation', link: '/reproducibility' },
          { text: 'Literature References', link: '/references' },
        ],
      },
      {
        text: 'Support',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Developer Guide', link: '/developer-guide' },
          { text: 'GitHub Repository', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' },
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
          { text: 'Repository Architecture', link: '/concepts-overview' },
          { text: 'TO DO & Checklist', link: '/todo' },
        ],
      },
      {
        text: 'Sequence Implementation',
        items: [
          { text: 'Sequence Implementation', link: '/sequence-generation' },
          { text: 'TSE Signal & Echo Train', link: '/theory/tse-echo-train' },
          { text: 'Phase Encoding & Acceleration', link: '/theory/phase-encoding' },
          { text: 'gSlider-TSE & TRAPS', link: '/guide/gslider-traps' },
          { text: 'Parameter Reference', link: '/parameter-reference' },
          { text: 'Platform Integration', link: '/platform-integration' },
        ],
      },
      {
        text: 'Reconstruction',
        collapsed: false,
        items: [
          { text: 'Functions, Principles & Options', link: '/reconstruction' },
          { text: 'Optional Echo Correction', link: '/guide/echo-corrections' },
          { text: 'Optional Denoising', link: '/guide/denoising' },
          { text: 'Reconstruction Protocol', link: '/validation/reconstruction-protocol' },
        ],
      },
      {
        text: 'Validation & Safety',
        items: [
          { text: 'Validation Strategy', link: '/validation/scientific-validation' },
          { text: 'Validation & Safety', link: '/validation-and-safety' },
          { text: 'Performance & Benchmarking', link: '/validation/performance-benchmarking' },
        ],
      },
      {
        text: 'Reference & Provenance',
        collapsed: false,
        items: [
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Dependencies & Method Provenance', link: '/reference/provenance' },
          { text: 'Symbols & Notation', link: '/theory/symbols' },
          { text: 'Reproducibility & Citation', link: '/reproducibility' },
          { text: 'Literature References', link: '/references' },
        ],
      },
      {
        text: 'Support',
        collapsed: true,
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Developer Guide', link: '/developer-guide' },
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
      message: 'Open-source Pulseq sequence engineering: acquisition implementation, platform integration, reconstruction, validation, and traceable method provenance.',
      copyright: 'TSE Pulseq contributors',
    },
  },
})
