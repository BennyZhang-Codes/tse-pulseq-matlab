import { defineConfig } from 'vitepress'
import { mermaidPlugin } from './plugins/vitepress-mermaid/index.js'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  description: 'Vendor-neutral Pulseq development of Cartesian 2D TSE and gSlider-TSE, with explicit platform integration and transparent MATLAB reconstruction.',
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
          { text: 'Getting started', link: '/quickstart' },
          { text: 'Installation', link: '/installation' },
          { text: 'Architecture', link: '/concepts-overview' },
        ],
      },
      {
        text: 'Theory',
        items: [
          { text: 'Symbols & notation', link: '/theory/symbols' },
          { text: 'TSE echo-train model', link: '/theory/tse-echo-train' },
          { text: 'Phase encoding & effective TE', link: '/theory/phase-encoding' },
        ],
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence generation', link: '/sequence-generation' },
          { text: 'gSlider & TRAPS', link: '/guide/gslider-traps' },
          { text: 'Parameter reference', link: '/parameter-reference' },
        ],
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Reconstruction workflow', link: '/reconstruction' },
          { text: 'Echo corrections', link: '/guide/echo-corrections' },
          { text: 'Image-domain denoising', link: '/guide/denoising' },
        ],
      },
      {
        text: 'Validation',
        items: [
          { text: 'Platform integration', link: '/platform-integration' },
          { text: 'Siemens 7 T LIN & ICE', link: '/phase-encoding-and-ice' },
          { text: 'Validation & safety', link: '/validation-and-safety' },
          { text: 'Siemens 7 T phantom SOP', link: '/staged-phantom-validation' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Reproducibility & citation', link: '/reproducibility' },
          { text: 'Developer guide', link: '/developer-guide' },
          { text: 'Literature references', link: '/references' },
        ],
      },
      {
        text: 'Support',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
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
          { text: 'TSE echo-train model', link: '/theory/tse-echo-train' },
          { text: 'Phase encoding & effective TE', link: '/theory/phase-encoding' },
        ],
      },
      {
        text: 'Sequence Design',
        items: [
          { text: 'Sequence generation', link: '/sequence-generation' },
          { text: 'gSlider & TRAPS', link: '/guide/gslider-traps' },
          { text: 'Parameter reference', link: '/parameter-reference' },
        ],
      },
      {
        text: 'Platform Integration',
        items: [
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
        ],
      },
      {
        text: 'Validation',
        items: [
          { text: 'Validation & safety', link: '/validation-and-safety' },
          { text: 'Siemens 7 T phantom SOP', link: '/staged-phantom-validation' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Reproducibility & citation', link: '/reproducibility' },
          { text: 'Developer guide', link: '/developer-guide' },
          { text: 'Literature references', link: '/references' },
        ],
      },
      {
        text: 'Support',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
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
    footer: {
      message: 'Vendor-neutral Pulseq TSE design with explicit platform integration and transparent offline reconstruction.',
      copyright: 'TSE Pulseq contributors',
    },
  },
})
