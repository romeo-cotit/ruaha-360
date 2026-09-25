import { defineConfig, mergeConfig } from 'vitest/config'
import viteConfig from './vite.config'

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: 'jsdom',
      globals: true,
      setupFiles: ['./src/test-setup.ts'],
      include: ['src/**/*.test.{ts,tsx}'],
      coverage: {
        provider: 'v8',
        reporter: ['text', 'html', 'json', 'json-summary'],
        include: [
          'src/components/ConfirmDialog.tsx',
          'src/features/officer/OfficerEditDialog.tsx',
          'src/features/officer/OfficerRecordScreens.tsx',
          'src/features/officer/PersonDetailScreen.tsx',
          'src/features/officer/RecordEditAction.tsx',
          'src/features/officer/VerifyButton.tsx',
          'src/features/officer/VerifyQueueScreen.tsx',
          'src/features/officer/officerEdit.ts',
          'src/features/officer/personDetail.ts',
          'src/features/officer/recordFocus.ts',
          'src/features/officer/useOfficerEdit.ts',
          'src/features/officer/useOfficerRecords.ts',
          'src/features/officer/usePersonDetail.ts',
          'src/features/officer/useVerifyQueue.ts',
          'src/features/officer/verifyNavigation.ts',
        ],
        thresholds: { lines: 100, functions: 100, branches: 100, statements: 100 },
      },
    },
  }),
)
