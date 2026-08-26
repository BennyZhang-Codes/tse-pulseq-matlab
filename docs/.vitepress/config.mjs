import { defineConfig } from 'vitepress'
import { mermaidPlugin } from './plugins/vitepress-mermaid/index.js'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  description: 'Documentation for an open-source Cartesian 2D TSE and gSlider-TSE Pulseq implementation with companion MATLAB reconstruction.',
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
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Installation', link: '/installation' },
        ],
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence Implementation', link: '/sequence-generation' },
          { text: 'Parameter Reference', link: '/parameter-reference' },
          { text: 'TSE Echo Train', link: '/theory/tse-echo-train' },
          { text: 'Phase Encoding & Acceleration', link: '/theory/phase-encoding' },
          { text: 'gSlider-TSE', link: '/guide/gslider-traps' },
        ],
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Reconstruction', link: '/reconstruction' },
          { text: 'Optional Echo Correction', link: '/guide/echo-corrections' },
          { text: 'Optional Denoising', link: '/guide/denoising' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Dependencies & Method Provenance', link: '/reference/provenance' },
          { text: 'Reproducibility & Citation', link: '/reproducibility' },
          { text: 'Literature References', link: '/references' },
          { text: 'TO DO', link: '/todo' },
        ],
      },
      {
        text: 'Support',
        items: [
          { text: 'Validation & Safety', link: '/validation-and-safety' },
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
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Installation', link: '/installation' },
        ],
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence Implementation', link: '/sequence-generation' },
          { text: 'Parameter Reference', link: '/parameter-reference' },
          { text: 'TSE Signal & Echo Train', link: '/theory/tse-echo-train' },
          { text: 'Phase Encoding & Acceleration', link: '/theory/phase-encoding' },
          { text: 'gSlider-TSE', link: '/guide/gslider-traps' },
        ],
      },
      {
        text: 'Reconstruction',
        collapsed: false,
        items: [
          { text: 'Reconstruction', link: '/reconstruction' },
          { text: 'Optional Echo Correction', link: '/guide/echo-corrections' },
          { text: 'Optional Denoising', link: '/guide/denoising' },
        ],
      },
      {
        text: 'Reference',
        collapsed: false,
        items: [
          { text: 'Sequence API', link: '/reference/sequence-api' },
          { text: 'Dependencies & Method Provenance', link: '/reference/provenance' },
          { text: 'Symbols & Notation', link: '/theory/symbols' },
          { text: 'Reproducibility & Citation', link: '/reproducibility' },
          { text: 'Literature References', link: '/references' },
          { text: 'TO DO', link: '/todo' },
        ],
      },
      {
        text: 'Support',
        collapsed: true,
        items: [
          { text: 'Validation & Safety', link: '/validation-and-safety' },
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'Developer Guide', link: '/developer-guide' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' },
    ],
    search: { provider: 'local' },
    outline: { level: [2, 3], label: 'On this page' },
    editLink: {
      pattern: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab/edit/vitepress-style/docs/:path',
      text: 'Edit this page on GitHub',
    },
    docFooter: { prev: 'Previous page', next: 'Next page' },
    footer: {
      message: 'Open-source Pulseq TSE sequence implementation with companion MATLAB reconstruction.',
      copyright: 'TSE Pulseq contributors',
    },
  },
})
