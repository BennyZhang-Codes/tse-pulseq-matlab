import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  description: 'Siemens-targeted Cartesian 2D TSE Pulseq sequence generation and offline MATLAB reconstruction.',
  base: '/tse-pulseq-matlab/',
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ['meta', { name: 'theme-color', content: '#3451b2' }]
  ],
  themeConfig: {
    siteTitle: 'TSE Pulseq for MATLAB',
    nav: [
      { text: 'Guide', link: '/quickstart' },
      { text: 'Reconstruction', link: '/reconstruction' },
      { text: 'Validation', link: '/validation-and-safety' },
      { text: 'GitHub', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' }
    ],
    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Introduction', link: '/' },
          { text: 'Installation', link: '/installation' },
          { text: 'Quick Start', link: '/quickstart' }
        ]
      },
      {
        text: 'Sequence',
        items: [
          { text: 'Sequence Generation', link: '/sequence-generation' },
          { text: 'Phase Encoding & Siemens ICE', link: '/phase-encoding-and-ice' },
          { text: 'Validation & Safety', link: '/validation-and-safety' }
        ]
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Offline Reconstruction', link: '/reconstruction' }
        ]
      },
      {
        text: 'Project',
        items: [
          { text: 'Reproducibility & Citation', link: '/reproducibility' },
          { text: 'Developer Guide', link: '/developer-guide' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab' }
    ],
    search: {
      provider: 'local'
    },
    outline: {
      level: [2, 3],
      label: 'On this page'
    },
    footer: {
      message: 'Research software for MRI sequence development. Scanner-side validation remains required.',
      copyright: 'Released under the MIT License.'
    },
    editLink: {
      pattern: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})
