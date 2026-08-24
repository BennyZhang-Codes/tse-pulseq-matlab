import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'TSE Pulseq for MATLAB',
  titleTemplate: ':title · TSE Pulseq',
  description: 'Pulseq-based Cartesian 2D TSE sequence development toward vendor-neutral deployment, with current implementation and validation on Siemens 7 T.',
  base: '/tse-pulseq-matlab/',
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ['meta', { name: 'theme-color', content: '#a63b34' }]
  ],
  themeConfig: {
    siteTitle: 'TSE Pulseq',
    nav: [
      {
        text: 'Guide',
        link: '/quickstart',
        activeMatch: '^/(installation|quickstart)'
      },
      {
        text: 'Sequence',
        link: '/sequence-generation',
        activeMatch: '^/(sequence-generation|parameter-reference)'
      },
      {
        text: 'Platforms',
        link: '/platform-integration',
        activeMatch: '^/(platform-integration|phase-encoding-and-ice)'
      },
      { text: 'Reconstruction', link: '/reconstruction' },
      {
        text: 'Validation',
        link: '/validation-and-safety',
        activeMatch: '^/(validation-and-safety|staged-phantom-validation)'
      }
    ],
    sidebar: [
      {
        text: 'Start here',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Installation', link: '/installation' },
          { text: 'Quick Start', link: '/quickstart' }
        ]
      },
      {
        text: 'Sequence design',
        items: [
          { text: 'Sequence Workflow', link: '/sequence-generation' },
          { text: 'Parameter Reference', link: '/parameter-reference' }
        ]
      },
      {
        text: 'Platform integration',
        items: [
          { text: 'Platform Overview', link: '/platform-integration' },
          { text: 'Siemens 7 T Encoding & ICE', link: '/phase-encoding-and-ice' }
        ]
      },
      {
        text: 'Reconstruction',
        items: [
          { text: 'Siemens Twix Reconstruction', link: '/reconstruction' }
        ]
      },
      {
        text: 'Validation',
        items: [
          { text: 'Validation & Safety', link: '/validation-and-safety' },
          { text: 'Siemens 7 T Phantom SOP', link: '/staged-phantom-validation' }
        ]
      },
      {
        text: 'Project',
        collapsed: true,
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
    docFooter: {
      prev: 'Previous',
      next: 'Next'
    },
    lastUpdated: {
      text: 'Updated'
    },
    returnToTopLabel: 'Back to top',
    sidebarMenuLabel: 'Menu',
    darkModeSwitchLabel: 'Theme',
    lightModeSwitchTitle: 'Switch to light theme',
    darkModeSwitchTitle: 'Switch to dark theme',
    externalLinkIcon: true,
    footer: {
      message: 'Vendor-neutral design goal · Current implementation and scanner validation: Siemens 7 T.',
      copyright: 'MIT License'
    },
    editLink: {
      pattern: 'https://github.com/BennyZhang-Codes/tse-pulseq-matlab/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    }
  }
})
