import { DownloadIcon } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import { getBridge } from './bridge';
import { Button } from './ui/button';
import { saveExport } from '@/lib/export-history';

export function SaveAudioButton({
  url,
  suggestedName,
  disabled = false,
  iconOnly = false,
}: {
  url?: string;
  suggestedName: string;
  disabled?: boolean;
  /** A compact secondary action: the label becomes the tooltip. */
  iconOnly?: boolean;
}) {
  const { t } = useTranslation();
  const [saving, setSaving] = useState(false);
  const bridge = getBridge();

  const save = async () => {
    if (!url) return;
    setSaving(true);
    try {
      if (bridge && !url.startsWith('blob:')) {
        const saved = await saveExport(url, suggestedName);
        if (!saved) return;
        if (!saved.canceled && saved.path) {
          const path = saved.path;
          toast.success(t('clone.saved_to', { path }), {
            action: {
              label: t('clone.reveal'),
              onClick: () =>
                void bridge.files.revealPath(path).catch((error) => {
                  const message = error instanceof Error ? error.message : String(error);
                  toast.error(t('clone.download_failed', { message }));
                }),
            },
          });
        }
      } else {
        const filename = suggestedName.split(/[\\/]/).pop() || 'audio.wav';
        const browserWindow = window as Window & {
          showSaveFilePicker?: (options: { suggestedName: string }) => Promise<{
            createWritable: () => Promise<{
              write: (data: Blob) => Promise<void>;
              close: () => Promise<void>;
            }>;
          }>;
        };
        const fileHandle = browserWindow.showSaveFilePicker
          ? await browserWindow.showSaveFilePicker({ suggestedName: filename })
          : null;
        const response = await fetch(url, { credentials: 'include' });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const blob = await response.blob();
        if (!blob.size) throw new Error('The audio file is empty.');
        if (fileHandle) {
          const writable = await fileHandle.createWritable();
          await writable.write(blob);
          await writable.close();
          return;
        }
        const objectUrl = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = objectUrl;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        link.remove();
        setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
      }
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') return;
      const message = error instanceof Error ? error.message : String(error);
      toast.error(t('clone.download_failed', { message }));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Button
      variant="ghost"
      size={iconOnly ? 'icon-sm' : 'sm'}
      aria-label={iconOnly ? t('clone.download') : undefined}
      title={iconOnly ? t('clone.download') : undefined}
      onClick={() => void save()}
      disabled={disabled || saving || !url}
    >
      <DownloadIcon />
      {iconOnly ? null : t('clone.download')}
    </Button>
  );
}
